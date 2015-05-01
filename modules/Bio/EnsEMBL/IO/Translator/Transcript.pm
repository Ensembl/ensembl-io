=pod

=head1 LICENSE

  Copyright (c) 1999-2013 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

  http://www.ensembl.org/info/about/code_licence.html

=head1 NAME

Translator::Transcript - Translates accessor methods between transcript objects and parsers

=cut

package Bio::EnsEMBL::IO::Translator::Transcript;

use strict;
use warnings;

use Bio::EnsEMBL::Utils::Exception qw/throw/;

use base qw/Bio::EnsEMBL::IO::Translator::Feature/;

=head2 get_itemRgb

    Description:
    Returntype : String

=cut

sub get_itemRgb {
  my ($self, $transcript) = @_;
  return '0,0,0' unless $self->species_defs;
  my $colours = $self->species_defs->colour('transcript');
  my $colour = $colours->{$transcript->biotype}{'default'};
  return $colour ? '('.join(',',$self->rgb_by_name($colour)).')' : undef;
}

=head2 get_thickStart

    Description: Placeholder - needed so that column counts are correct
    Returntype : Zero

=cut

sub get_thickStart {
  my ($self, $transcript) = @_;
  return $transcript->coding_region_start;
}

=head2 get_thickEnd

    Description: Placeholder - needed so that column counts are correct
    Returntype : Zero

=cut

sub get_thickEnd {
  my ($self, $transcript) = @_;
  return $transcript->coding_region_end;
}

=head2 get_blockCount

    Description: Placeholder - needed so that column counts are correct
    Returntype : Zero

=cut

sub get_blockCount {
  my ($self, $transcript) = @_;
  return scalar(@{$transcript->get_all_Exons});
}

=head2 get_blockSizes

    Description: Placeholder - needed so that column counts are correct
    Returntype : Zero

=cut

sub get_blockSizes {
  my ($self, $transcript) = @_;
  my @sizes;
  foreach my $exon (@{$transcript->get_all_Exons}) {
      push(@sizes, $exon->length);
  }
  @sizes = reverse(@sizes) if ($transcript->strand == -1);
  return join(',', @sizes);
}

=head2 get_blockStart

    Description: Placeholder - needed so that column counts are correct
    Returntype : Zero

=cut

sub get_blockStarts {
  my ($self, $transcript) = @_;
  my @starts;
  foreach my $exon (@{$transcript->get_all_Exons}) {
      push(@starts, $exon->start);
  }
  @starts = reverse(@starts) if ($transcript->strand == -1);
  return join(',', @starts);
}

1;
