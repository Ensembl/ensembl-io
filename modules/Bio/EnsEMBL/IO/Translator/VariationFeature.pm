=pod

=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

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

Translator::VarationFeature - Translates accessor methods between variation feature objects and parsers

=cut

package Bio::EnsEMBL::IO::Translator::VariationFeature;

use strict;
use warnings;

use Carp;

use base qw/Bio::EnsEMBL::IO::Translator::Feature/;

sub seqname {
  my $self = shift;
  my $object = shift;
  
  return $object->seq_region_name;
}

sub start {
  my $self = shift;
  my $object = shift;

  #return ( $object->seq_region_start() > $object->seq_region_end() ) ? $object->seq_region_end() : $object->seq_region_start();
  return ( $object->start() > $object->end() ) ? $object->end() : $object->start();
}

sub end {
  my $self = shift;
  my $object = shift;

  return ( $object->start() > $object->end() ) ? $object->start() : $object->end();
  #return ( $object->seq_region_start() > $object->seq_region_end() ) ? $object->seq_region_start() : $object->seq_region_end();
}

sub name {
  my $self = shift;
  my $object = shift;

  return $object->variation_name();
}

sub alleles {
  my $self = shift;
  my $object = shift;
  
  return $object->allele_string();
}

1;
