# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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

use Bio::EnsEMBL::IO::Parser::GFF3;

my $test_file = "modules/t/data.gff3";

my $parser = Bio::EnsEMBL::IO::Parser::GFF3->open($test_file);
ok ($parser->next(), "Loading first record");
my @test_row = (qw(mmscl   supported_mRNA  CDS 40759   41225   .   +   .   Parent=mmscl));
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
ok ($parser->next(), "Loading second record");
@test_row = (qw(mmscl   supported_mRNA  exon    61468   61729   .   +   .   Parent=mmMAP_17));
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
ok ($parser->close(), "Closing file");

done_testing();
