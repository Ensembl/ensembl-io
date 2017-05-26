# Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use strict;
use warnings;

use FindBin qw/$Bin/;
use Test::More;
use Test::Differences;
use Test::Exception;

use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::IO::Translator::BulkFetcherFeature;

use_ok 'Bio::EnsEMBL::IO::Translator::BulkFetcherFeature';

my $omulti = Bio::EnsEMBL::Test::MultiTestDB->new('ontology', "$Bin/..");
my $ontology_adaptor =
  $omulti->get_DBAdaptor('ontology')->get_OntologyTermAdaptor();

my $multi = Bio::EnsEMBL::Test::MultiTestDB->new(undef, "$Bin/..");
my $meta_adaptor = $multi->get_DBAdaptor('core')->get_MetaContainer();

my $translator =
  Bio::EnsEMBL::IO::Translator::BulkFetcherFeature->new(version           => 89,
							production_name   => 'homo_sapiens',
							xref_mapping_file => "$Bin/xref_LOD_mapping.json",
							ontology_adaptor  => $ontology_adaptor,
							meta_adaptor      => $meta_adaptor);

done_testing();
