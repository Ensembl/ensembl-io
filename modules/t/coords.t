# See the NOTICE file distributed with this work for additional information
# regarding copyright ownership.
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

use Bio::EnsEMBL::IO::Parser::Coords;
use FindBin;

my $test_file = $FindBin::Bin . '/input/coords.txt';

my $parser = Bio::EnsEMBL::IO::Parser::Coords->open($test_file);
ok ($parser->next(), "Loading first record");
is ($parser->get_seqname(), 1, 'seq name');
is ($parser->get_start(), 123456, 'start');
is ($parser->get_end(), 123789, 'end');
ok ($parser->close(), "Closing file");

done_testing();
