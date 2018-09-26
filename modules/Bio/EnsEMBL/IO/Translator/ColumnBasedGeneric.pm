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

Bio::EnsEMBL::IO::Translator::ColumnBasedGeneric - Generic translator for column based parser results

=cut

package Bio::EnsEMBL::IO::Translator::ColumnBasedGeneric;

use strict;
use warnings;

use Carp;

use base qw/Bio::EnsEMBL::IO::Translator/;

# We don't need any functionality in this translator, we just need the
# module to exist so get_translator_by_type() can instanciate an instance
# of this translator type for a data object of type ::ColumnBasedGeneric

# Dirty, but that's how ::Write is written.

1;
