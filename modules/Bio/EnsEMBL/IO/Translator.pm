=pod

=head1 LICENSE

  Copyright (c) 1999-2013 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

  http://www.ensembl.org/info/about/code_licence.html

=head1 NAME

Translator - An abstract class to translate accessor methods between API objects and parsers

=cut

package Bio::EnsEMBL::IO::Translator;

use strict;
use warnings;

use Bio::EnsEMBL::Utils::Exception qw/throw/;

=head2 new

    Constructor
    Returntype   : Bio::EnsEMBL::IO::Translator

=cut

sub new {
  my ($class, $sd) = @_;

  ## Optional track colour configuration (requires ensembl-webcode)
  my $colourmap;
  if ($sd) {
    eval "require EnsEMBL::Draw::ColourMap";
    if (!$@) {
      $colourmap = EnsEMBL::Draw::ColourMap->new($sd);
    }
  }
  my $self = {
              'species_defs' => $sd,
              'colourmap' => $colourmap
             };
  bless $self, $class;
  return $self;
}


sub species_defs {
  my $self = shift;
  return $self->{'species_defs'};
}

sub colourmap {
  my $self = shift;
  return $self->{'colourmap'};
}

sub rgb_by_name {
  my ($self, $name) = @_;
  return $self->colourmap ? $self->colourmap->rgb_by_name($name) : undef;
}

1;
