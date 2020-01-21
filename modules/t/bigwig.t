# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
# Copyright [2016-2020] EMBL-European Bioinformatics Institute
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
use Bio::EnsEMBL::IO::Parser::BigWig;
use FindBin;

######################################################
## Test 1
######################################################
my $test_file = $FindBin::Bin . '/input/data-variableStep.bw';
my $parser = Bio::EnsEMBL::IO::Parser::BigWig->open($test_file);
ok($parser->seek(1, 1, 100));

ok($parser->next);
ok($parser->get_seqname eq '1');
ok($parser->get_start == 1);
ok($parser->get_end == 2);
ok($parser->get_score == 2);

for (my $i = 1; $i < 4; $i++) {
  ok($parser->next);
  ok($parser->get_seqname eq '1');
  my $start = $i * 2 + 1;
  ok($parser->get_start == $start);
  ok($parser->get_end == $start + 1);
  ok($parser->get_score == $i + 2);
}

ok(!$parser->next);

$parser->close();

######################################################
## Test 2
######################################################
$test_file = $FindBin::Bin . '/input/data-fixedStep.bw';
$parser = Bio::EnsEMBL::IO::Parser::BigWig->open($test_file);
ok($parser->seek(1, 1, 100));

for (my $i = 1; $i < 10; $i ++) {
  ok($parser->next);
  ok($parser->get_seqname eq '1');
  ok($parser->get_start == $i);
  ok($parser->get_end == $i + 1);
  ok($parser->get_score == $i);
}

ok(!$parser->next);
$parser->close();

done_testing;
