=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

Bio::EnsEMBL::IO::Object::Metadata - Abstract base class to represent metadata

=head1 SYNOPSIS

  use Bio::EnsEMBL::IO::Object::Metadata;

=head1 Description

This is an abstract base class to represent metadata, mainly so object reference
testing in serializers and parsers can test for a single object type. This class
should never be instantiated directly, nor should sub-classes call SUPER on this
base class.

=cut

package Bio::EnsEMBL::IO::Object::Metadata;

use strict;
use warnings;

sub new {

    die "Bio::EnsEMBL::IO::Object::Metadata should not be directly instantiated!";

}

sub create_record {

    die "Bio::EnsEMBL::IO::Object::Metadata can not create records, this must be implemented in your derived class.";

}

1;
