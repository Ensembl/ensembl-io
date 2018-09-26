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
use FindBin;

use Bio::EnsEMBL::IO::Parser::VEP_input;

my $test_file = $FindBin::Bin . '/input/data.vepi';

my $parser = Bio::EnsEMBL::IO::Parser::VEP_input->open($test_file);
ok ($parser->next(), "Loading first record");
ok ($parser->get_seqname() eq 19);
ok ($parser->get_start() == 66520);
ok ($parser->get_end() == 66520);
ok ($parser->get_allele() eq 'G/A');
ok ($parser->get_strand() == 1);
ok ($parser->get_id() eq 'var1');
ok ($parser->next(), "Loading second record");
ok ($parser->close(), "Closing file");

done_testing();
