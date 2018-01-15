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

use Bio::EnsEMBL::IO::Parser::Psl;

my $test_file = "modules/t/input/data.psl";

my $parser = Bio::EnsEMBL::IO::Parser::Psl->open($test_file);
ok ($parser->next(), "Loading first record");
my $test_desc = 'Fish BLAT';
is_deeply($parser->get_metadata_value('description'), $test_desc, "Test track description");
ok ($parser->get_matches() eq 59, "Matches");
ok ($parser->get_misMatches() eq 9, 'MisMatches');
ok ($parser->get_repMatches() eq 0, 'RepMatches');
ok ($parser->get_nCount() eq 0, 'NCount');
ok ($parser->get_qNumInsert() eq 1, 'QNumInsert');
ok ($parser->get_qBaseInsert() eq 823, 'QBaseInsert');
ok ($parser->get_tNumInsert() eq 1, 'TNumInsert');
ok ($parser->get_tBaseInsert() eq 96, 'TBaseInsert');
ok ($parser->get_strand() eq '-1', 'Strand');
ok ($parser->get_qName() eq 'FS_CONTIG_48080_1', 'QName');
ok ($parser->get_qSize() eq 1955, 'QSize');
ok ($parser->get_qStart() eq 171, 'QStart');
ok ($parser->get_qEnd() eq 1062, 'QEnd');
ok ($parser->get_tName() eq 22, 'TName');
ok ($parser->get_tSize() eq 47748585, 'TSize');
ok ($parser->get_tStart() eq 13073590, 'TStart');
ok ($parser->get_tEnd() eq 13073753, 'TEnd');
ok ($parser->get_blockCount() eq 2, 'BlockCount');
my $A = $parser->get_blockSizes();
ok ($A->[0] eq 48, 'BlockSizes');
my $B = $parser->get_qStarts();
ok ($B->[0] eq 171, 'QStarts');
my $C = $parser->get_tStarts();
ok ($C->[0] eq 34674832, 'TStarts');
ok ($parser->next(), "Loading second record");
ok ($parser->next(), "Loading third record");
ok (!$parser->next(), "Reaching end of file");
ok ($parser->close(), "Closing file");

done_testing();
