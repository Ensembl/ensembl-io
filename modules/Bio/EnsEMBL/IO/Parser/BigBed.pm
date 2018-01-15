=pod

=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2018] EMBL-European Bioinformatics Institute

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

Bio::EnsEMBL::IO::Parser::BigBed - A line-based parser devoted to BigBed

=cut

package Bio::EnsEMBL::IO::Parser::BigBed;

use strict;
use warnings;
no warnings 'uninitialized';

use parent qw/Bio::EnsEMBL::IO::BigFileParser Bio::EnsEMBL::IO::Parser::Bed/;

=head2 init

    Definition: When we open the file, we want to check for AutoSQL 
                and assign column positions
    Return: Void

=cut

sub init {
  my ($self, $fh) = @_;

  ## Define default column positions, because AutoSQL
  $self->{'default_names'} = [qw(chrom chromStart chromEnd name score strand thickStart thickEnd itemRgb blockCount blockSizes chromStarts)];
  $self->{'alt_names'} = {
                          'item_colour' => 'itemRgb',
                          'colour'      => 'itemRgb',
                          'reserved'    => 'itemRgb',
                          'age'         => 'score',
                          };

  my $autoSQL = $fh->bigBedAs;
  my $column_map = {};
  my $i = 0;
  while ($autoSQL) {
    next unless $autoSQL->isTable; 
    my @table;
    my $cols = $autoSQL->columnList;
    while ($cols) {
      my $real_name;
      ## Check for incomplete AutoSQL
      if (($cols->name =~ /^field\d+$/ || $cols->comment eq 'Undocumented field') && $i < scalar @{$self->{'default_names'}}) { 
        $real_name = $self->{'default_names'}[$i];
      }
      else {
        $real_name = $self->{'alt_names'}{$cols->name} || $cols->name;
      }
      $column_map->{$real_name} = $i;
      $i++;
      $cols = $cols->next;
    }
    $autoSQL = $autoSQL->next;
  }
  if (keys %$column_map) {
    $self->{'column_map'} = $column_map;
  }
  else {
    $self->{'column_map'} = {
                            'chrom'         => 0,
                            'chromStart'    => 1,
                            'chromEnd'      => 2,
                            'name'          => 3,
                            'score'         => 4,
                            'strand'        => 5,
                            'thickStart'    => 6,
                            'thickEnd'      => 7,
                            'itemRgb'       => 8,
                            'blockCount'    => 9,
                            'blockSizes'    => 10,
                            'blockStarts'   => 11,
                            'chromStarts'   => 11,
                          };
  }
}
 
=head2 type

    Description : Return case-correct version of format name, for use in method names 
    Returntype  : String

=cut

sub type {
    return 'bigBed'; 
}

=head2 seek

    Description: Fetches the raw data from the requested region and caches it 
    Returntype : Void

=cut

sub seek {
    my ($self, $chr_id, $start, $end) = @_;

    my $fh = $self->open_file;
    warn "Failed to open file ".$self->url unless $fh;
    return unless $fh;

    ## Get the internal chromosome name
    my $seq_id = $self->cache->{'chromosomes'}{$chr_id};
    return unless $seq_id;

    ## Remember this method takes half-open coords (subtract 1 from start)
    my $list_head = $fh->bigBedIntervalQuery("$seq_id", $start-1, $end);

    my $feature_cache = $self->cache->{'features'};

    for (my $i=$list_head->head; $i; $i=$i->next) {
      my @line = ($chr_id, $i->start, $i->end, split(/\t/,$i->rest));
      push @$feature_cache, \@line;
    }
    return unless scalar @$feature_cache;

    ## pre-load peek buffer
    $self->next_block();
}

=head2 fetch_summary_data 

    Description: fetches data from the requested region, grouped into 
                  a set number of bins, and caches it
    Returntype : Void

=cut

sub fetch_summary_data {
    my ($self, @args) = @_;
    
    ## In effect we're creating a bedGraph, so tell the Bed parser this
    $self->{'metadata'}{'type'} = 'bedGraph';
    $self->SUPER::fetch_summary_data(@args);
}


#### Override the BED raw accessors, because AutoSQL

=head2 get_raw_chrom

    Description: Getter for chrom field
    Returntype : String 

=cut

sub get_raw_chrom {
  my $self = shift;
  my $index = $self->{'column_map'}{'chrom'};
  return $self->{'record'}[$index] if defined($index);
}


=head2 get_raw_chromStart

    Description: Getter for chromStart field
    Returntype : Integer 

=cut

sub get_raw_chromStart {
  my $self = shift;
  my $index = $self->{'column_map'}{'chromStart'};
  return $self->{'record'}[$index] if defined($index);
}

=head2 get_raw_chromEnd

    Description: Getter for chromEnd field
    Returntype : Integer 

=cut

sub get_raw_chromEnd {
  my $self = shift;
  my $index = $self->{'column_map'}{'chromEnd'};
  return $self->{'record'}[$index] if defined($index);
}

=head2 get_raw_name

    Description: Getter for name field
    Returntype : String 

=cut

sub get_raw_name {
  my $self = shift;
  my $index = $self->{'column_map'}{'name'};
  return $self->{'record'}[$index] if defined($index);
}

=head2 get_raw_score

    Description: Getter for score field
    Returntype : Number (usually floating point) or String (period = no data) 

=cut

sub get_raw_score {
  my $self = shift;
  my $index = $self->{'column_map'}{'score'};
  return $self->{'record'}[$index] if defined($index);
}

=head2 get_raw_strand

    Description: Getter for strand field
    Returntype : String 

=cut

sub get_raw_strand {
  my $self = shift;
  my $index = $self->{'column_map'}{'strand'};
  return $self->{'record'}[$index] if defined($index);
}

=head2 get_raw_thickStart

    Description: Getter for thickStart field
    Returntype : Integer

=cut

sub get_raw_thickStart {
  my $self = shift;
  my $index = $self->{'column_map'}{'thickStart'};
  return $self->{'record'}[$index] if defined($index);
}

=head2 get_raw_thickEnd

    Description: Getter for thickEnd field
    Returntype : Integer 

=cut

sub get_raw_thickEnd {
  my $self = shift;
  my $index = $self->{'column_map'}{'thickEnd'};
  return $self->{'record'}[$index] if defined($index);
}

=head2 get_raw_itemRgb

    Description: Getter for itemRgb field
    Returntype : String  (3 comma-separated values)

=cut

sub get_raw_itemRgb {
  my $self = shift;
  my $index = $self->{'column_map'}{'itemRgb'};
  return $self->{'record'}[$index] if defined($index);
}

=head2 get_raw_blockCount

    Description: Getter for blockCount field
    Returntype : Integer 

=cut

sub get_raw_blockCount {
  my $self = shift;
  my $index = $self->{'column_map'}{'blockCount'};
  return $self->{'record'}[$index] if defined($index);
}

=head2 get_raw_blockSizes

    Description: Getter for blockSizes field
    Returntype : String (comma-separated values)

=cut

sub get_raw_blockSizes {
  my $self = shift;
  my $index = $self->{'column_map'}{'blockSizes'};
  return $self->{'record'}[$index] if defined($index);
}

=head2 get_raw_blockStarts

    Description: Getter for blockStarts field
    Returntype : String (comma-separated values)

=cut

sub get_raw_blockStarts {
  my $self = shift;
  ## This field, annoyingly, has two synonyms
  my $index = $self->{'column_map'}{'blockStarts'} || $self->{'column_map'}{'chromStarts'};
  return $self->{'record'}[$index] if defined($index);
}

### AUTOLOAD ANY AUTOSQL ACCESSORS

our $AUTOLOAD;

sub AUTOLOAD {
  my $self = shift;
  my $method = our $AUTOLOAD;
  $method =~ s/.*:://;
  my $value;

  if ($method =~ /^get_(\w+)/) {
    my $key = $1;
    $value = $self->{'record'}[$self->{'column_map'}{$key}];
  } 
  return $value;
}



1;
