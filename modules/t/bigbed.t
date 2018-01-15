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
use Bio::EnsEMBL::IO::Parser::BigBed;

######################################################
## Test 1
######################################################
my $parser = Bio::EnsEMBL::IO::Parser::BigBed->open('modules/t/input/data.bb');
ok($parser->seek(1, 1, 10));

ok($parser->next());
ok($parser->get_chrom eq '1');
ok($parser->get_start == 3);
ok($parser->get_end == 6);
ok($parser->get_strand == 0);
ok($parser->get_name eq 'Mo');
ok($parser->get_score == 1000);

ok($parser->next);
ok($parser->get_chrom eq '1');
ok($parser->get_start == 4);
ok($parser->get_end == 8);
ok($parser->get_strand);
ok($parser->get_name eq 'Larry');
ok($parser->get_score == 1000);

ok($parser->seek(2, 1, 10));
ok($parser->next);
ok($parser->get_chrom eq '2');
ok($parser->get_start == 2);
ok($parser->get_end == 7);
ok($parser->get_strand == -1);
ok($parser->get_name eq 'Curly');
ok($parser->get_score == 1000);

ok(!$parser->next);

$parser->close();

done_testing;
