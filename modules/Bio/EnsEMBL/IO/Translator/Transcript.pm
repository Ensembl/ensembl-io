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
  my $colours = $self->species_defs->colour('transcript');
  my $colour = $colours->{$transcript->biotype}{'default'};
  return $colour ? '('.join(',',$self->rgb_by_name($colour)).')' : undef;
}

1;
