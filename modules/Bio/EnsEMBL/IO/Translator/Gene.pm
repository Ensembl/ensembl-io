=pod

=head1 LICENSE

  Copyright (c) 1999-2013 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

  http://www.ensembl.org/info/about/code_licence.html

=head1 NAME

Translator::Gene - Translates accessor methods between gene objects and parsers

=cut

package Bio::EnsEMBL::IO::Translator::Gene;

use strict;
use warnings;

use Bio::EnsEMBL::Utils::Exception qw/throw/;

use base qw/Bio::EnsEMBL::IO::Translator/;

=head2 get_seqname

    Description: Wrapper around API call to seq region name
    Returntype : String

=cut

sub get_seqname {
  my ($self, $gene) = @_;
  return $gene->slice->seq_region_name;
}

=head2 get_start

    Description: Wrapper around API call to feature start
    Returntype : Integer

=cut

sub get_start {
  my ($self, $gene) = @_;
  return $gene->start;
}

=head2 get_end

    Description: Wrapper around API call to feature end
    Returntype : Integer

=cut

sub get_end {
  my ($self, $gene) = @_;
  return $gene->end;
}

1;
