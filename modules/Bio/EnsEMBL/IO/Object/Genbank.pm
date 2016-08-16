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

package Bio::EnsEMBL::IO::Object::Genbank;

use strict;
use warnings;
use Carp;

=head2 fields

    Description: Access the fields for a Genbank type record
    Returntype : Array of fields

=cut

sub fields
{
    my $self = shift;

    return [qw(LOCUS DEFINITION ACCESSION VERSION KEYWORDS SOURCE COMMENT REFERENCE FEATURES ORIGIN)];
}
