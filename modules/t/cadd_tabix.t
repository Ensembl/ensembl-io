# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
# Copyright [2016-2024] EMBL-European Bioinformatics Institute
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
use Bio::EnsEMBL::IO::Parser::CADDTabix;
use FindBin;

my $test_file = $FindBin::Bin . '/input/cadd.tsv.gz';

my $parser = Bio::EnsEMBL::IO::Parser::CADDTabix->open($test_file);

$parser->seek(10,102918295,102918295);

ok ($parser->next(), "Loading first record");
my @test_row = qw(10 102918295 C A 1.157959 14.09);
is_deeply($parser->{'record'}, \@test_row, "Test basic parsing of a row");
note "Testing each column of the row";
do_the_tests(\@test_row);

ok ($parser->next(), "Loading second record");
@test_row = qw(10 102918295 C G 1.179596 14.23);
is_deeply($parser->{'record'}, \@test_row, "Test basic parsing of a row");

ok ($parser->next(), "Loading third record");
@test_row = qw(10 102918295 C T 1.200556 14.36);
is_deeply($parser->{'record'}, \@test_row, "Test basic parsing of a row");
note "Testing each column of the row";
do_the_tests(\@test_row);

$parser->seek(10,302918295,302918295); 
ok ($parser->next() == 0, "Next returns 0 if non existing location was used in seek");

#$parser->seek(33,302918295,302918295); 
#ok ($parser->next() == 0, "Next returns 0 if non existing chromosome was used in seek");

ok ($parser->close(), "Closing file");

done_testing();

sub do_the_tests {
  my $test = shift;
  ok($test->[0] eq $parser->get_seqname,     'Chromosome');
  ok($test->[1] eq $parser->get_start,       'Start');
  ok($test->[2] eq $parser->get_reference,   'Reference');
  ok($test->[3] eq $parser->get_alternative, 'Alternative');
  ok($test->[4] eq $parser->get_raw_score,   'Raw score');
  ok($test->[5] eq $parser->get_phred_score, 'PHRED score');
}

