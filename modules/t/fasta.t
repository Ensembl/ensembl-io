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

use Bio::EnsEMBL::IO::Parser::Fasta;

my $test_file = "modules/t/input/data.fasta";

######################################################
## Test 1
######################################################
my $parser = Bio::EnsEMBL::IO::Parser::Fasta->open($test_file);
ok($parser->next());
ok(length($parser->getHeader()) == 44, "Check length of header");
ok(scalar(@{$parser->getRawSequence()}) == 17,"Check size of first FASTA block");
ok($parser->next_sequence());
ok(scalar(@{$parser->getRawSequence()}) == 14,"Check size of second FASTA block");
ok(!$parser->next(), "Final attempt to read returns nothing.");
ok($parser->close());

######################################################
## Test 2
##
## Don't read the sequence, ensure the pointer moves
## forward correctly between records
##
######################################################
$parser = Bio::EnsEMBL::IO::Parser::Fasta->open($test_file);
ok($parser->next(), 'Read the first record');
ok($parser->next(), 'Second record, don\'t touch the sequence');
ok(!$parser->next(), "Final attempt to read returns nothing.");
ok($parser->close());

done_testing;
