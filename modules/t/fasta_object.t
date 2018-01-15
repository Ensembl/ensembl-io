# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
# Copyright [2016-2018] EMBL-European Bioinformatics Institute
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

use Test::More;

use Bio::EnsEMBL::IO::Object::Fasta;

my $obj = Bio::EnsEMBL::IO::Object::Fasta->new();

ok($obj, "Object created");

ok($obj->sequence('NNNNN'), 'Set sequence');
ok($obj->header('ENSG00001701.1 hypothetical protein'), 'Set header');


is($obj->sequence, 'NNNNN', 'Test getter');
is($obj->sequence, 'NNNNN', 'Test generic getter');

is($obj->header, 'ENSG00001701.1 hypothetical protein', 'Fetch header');

is($obj->description(), 'hypothetical protein', 'Get description');
is($obj->id, 'ENSG00001701.1', 'Fetch sequence id');

ok($obj->sequence('ACTG'), 'Update sequence');
is($obj->sequence(), 'ACTG', 'Get updated sequence');

done_testing();
