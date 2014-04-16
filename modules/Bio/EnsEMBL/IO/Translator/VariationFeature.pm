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

use base qw/Bio::EnsEMBL::IO::Translator::Feature/;


=head2 get_itemRgb

    Description:
    Returntype : String

=cut

sub get_itemRgb {
  my ($self, $vf) = @_;
  return '';
}

1;
