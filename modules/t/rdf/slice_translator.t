# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
# Copyright [2016-2024] EMBL-European Bioinformatics Institute
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
use Test::Deep;
use Test::Differences;
use Test::Exception;
use JSON;

use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::CoordSystem;
use Bio::EnsEMBL::Slice;

use_ok 'Bio::EnsEMBL::IO::Translator::Slice';

my $multi = Bio::EnsEMBL::Test::MultiTestDB->new(undef, "$Bin/..");
my $meta_adaptor = $multi->get_DBAdaptor('core')->get_MetaContainer();
my ($version, $production_name) =
  (
   $meta_adaptor->list_value_by_key('schema_version')->[0],
   $meta_adaptor->list_value_by_key('species.production_name')->[0]
  );

my $translator =
  Bio::EnsEMBL::IO::Translator::Slice->new(version => $version, meta_adaptor => $meta_adaptor);

ok($translator->version == $version, 'version');
ok($translator->production_name eq $production_name, 'production name');
ok($translator->taxon_id == 9606, 'taxon id');
ok($translator->scientific_name eq 'Homo sapiens', 'scientific name');

my $cs = Bio::EnsEMBL::CoordSystem->new(-NAME    => 'chromosome',
                                        -VERSION => 'GRCh38',
                                        -RANK    => 1,
                                        ); 
my $slice = Bio::EnsEMBL::Slice->new( -coord_system     => $cs,
                                      -seq_region_name  => 1,
                                      -start            => 1,
                                      -end              => 248956422,
                                      -strand           => 1,
				    );

# test some accessors
is($translator->name($slice), "chromosome:GRCh38:1:1:248956422:1", 'slice name');
is($translator->coord_system_name($slice), "chromosome", 'coord system name');
is($translator->coord_system_version($slice), 'GRCh38', 'coord system version');
my ($version_uri, $unversioned_uri) = $translator->uri($slice);
is($version_uri, "<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/chromosome:GRCh38:1:1:248956422:1>", "slice versioned URI");
is($unversioned_uri, "<http://rdf.ebi.ac.uk/resource/ensembl/homo_sapiens/GRCh38/chromosome:GRCh38:1:1:248956422:1>", "slice unversioned URI");

done_testing();
