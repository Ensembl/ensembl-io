=pod

=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 NAME

BigFileParser - a parser for indexed files such as BigBed and BigWig 

=cut

package Bio::EnsEMBL::IO::BigFileParser;

use strict;
use warnings;

use List::Util qw(max);
use POSIX qw(floor ceil);

use Bio::DB::BigFile;
use Bio::DB::BigFile::Constants;
use Bio::EnsEMBL::IO::Utils;

use parent qw(Bio::EnsEMBL::IO::Parser);

=head2 new

    Constructor
    Argument [1+]: Hash of parameters for configuration, e.g. buffer sizes or 
                   specific functions for handling headers or data
    Returntype   : Bio::EnsEMBL::IO::BigFileParser

=cut

sub new {
    my ($class, $url) = @_;
    
    my $self = {
      url               => $url,
      cache             => {
                            'file_handle' => undef,
                            'features'    => [],
                            },
      current_block     => undef,
      waiting_block     => undef,
      record            => undef,
      strand_conversion => {'+' => '1', '.' => '0', '-' => '-1'},
    };

    bless $self, $class;
  
    return $self;
}

=head2 open

    Constructor
    Argument [1] : Filepath or GLOB or open filehandle
    Argument [2+]: Hash of parameters for configuration, e.g. buffer sizes or 
                   specific functions for handling headers or data
    Returntype   : Bio::EnsEMBL::IO::BigFileParser

=cut

sub open {
    my ($caller, $url, @other_args) = @_;
    my $class = ref($caller) || $caller;
    my $self = $class->new($url, @other_args);
    my $fh = $self->open_file;

    ## Do any additional pre-processing
    $self->init($fh); 

    return $self;
}

=head _chr_mapping

  Description: Build the chromosome name mapping scheme for lookup

=cut

sub _chr_mapping {
  my ($self, $bbi) = @_;
  if(! exists $self->{cache}{chromosomes}) {
    $bbi = $self->open_file() if ! defined $bbi;
    my $list = $bbi->chromList;
    my $head = $list->head;
    my $chromosomes = {};
    do {
      if ($head->name && $head->size) {
        my $chr = $head->name;
        $chr =~ s/^chr//;
        $chromosomes->{$chr} = $head->name;
        $chromosomes->{$head->name} = $head->name;
      }
    } while ($head && ($head = $head->next));
    $self->{cache}{chromosomes} = $chromosomes;
  }
  return $self->{cache}{chromosomes};
}

=head _map_chr_to_internal_name

  Description: Map a name into the internal representation

=cut

sub _map_chr_to_internal_name {
  my ($self, $chr_id) = @_;
  return if ! defined $chr_id;
  my $chr_mapping = $self->_chr_mapping();
  my $seq_id = $chr_mapping->{$chr_id};
  return if ! $seq_id;
  return $seq_id;
}

=head2 init 

    Description: placeholder - may need implementing in child

=cut 

sub init {}


=head2 type

    Description : Placeholder for accessor 
    Returntype  : String

=cut

sub type {
      confess("Method not implemented. This is really important");
}

=head2 url

    Description : Accessor for file url
    Returntype  : String

=cut

sub url {
  my $self = shift;
  return $self->{'url'};
}

=head2 cache

    Description : Accessor for cache
    Returntype  : Hashref

=cut

sub cache {
  my $self = shift;
  return $self->{'cache'};
}


=head2 open

    Description: Opens a remote file from URL
    Returntype : Filehandle 

=cut

sub open_file {
  my ($self) = @_;
  if(defined $self->{cache}->{file_handle}) {
    return $self->{cache}->{file_handle};
  }
  Bio::DB::BigFile->set_udc_defaults;
  my $method = $self->type.'FileOpen';
  $self->{cache}->{file_handle} = Bio::DB::BigFile->$method($self->url);
  return $self->{cache}->{file_handle};
}

=head2 fetch_summary_data 

    Description: fetches data from the requested region, grouped into 
                  a set number of bins, and caches it
    Returntype : Void

=cut

sub fetch_summary_data {
    my ($self, $chr_id, $start, $end, $bins) = @_;
    
    my $fh = $self->open_file;
    warn "Failed to open file ".$self->url unless $fh;
    return unless $fh;

    my $seq_id = $self->_map_chr_to_internal_name($chr_id);
    return unless $seq_id;

    my $method = $self->type.'SummaryArray';
    my $list = $fh->$method("$seq_id", $start-1, $end, bbiSumMean, $bins);
    my $bin_size = floor(($end - $start)/$bins);

    my $feature_cache = []; 

    foreach (@$list) {
      next unless defined($_);
      my @line = ($chr_id, $start, $start + $bin_size, $_);
      $start += $bin_size;
      push @$feature_cache, \@line;
    }

    $self->cache->{'summary'} = $feature_cache;
}

=head2 fetch_summary_array

    Description: fetches values only from the requested region 
    Returntype : ArrayRef

=cut

sub fetch_summary_array {
    my ($self, $chr_id, $start, $end, $bins) = @_;

    my $fh = $self->open_file;
    warn "Failed to open file ".$self->url unless $fh;
    return unless $fh;

    my $seq_id = $self->_map_chr_to_internal_name($chr_id);
    return unless $seq_id;

    my $method = $self->type.'SummaryArray';
    return $fh->$method("$seq_id", $start-1, $end, bbiSumMean, $bins);
}



=head2 next_block

    Description: Shifts to next block. Note that Big files don't have metadata 
    Returntype : Void

=cut

sub next_block {
    my $self = shift;
    $self->shift_block();
}

=head2 read_block

    Description : Reads a line of text, stores it into next_block, 
                  moving next_block to current_block.
    Returntype   : True/False on existence of a defined current_block after running.

=cut

sub read_block {
    my $self = shift;
    my $features = $self->{'cache'}{'features'};

    if (scalar @$features) {
        $self->{'waiting_block'} = shift @$features || confess ("Error reading cached features: $!");
    } else {
        $self->{'waiting_block'} = undef;
    }
}

=head2 read_record

    Description: Features are cached as an array, so no processing needed 
    Returntype : Void 

=cut


sub read_record {
    my $self = shift;
    $self->{'record'} = $self->{'current_block'};
}

sub close {
  my ($self) = @_;
  delete $self->{cache}->{file_handle};
}


1;
