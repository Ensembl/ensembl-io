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

use Bio::EnsEMBL::IO::Parser::Bed;

my $test_file = "modules/t/input/data.bed";

my $parser = Bio::EnsEMBL::IO::Parser::Bed->open($test_file);
ok ($parser->next(), "Loading first record");
is ($parser->get_seqname(), 19, 'seq name');
is ($parser->get_start(), 6603910, 'start');
is ($parser->get_end(), 6764455, 'end');
is ($parser->get_name(), 'RP11-635J19', 'name');
is ($parser->get_score(), 1000, 'score');
is ($parser->get_strand(), -1, 'strand');
is ($parser->get_thickStart(), 6603910, 'thickEnd in 1 based coordinates');
is ($parser->get_thickEnd(), 6764455, 'thinEnd');
is ($parser->get_itemRgb(), 0, 'rgb');
is ($parser->get_blockCount(), 2, 'blocks');
my @test_starts = (407, 441);
is_deeply($parser->get_blockSizes(), \@test_starts, "Testing block sizes");
my @test_lengths = (0, 160105);
is_deeply($parser->get_blockStarts(), \@test_lengths, "Testing block starts");
ok ($parser->next(), "Loading second record");
ok ($parser->close(), "Closing file");

done_testing();
