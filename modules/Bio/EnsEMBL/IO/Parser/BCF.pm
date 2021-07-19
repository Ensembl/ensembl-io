=pod

=head1 LICENSE

Copyright [2020-2021] EMBL-European Bioinformatics Institute

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

Bio::EnsEMBL::IO::Parser::BCF - A line-based parser devoted to BCF

=head1 DESCRIPTION

BCF is a binary format of VCF

=cut

package Bio::EnsEMBL::IO::Parser::BCF;

use strict;
use warnings;

use Carp;
use Bio::DB::HTS::VCF;
use Bio::DB::HTS::VCF::Iterator;
use Cwd qw(getcwd);
use parent qw/Bio::EnsEMBL::IO::Parser::BaseVCF4/;

sub open {
  my ($caller, $filename, @other_args) = @_;
  my $class = ref($caller) || $caller;

  # initialize generic parser
  my $self = $class->SUPER::new(@other_args);

  $self->{record} = undef;
  $self->{bcf_file} = Bio::DB::HTS::VCF->new( filename => $filename );
  $self->{iterator} = undef;

  return $self;
}

sub open_with_location {
  my ($caller, $filename, $location, @other_args) = @_;
  my $class = ref($caller) || $caller;

  # initialize generic parser
  my $self = $class->SUPER::new(@other_args);
  my $currentDir = getcwd();
  chdir($location);
  $self->{record} = undef;
  $self->{bcf_file} = Bio::DB::HTS::VCF->new( filename => $filename );
  $self->{iterator} = undef;
  $self->read_metadata;
  chdir($currentDir);
  return $self;
}

sub read_metadata {
# Put the entire header into an easily readable hash
  my $self = shift;

  foreach my $line (split /\n/, $self->header->fmt_text) {
    if ($line =~ /^##\s*(\w+)=(.+)$/) {
      $self->_parse_metadata_line($line, $1, $2);
    }
    elsif ($line =~ /^#\s*(.+)$/) {
      $self->{'metadata'}->{'header'} = [split("\t",$1)];
      $self->{'sample_begin'} = (scalar @{$self->{'metadata'}->{'header'}} >= 9 && $self->{'metadata'}->{'header'}->[8] eq 'FORMAT') ? 9 : 8;
    }
  }
}

sub seek {
  my ($self, $chrom, $start, $end) = @_;

  $self->{iterator}->close()
    if UNIVERSAL::isa($self->{iterator}, 'Bio::DB::HTS::VCF::Iterator');

  ## Check for both possible versions of chromosome name
  foreach ($chrom, "chr$chrom") {
    my $region = "$_:$start-$end";
    $self->{iterator} = $self->{bcf_file}->query($region) ;
    last if $self->{iterator};
  }

  # pre-load peek buffer
  if ($self->{iterator}) {
    $self->next_block();
    $self->{record} = $self->{waiting_block};
    return 1;
  } else {
    return 0;
  }
}

sub next_block {
  my $self = shift;

  if (!defined $self->{iterator}) {
    exit 1;
  }

  $self->shift_block();
}

sub read_block {
  my $self = shift;

  $self->{waiting_block} = $self->{iterator}->next;
}

sub close {
  my $self = shift;

  $self->{iterator}->close if $self->{iterator};
  my $report = $self->{bcf_file}->DESTROY;

  return (defined $report) ? 0 : 1;
}

sub num_variants {
  my $self = shift;

  return $self->{bcf_file}->num_variants();
}

sub header {
  my $self = shift;

  return $self->{bcf_file}->header();
}

sub next {
  my $self = shift;

  $self->{record} = $self->{bcf_file}->next();

  if (defined $self->{record}) {
    return 1;
  } else {
    return 0;
  }
}

sub query {
  my ($self, $region) = @_;

  return $self->{bcf_file}->query($region);
}

sub read_record {
  my $self = shift;

  return $self->{record};
}

## Override 'raw' VCF accessors because we're dealing with an object, not an arrayref

sub get_raw_seqname {
    my $self = shift;
    return $self->{'record'}->chromosome($self->header);
}

sub get_raw_start {
    my $self = shift;
    return $self->{'record'}->position;
}

sub get_raw_end {
    my $self = shift;
    my $info = $self->get_info($self->header);
    my $end;
    if (defined($info->{END})) {
      $end = $info->{END};
    }
    elsif(defined($info->{SVLEN})) {
      my $svlen = (split(',',$info->{SVLEN}))[0];
      $end = $self->get_raw_start + abs($svlen);
    }
    else {
      $end = $self->get_raw_start + length($self->get_raw_reference) - 1;
    }
    return $end;
}

sub get_raw_IDs {
    my $self = shift;
    return $self->{'record'}->id;
}

sub get_raw_score {
    my $self = shift;
    return $self->{'record'}->quality;
}

sub get_score {
    my $self = shift;
    my $score = $self->get_raw_score;
    $score = undef if $score eq 'NaN';
    return $score;
}

sub get_raw_reference {
    my $self = shift;
    return $self->{'record'}->reference;
}

sub get_raw_alternatives {
    my $self = shift;
    return $self->{'record'}->get_alleles;
}

sub get_alternatives {
  my $self = shift;
  return $self->get_raw_alternatives;
}


sub get_alternative_description {
  my $self = shift;
  my $alt = shift;
  return $self->get_metadata_description('ALT', $alt);
}

sub get_raw_info {
  my $self = shift;
  return $self->{'record'}->get_info($self->header);
}

sub get_info {
  my $self = shift;

  if(!exists($self->{_cache}->{info})) {
    my %info_data;
    for (my ($key,$value) = each (%{$self->get_raw_info})) {
      if (ref($value) eq 'ARRAY') {
        $value = join(',', @$value);
      }
      $info_data{$key} = $value;
    }
    $self->{_cache}->{info} = \%info_data;
  }

  return $self->{_cache}->{info};
}

sub get_raw_filter_results {
  my $self = shift;
  my @filters = @{$self->{metadata}{FILTER}||[]};
  my $filter_results = [];

  foreach my $filter (@filters) {
    my $has_filter = $self->{record}->has_filter($self->header, $filter->{ID});
    if ($has_filter) {
      push @$filter_results, $filter->{ID};
    }
  }  
  return $filter_results;
}

sub get_filter_results {
  my $self = shift;
  return $self->get_raw_filter_results;
}

sub get_raw_formats {
  my $self = shift;
  return {} unless $self->{metadata}{FORMAT}; 
  return $self->{record}->get_format($self->header);
}

sub get_formats {
  my $self = shift;
  return keys %{$self->get_raw_formats||{}};
}

sub get_individuals {
  my $self = shift;

  return $self->header->get_samples;
}

## These methods are only needed by non-binary VCF formats,
## so prevent them from returning nonsense

sub add_format {}
sub is_metadata {}


1;
