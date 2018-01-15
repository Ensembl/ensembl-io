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

Translator::Transcript - Translates accessor methods between transcript objects and parsers

=cut

package Bio::EnsEMBL::IO::Translator::Transcript;

use strict;
use warnings;

use Carp;

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
