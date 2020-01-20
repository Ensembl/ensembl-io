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

Bio::EnsEMBL::IO::Object::GFF3 - Generic object for holding GFF3 based records

=head1 SYNOPSIS

  use Bio::EnsEMBL::IO::Object::GFF3;
  use Bio::EnsEMBL::IO::Parser::GFF3;

  my $parser = Bio::EnsEMBL::IO::Parser::GFF3->open('myfile.gff3');
  my $obj = Bio::EnsEMBL::IO::Object::GFF3->new($parser->get_fields);

  $obj->munrge_seqname('my_seq');

=head1 Description

An object derived from ColumnBasedGeneric with a specialized create_record to properly
format the record as GFF3 and map the strand to the correct values type (+/-)
rather than GFF3 as the generic object does.

=cut

package Bio::EnsEMBL::IO::Object::GFF3;

use parent qw/Bio::EnsEMBL::IO::Object::ColumnBasedGeneric/;

use strict;
use warnings;
use Carp;

my %strand_mapping = (1 => '+', -1 => '-');

=head2 fields

    Description: Access the fields for a GFF3 type record
    Returntype : Array of fields

=cut

sub fields {
    my $self = shift;

    return [qw(seqname source type start end score strand phase attributes)];
}

=head2 strand_conversion

    Description: Access the strand conversion mappings

=cut

sub strand_conversion {
    my $self = shift;

    return \%strand_mapping;
}
