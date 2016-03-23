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

eval "require Bio::DB::BigFile";
my $big_file_unavailable = $@;

SKIP: {
  skip 'Bio::DB::BigFile is not installed. Cannot run tests', 1 if $big_file_unavailable;
  require Bio::EnsEMBL::IO::Parser::BigWig;

  ######################################################
  ## Test 1
  ######################################################
  my $parser = Bio::EnsEMBL::IO::Parser::BigWig->open("modules/t/data-variableStep.bw");

  note 'Querying for chr1:1-10. Expecting 5 data points';
  $parser->seek('chr1', 1, 10);
  ok($parser->next, 'Got next data value');
  is($parser->get_chrom, 'chr1', 'chromosome');
  is($parser->get_start, 1, 'start');
  is($parser->get_end, 1, 'end');
  is($parser->get_score, 1, 'score');

  for (my $i = 0; $i < 4; $i++) {
    ok($parser->next, 'Got next data value');
    is($parser->get_chrom, 'chr1', 'chromosome');
    is($parser->get_start, (2 + 2 * $i), 'start');
    is($parser->get_end, (2 + 2 * $i), 'end');
    is($parser->get_score, (2+$i), 'score');
  }

  ok(!$parser->next, 'Exhausted elements');

  $parser->close();

  ######################################################
  ## Test 2
  ######################################################
  $parser = Bio::EnsEMBL::IO::Parser::BigWig->open('modules/t/data-fixedStep.bw');

  note 'Querying for chr1:1-10. Expecting 10 fixed step data points';
  $parser->seek('chr1', 1, 10);
  for (my $i = 0; $i < 10; $i ++) {
    ok($parser->next, 'Got next data value');
    is($parser->get_chrom, 'chr1', 'chromosome');
    is($parser->get_start, (1 + $i), 'start');
    is($parser->get_end, (1 + $i), 'end');
    is($parser->get_score, $i, 'score');
  }

  ok(!$parser->next, "Exhausted elements");

  $parser->close();
}

done_testing();
