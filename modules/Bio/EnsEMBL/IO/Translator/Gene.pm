=pod

=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2020] EMBL-European Bioinformatics Institute

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

use parent qw/Bio::EnsEMBL::IO::Translator::Feature/;

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

1;
