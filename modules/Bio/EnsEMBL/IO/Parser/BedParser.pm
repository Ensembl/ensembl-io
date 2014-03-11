=pod

=head1 LICENSE

  Copyright (c) 1999-2013 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

  http://www.ensembl.org/info/about/code_licence.html

=head1 NAME

Bio::EnsEMBL::IO::Parser::BedParser - A line-based parser devoted to BED

=cut

package Bio::EnsEMBL::IO::Parser::BedParser;

use strict;
use warnings;

use base qw/Bio::EnsEMBL::IO::TrackBasedParser/;

## ----------- Mandatory fields -------------

sub get_raw_chrom {
  my $self = shift;
  return $self->{'record'}[0];
}

sub get_seqname {
  my $self = shift;
  (my $chr = $self->get_raw_chrom()) =~ s/^chr//;
  return $chr;
}

sub get_raw_chromStart {
  my $self = shift;
  return $self->{'record'}[1];
}

sub get_start {
  my $self = shift;
  ## BED uses semi-open coordinates
  return $self->get_raw_chromStart()+1;
}

sub get_raw_chromEnd {
  my $self = shift;
  return $self->{'record'}[2];
}

sub get_end {
  my $self = shift;
  return $self->get_raw_chromEnd();
}

## ----------- Optional fields -------------

sub get_raw_name {
  my $self = shift;
  my $column = $self->get_metadata_value('type') eq 'bedGraph' ? undef : $self->{'record'}[3];
  return $column;
}

sub get_name {
  my $self = shift;
  return $self->get_raw_name();
}

sub get_raw_score {
  my $self = shift;
  my $column = $self->get_metadata_value('type') eq 'bedGraph' ? 3 : 4;
  return $self->{'record'}[$column];
}

sub get_score {
  my $self = shift;
  my $val = $self->get_raw_score();
  if ($val =~ /\./) {
    return undef;
  } else {
    return $val;
  }
}

sub get_raw_strand {
  my $self = shift;
  return $self->{'record'}[5];
}

my %strand_conversion = ( '+' => '1', '.' => '0', '-' => '-1');

sub get_strand {
  my $self = shift;
  my $val = $self->get_raw_strand();
  if ($val =~ /\./) {
    return undef;
  } else {
    return $strand_conversion{$val};
  }
}

sub get_raw_thickStart {
  my $self = shift;
  return $self->{'record'}[6];
}

sub get_thickStart {
  my $self = shift;
  return $self->get_raw_thickStart();
}

sub get_raw_thickEnd {
  my $self = shift;
  return $self->{'record'}[7];
}

sub get_thickEnd {
  my $self = shift;
  return $self->get_raw_thickEnd();
}

sub get_raw_itemRgb {
  my $self = shift;
  return $self->{'record'}[8];
}

sub get_itemRgb {
  my $self = shift;
  return $self->get_raw_itemRgb();
}

sub get_raw_blockCount {
  my $self = shift;
  return $self->{'record'}[9];
}

sub get_blockCount {
  my $self = shift;
  return $self->get_raw_blockCount();
}

sub get_raw_blockSizes {
  my $self = shift;
  return $self->{'record'}[10];
}

sub get_blockSizes {
  my $self = shift;
  my @res = split ",", $self->get_raw_blockSizes();
  return \@res;
}

sub get_raw_blockStarts {
  my $self = shift;
  return $self->{'record'}[11];
}

sub get_blockStarts {
  my $self = shift;
  my @res = split ",", $self->get_raw_blockStarts();
  return \@res;
}

1;
