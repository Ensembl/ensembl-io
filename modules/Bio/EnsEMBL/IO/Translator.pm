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

=cut

package Bio::EnsEMBL::IO::Translator;

use strict;
use warnings;

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
