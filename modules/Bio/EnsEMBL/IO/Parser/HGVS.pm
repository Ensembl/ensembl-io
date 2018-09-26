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

Bio::EnsEMBL::IO::Parser::HGVS - a list-based parser for HGVS identifiers

=cut

### IMPORTANT - this is a work-in-progress and needs extending to fully parse
### the content (possibly using VEP code)

package Bio::EnsEMBL::IO::ListBasedParser::HGVS;

use strict;
use warnings;

use base qw/Bio::EnsEMBL::IO::ListBasedParser/;

=head2 get_raw_feature_id

    Description: Getter for first element of HGVS - seqname or stable id
    Returntype : String

=cut

sub get_raw_feature_id {
  my $self = shift;
  my ($id) = split(':', $self->{'record'});
  return $id;
}

=head2 get_feature_id

    Description: Getter - wrapper around get_raw_feature_id
    Returntype : String

=cut

sub get_feature_id {
  my $self = shift;
  return $self->get_raw_feature_id; 
}

=head2 get_raw_ref_seq_type

    Description: Getter for second element of HGVS - type of reference sequence
    Returntype : String (single lower-case character)

=cut

sub get_raw_ref_seq_type {
  my $self = shift;
  my ($id, $remainder) = split(':', $self->{'record'});
  my ($type) = split('\.', $remainder);
  return $type;
}

=head2 get_ref_seq_type

    Description: Getter - wrapper around get_raw_feature_id
    Returntype : String

=cut

sub get_ref_seq_type {
  my $self = shift;
  return $self->get_raw_ref_seq_type; 
}

=head2 get_raw_variant

    Description: Getter for third element of HGVS - variant notation
    Returntype : String

=cut

sub get_raw_variant {
  my $self = shift;
  my ($id, $remainder) = split(':', $self->{'record'});
  my ($type, $var) = split('\.', $remainder);
  return $var;
}

=head2 get_variant

    Description: Getter - wrapper around get_raw_variant
    Returntype : String

=cut

sub get_variant {
  my $self = shift;
  return $self->get_raw_variant; 
}

1;
