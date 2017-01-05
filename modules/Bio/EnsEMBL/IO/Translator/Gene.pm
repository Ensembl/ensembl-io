=pod

=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

Translator::Gene - Translates accessor methods between gene objects and parsers

=cut

package Bio::EnsEMBL::IO::Translator::Gene;

use strict;
use warnings;

use Carp;

use Bio::EnsEMBL::IO::Utils::ColourMap;

use base qw/Bio::EnsEMBL::IO::Translator::Feature/;

my %gene_field_callbacks = (itemRgb => 'itemRgb');

=head2 new

    Returntype   : Bio::EnsEMBL::IO::Translator::Gene

=cut

sub new {
    my ($class, $args) = @_;

    ## Might we want to output web colours?
    if ($args->{'species_defs'}) {
      $args->{'colourmap'} = Bio::EnsEMBL::IO::Utils::ColourMap->new($args->{'species_defs'});
    }

    my $self = $class->SUPER::new($args);

    # Once we have the instance, add our customized callbacks
    # to the translator
    $self->add_callbacks(\%gene_field_callbacks);

    return $self;

}


=head2 colourmap

    Description : Accessor for optional colour-mapping object
    Returntype  : Bio::EnsEMBL::IO::Utils::ColourMap;

=cut

sub colourmap {
  my $self = shift;
  return $self->{'colourmap'};
}


=head2 name
    Description: Wrapper around API call to feature name
    Returntype : String
=cut

sub name {
  my ($self, $feature) = @_;

  my $dxr   = $feature->can('display_xref') ? $feature->display_xref : undef;
  my $label = $dxr ? $dxr->display_id : $feature->stable_id;
}


=head2 source
    Description: Get the source of gene track
    Returntype : Integer
=cut

sub source {
    my $self = shift;
    my $object = shift;

    return $object->source();
}

=head2 itemRgb

    Description:
    Returntype : String

=cut

sub itemRgb {
  my ($self, $gene) = @_;
  return '.' unless $self->colourmap;
  my $colours = $self->species_defs->colour('gene');
  my $colour = $colours->{$gene->biotype}{'default'};
  return $colour ? join(',',$self->colourmap->rgb_by_name($colour)) : undef;
}

1;
