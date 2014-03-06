=pod

=head1 LICENSE

  Copyright (c) 1999-2013 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

  http://www.ensembl.org/info/about/code_licence.html

=head1 NAME

Bio::EnsEMBL::IO::Parser::WigParser - A line-based parser devoted to WIG

=cut

package Bio::EnsEMBL::IO::Parser::WigParser;

use strict;
use warnings;

use base qw/Bio::EnsEMBL::IO::TrackBasedParser/;

=head2 read_record

    Description: Extends parent method, by keeping a count of records read 
    Returntype : Void 

=cut


sub read_record {
  my $self = shift;
  chomp $self->{'current_block'};
  $self->{'record'} = [ split($self->{'delimiter'},$self->{'current_block'}) ] ;
  $self->{'metadata'}{'feature_count'}++;
}


## --------- FORMAT-SPECIFIC METADATA -----------

sub is_metadata {
  my $self = shift;
  if ($self->{'current_block'} =~ /^track/ 
      || $self->{'current_block'} =~ /^browser/
      || $self->{'current_block'} =~ /^#/ 
      || $self->{'current_block'} =~ /^(fixed|variable)Step/) {
    $self->{'metadata'}{'feature_count'} = 0;
    return $self->{'current_block'};
  }
}

sub get_feature_count {
  ## Not strictly part of metadata, but we need to keep track of this
  ## in fixed-step tracks to get the start coordinates right
  my $self = shift;
  return $self->{'metadata'}{'feature_count'} || 0;
}

sub get_wiggle_type {
  my $self = shift;
  return $self->{'metadata'}{'step_type'} || $self->get_track_type;
}

sub get_graphType {
  my $self = shift;
  return $self->{'metadata'}{'graphType'};
}

sub get_autoScale {
  my $self = shift;
  return $self->{'metadata'}{'autoScale'};
}

sub get_viewLimits {
  my $self = shift;
  return $self->{'metadata'}{'viewLimits'};
}

sub get_step {
  my $self = shift;
  return $self->{'metadata'}{'step'};
}

sub get_span {
  my $self = shift;
  return $self->{'metadata'}{'span'};
}

sub get_color {
  my $self = shift;
  return $self->{'metadata'}{'color'};
}

sub get_maxHeightPixels {
  my $self = shift;
  return $self->{'metadata'}{'maxHeightPixels'};
}

## -------------- RECORDS -------------------

## ----------- Mandatory fields -------------

sub get_raw_chrom {
  my $self = shift;
  if ($self->get_wiggle_type =~ /Step/) {
    return $self->{'metadata'}{'chrom'};
  }
  else {
    return $self->{'record'}[0];
  }
}

sub get_seqname {
  my $self = shift;
  (my $chr = $self->get_raw_chrom()) =~ s/^chr//;
  return $chr;
}

sub get_raw_start {
  my $self = shift;
  if ($self->get_wiggle_type eq 'fixedStep') {
    return $self->{'metadata'}{'start'};
  }
  elsif ($self->get_wiggle_type eq 'variableStep') {
    return $self->{'record'}[0];
  }
  else {
    return $self->{'record'}[1];
  }
}

sub get_start {
  my $self = shift;
  if ($self->get_wiggle_type eq 'variableStep') {
    return $self->get_raw_start();
  }
  elsif ($self->get_wiggle_type eq 'fixedStep') {
    return $self->get_raw_start() + $self->get_step() * ($self->get_feature_count() - 1);
  }
  else {
  ## BED-type format with half-open coordinates
    return $self->get_raw_start() + 1;
  }
}

sub get_raw_end {
  my $self = shift;
  return $self->{'record'}[2];
}

sub get_end {
  my $self = shift;
  if ($self->get_wiggle_type =~ /Step/) {
    my $end = $self->get_start + $self->get_span - 1;
    return $end;
  }
  else {
    return $self->get_raw_end();
  }
}

sub get_raw_score {
  my $self = shift;
  if ($self->get_wiggle_type eq 'fixedStep') {
    return $self->{'record'}[0];
  }
  elsif ($self->get_wiggle_type eq 'variableStep') {
    return $self->{'record'}[1];
  } 
  else {
    return $self->{'record'}[3];
  } 
}

sub get_score {
  my $self = shift;
  my $val = $self->get_raw_score();
  if ($val =~ /^\.$/) {
    return undef;
  } else {
    return $val;
  }
}

1;
