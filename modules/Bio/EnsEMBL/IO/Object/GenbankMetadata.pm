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

Bio::EnsEMBL::IO::Object::Genbank - Generic object for holding Genbank based records

=head1 SYNOPSIS




=head1 Description


=cut

package Bio::EnsEMBL::IO::Object::GenbankMetadata;

use strict;
use warnings;
use Carp;




=head2 section_header_fields

    Description: Access the fields for a Genbank type record
    Returntype : Array of header fields. Currently the last of the these is the header for the body section.

=cut

sub section_header_fields
{
    my $self = shift;
    return [qw(LOCUS DEFINITION ACCESSION VERSION KEYWORDS SOURCE COMMENT REFERENCE FEATURES)];
}




=head2 section_footer_fields

    Description: Access the fields for a Genbank type record
    Returntype : Array of footer fields

=cut

sub section_footer_fields
{
    my $self = shift;
    return ["BASE COUNT","ORIGIN"];
}




