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
use FindBin;
use Bio::EnsEMBL::IO::Parser::BigBed;

## TEST FOR UCSC bigInteract FORMAT
## which is a custom bigBed format with specific AutoSQL fields

######################################################
## Test 1
######################################################
my $test_file = $FindBin::Bin . '/input/data_interact.bb';
my $parser = Bio::EnsEMBL::IO::Parser::BigBed->open($test_file);
ok($parser->seek(3, 63820967, 63880091));

ok($parser->next());
ok($parser->get_chrom eq '3');
ok($parser->get_start == 63741419);
ok($parser->get_end == 63978511);
ok($parser->get_score == 350);

## Test customisable source and target columns
ok($parser->get_chrom(8) eq '3');
ok($parser->get_start(9) == 63741419);
ok($parser->get_end(10) == 63743120);
ok($parser->get_chrom(13) eq '3');
ok($parser->get_start(14) == 63976339);
ok($parser->get_end(15) == 63978511);

$parser->close();

done_testing;
