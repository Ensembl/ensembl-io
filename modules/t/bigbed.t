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

use Test::More;
use Bio::EnsEMBL::IO::Parser::BigBed;

######################################################
## Test 1
######################################################
my $parser = Bio::EnsEMBL::IO::Parser::BigBed->open('modules/t/data.bb');

$parser->seek('chr1', 1, 2000);
ok($parser->next(), 'Can read BED rows after seek');
is($parser->get_chrom, 'chr1', 'chromosome');
is($parser->get_start, 3, 'start');
is($parser->get_end, 6, 'end');
is($parser->get_strand, 0, 'strand');
is($parser->get_name, 'Mo', 'name');
is($parser->get_score, 1000, 'score');

ok($parser->next(), 'Can read BED rows without another seek');
is($parser->get_chrom, 'chr1', 'chromosome');
is($parser->get_start, 4, 'start');
is($parser->get_end, 8, 'end');
is($parser->get_strand, 1, 'strand');
is($parser->get_name, 'Larry', 'name');
is($parser->get_score, 1000, 'score');
ok(!$parser->next, 'No more features left');

$parser->seek('chr2', 1, 2000);
ok($parser->next(), 'Can read BED rows after seek');
is($parser->get_chrom, 'chr2', 'chromosome');
is($parser->get_start, 2, 'start');
is($parser->get_end, 7, 'end');
is($parser->get_strand, -1, 'strand');
is($parser->get_name, 'Curly', 'name');
is($parser->get_score, 1000, 'score');

$parser->close();

done_testing;
