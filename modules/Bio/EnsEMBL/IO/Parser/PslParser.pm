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

package Bio::EnsEMBL::IO::Parser::PslParser;

use strict;
use warnings;

use base qw/Bio::EnsEMBL::IO::TrackBasedParser/;

## ----------- Mandatory fields (21) -------------

sub get_raw_matches {
  my $self = shift;
  return $self->{'record'}[0];
}

sub get_matches {
  my $self = shift;
  return $self->get_raw_matches; 
}

sub get_raw_misMatches {
  my $self = shift;
  return $self->{'record'}[1];
}

sub get_misMatches {
  my $self = shift;
  return $self->get_raw_misMatches; 
}

sub get_raw_repMatches {
  my $self = shift;
  return $self->{'record'}[2];
}

sub get_repMatches {
  my $self = shift;
  return $self->get_raw_repMatches; 
}

sub get_raw_nCount {
  my $self = shift;
  return $self->{'record'}[3];
}

sub get_nCount {
  my $self = shift;
  return $self->get_raw_nCount; 
}

sub get_raw_qNumInsert {
  my $self = shift;
  return $self->{'record'}[4];
}

sub get_qNumInsert {
  my $self = shift;
  return $self->get_raw_qNumInsert; 
}

sub get_raw_qBaseInsert {
  my $self = shift;
  return $self->{'record'}[5];
}

sub get_qBaseInsert {
  my $self = shift;
  return $self->get_raw_qBaseInsert; 
}

sub get_raw_tNumInsert {
  my $self = shift;
  return $self->{'record'}[6];
}

sub get_tNumInsert {
  my $self = shift;
  return $self->get_raw_tNumInsert; 
}

sub get_raw_tBaseInsert {
  my $self = shift;
  return $self->{'record'}[7];
}

sub get_tBaseInsert {
  my $self = shift;
  return $self->get_raw_tBaseInsert; 
}

sub get_raw_strand {
  my $self = shift;
  return $self->{'record'}[8];
}

sub get_strand {
  my $self = shift;
  ## Translated alignments list both query strand and genomic strand - we want the latter
  return substr($self->get_raw_strand, -1);
}

sub get_raw_qName {
  my $self = shift;
  return $self->{'record'}[9];
}

sub get_qName {
  my $self = shift;
  return $self->get_raw_qName; 
}

sub get_raw_qSize {
  my $self = shift;
  return $self->{'record'}[10];
}

sub get_qSize {
  my $self = shift;
  return $self->get_raw_qSize; 
}

sub get_raw_qStart {
  my $self = shift;
  return $self->{'record'}[11];
}

sub get_qStart {
  my $self = shift;
  return $self->get_raw_qStart; 
}

sub get_raw_qEnd {
  my $self = shift;
  return $self->{'record'}[12];
}

sub get_qEnd {
  my $self = shift;
  return $self->get_raw_qEnd; 
}

sub get_raw_tName {
  my $self = shift;
  return $self->{'record'}[13];
}

sub get_tName {
  my $self = shift;
  (my $chr = $self->get_raw_tName()) =~ s/^chr//;
  return $chr;
}

sub get_raw_tSize {
  my $self = shift;
  return $self->{'record'}[14];
}

sub get_tSize {
  my $self = shift;
  return $self->get_raw_tSize; 
}

sub get_raw_tStart {
  my $self = shift;
  return $self->{'record'}[15];
}

sub get_tStart {
  my $self = shift;
  return $self->get_raw_tStart+1; 
}

sub get_raw_tEnd {
  my $self = shift;
  return $self->{'record'}[16];
}

sub get_tEnd {
  my $self = shift;
  return $self->get_raw_tEnd; 
}

sub get_raw_blockCount {
  my $self = shift;
  return $self->{'record'}[17];
}

sub get_blockCount {
  my $self = shift;
  return $self->get_raw_blockCount; 
}

sub get_raw_blockSizes {
  my $self = shift;
  return $self->{'record'}[18];
}

sub get_blockSizes {
  my $self = shift;
  return split(',', $self->get_raw_blockSizes); 
}

sub get_raw_qStarts {
  my $self = shift;
  return $self->{'record'}[19];
}

sub get_qStarts {
  my $self = shift;
  return split(',', $self->get_raw_qStarts); 
}

sub get_raw_tStarts {
  my $self = shift;
  return $self->{'record'}[20];
}

sub get_tStarts {
  my $self = shift;
  return split(',', $self->get_raw_tStarts); 
}


1;
