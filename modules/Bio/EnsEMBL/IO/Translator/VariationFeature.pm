=pod

=head1 LICENSE

  Copyright (c) 1999-2013 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

  http://www.ensembl.org/info/about/code_licence.html

=head1 NAME

Translator::VarationFeature - Translates accessor methods between variation feature objects and parsers

=cut

package Bio::EnsEMBL::IO::Translator::VariationFeature;

use strict;
use warnings;

use Bio::EnsEMBL::Utils::Exception qw/throw/;

use base qw/Bio::EnsEMBL::IO::Translator/;

=head2 get_seqname

    Description: Wrapper around API call to seq region name
    Returntype : String

=cut

sub get_seqname {
  my ($self, $vf) = @_;
  return $vf->slice->seq_region_name;
}

=head2 get_start

    Description: Wrapper around API call to feature start
    Returntype : Integer

=cut

sub get_start {
  my ($self, $vf) = @_;
  return $vf->start;
}

=head2 get_end

    Description: Wrapper around API call to feature end
    Returntype : Integer

=cut

sub get_end {
  my ($self, $vf) = @_;
  return $vf->end;
}

=head2 get_name

    Description: Wrapper around API call to feature name
    Returntype : String

=cut

sub get_name {
  my ($self, $vf) = @_;
  return $vf->display_id;
}

=head2 get_score

    Description: Wrapper around API call to feature name
    Returntype : String

=cut

sub get_score {
  my ($self, $vf) = @_;
  return '.';
}

=head2 get_strand

    Description: Wrapper around API call to feature strand
    Returntype : String

=cut

sub get_strand {
  my ($self, $vf) = @_;
  return $vf->strand;
}

=head2 get_thickStart

    Description: Placeholder - needed so that column counts are correct 
    Returntype : Zero

=cut

sub get_thickStart {
  my ($self, $vf) = @_;
  return '0'
}

=head2 get_thickEnd

    Description: Placeholder - needed so that column counts are correct 
    Returntype : Zero

=cut

sub get_thickEnd {
  my ($self, $vf) = @_;
  return '0'
}

=head2 get_itemRgb

    Description:
    Returntype : String

=cut

sub get_itemRgb {
  my ($self, $vf) = @_;
  return '';
}

1;
