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

use Bio::EnsEMBL::IO::Parser::Wig;

my $test_file = "modules/t/input/data.wig";

my $parser = Bio::EnsEMBL::IO::Parser::Wig->open($test_file);
ok ($parser->next(), "Loading first record");

## NB: WIG files can contain BED format rows - that's what we're testing here!
my $test_desc = 'BED format';
is_deeply($parser->get_metadata_value('description'), $test_desc, "Testing track description");
ok ($parser->get_wiggle_type() eq 'bedGraph', 'bedGraph');
ok ($parser->get_seqname() eq 19, 'SeqName');
ok ($parser->get_start() eq 58302001, 'Start');
ok ($parser->get_end() eq 58302300, 'End');
ok ($parser->get_score() eq '-1.0', 'Score');
## Load rest of track
for (my $i = 2; $i < 10; $i++) {
	ok ($parser->next(), "Loading record " . $i);
}

## Checking WIG format variableStep
ok ($parser->next(), "Loading first record of second track");
$test_desc = 'variableStep format';
is_deeply($parser->get_metadata_value('description'), $test_desc, "Testing track description");
ok ($parser->get_wiggle_type() eq 'variableStep', 'Variable Step format');
ok ($parser->get_seqname() eq 19, 'SeqName');
ok ($parser->get_start() eq 58304701, 'Start');
ok ($parser->get_end() eq 58304850, 'End');
ok ($parser->get_score() eq '10.0', 'Score');
## Load rest of track
for (my $i = 11; $i < 19; $i++) {
	ok ($parser->next(), "Loading record " . $i);
}

## Checking WIG format fixedStep
ok ($parser->next(), "Loading first record of third track");
$test_desc = 'fixed step';
is_deeply($parser->get_metadata_value('description'), $test_desc, "Testing track description");
ok ($parser->get_wiggle_type() eq 'fixedStep', 'Fixed Step format');
ok ($parser->next(), "Loading second record of third track");
ok ($parser->get_seqname() eq 19, 'SeqName');
ok ($parser->get_start() eq 58307701, 'Start');
ok ($parser->get_end() eq 58307900, 'End');
ok ($parser->get_score() eq '900', 'Score');
## Load rest of track
for (my $i = 21; $i < 29; $i++) {
	ok ($parser->next(), "Loading record " . $i);
}

ok (!$parser->next(), "Reaching end of file");
ok ($parser->close(), "Closing file");

done_testing();
