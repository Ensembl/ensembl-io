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
use Bio::EnsEMBL::IO::Parser::VCF4;

my $test_file = "modules/t/input/data_sv.vcf";

my ($test_sample, $sample_info, $ind_info); 

my $parser = Bio::EnsEMBL::IO::Parser::VCF4->open($test_file);

my @inds = ('NA00001','NA00002','NA00003');
my $index = 0;

note "Record 1";
ok ($parser->next(), "Loading first record");
my @test_row = (qw(1	2827694	rs2376870	CGTGGATGCGGGGAC	C	.	PASS	SVTYPE=DEL;END=2827762;HOMLEN=1;HOMSEQ=G;SVLEN=-68	GT:GQ	1/1:13.9));
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
note "> Testing each column of the row";
do_the_tests(\@test_row);
$test_sample = [$inds[$index], $test_row[9]];
$ind_info  = $parser->get_raw_individuals_info($inds[$index]);
is_deeply($test_sample, $ind_info->[$index], 'Individual data (DEPRECATED)');
$sample_info = $parser->get_raw_samples_info($inds[$index]);
is_deeply($test_sample, $sample_info->[$index], 'Sample data');


note "Record 2";
ok ($parser->next(), "Loading second record");
@test_row = (qw(2	321682	.	T	<DEL>	6	PASS), 'SVTYPE=DEL;END=321887;SVLEN=-205;CIPOS=-56,20;CIEND=-10,62', 'GT:GQ', '0/1:12');
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
note "> Testing each column of the row";
do_the_tests(\@test_row);
$test_sample = [$inds[$index], $test_row[9]];
$ind_info  = $parser->get_raw_individuals_info($inds[$index]);
is_deeply($test_sample, $ind_info->[$index], 'Individual data (DEPRECATED)');
$sample_info = $parser->get_raw_samples_info($inds[$index]);
is_deeply($test_sample, $sample_info->[$index], 'Sample data');


note "Record 3";
ok ($parser->next(), "Loading third record");
@test_row = (qw(2	14477084	.	C	<DEL:ME:ALU>	12	PASS), 'SVTYPE=DEL;END=14477381;SVLEN=-297;CIPOS=-22,18;CIEND=-12,32', 'GT:GQ', '0/1:12');
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
note "> Testing each column of the row";
do_the_tests(\@test_row);
$test_sample = [$inds[$index], $test_row[9]];
$ind_info  = $parser->get_raw_individuals_info($inds[$index]);
is_deeply($test_sample, $ind_info->[$index], 'Individual data (DEPRECATED)');
$sample_info = $parser->get_raw_samples_info($inds[$index]);
is_deeply($test_sample, $sample_info->[$index], 'Sample data');


note "Record 4";
ok ($parser->next(), "Loading fourth record");
@test_row = (qw(3	9425916	.	C	<INS:ME:L1>	23	PASS), 'SVTYPE=INS;END=9425916;SVLEN=6027;CIPOS=-16,22', 'GT:GQ', '1/1:15');
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
note "> Testing each column of the row";
do_the_tests(\@test_row);
$test_sample = [$inds[$index], $test_row[9]];
$ind_info  = $parser->get_raw_individuals_info($inds[$index]);
is_deeply($test_sample, $ind_info->[$index], 'Individual data (DEPRECATED)');
$sample_info = $parser->get_raw_samples_info($inds[$index]);
is_deeply($test_sample, $sample_info->[$index], 'Sample data');


note "Record 5";
ok ($parser->next(), "Loading fifth record");
@test_row = (qw(3	12665100	.	A	<DUP>	14	PASS), 'SVTYPE=DUP;END=12686200;SVLEN=21100;CIPOS=-500,500;CIEND=-500,500', 'GT:GQ:CN:CNQ', './.:0:3:16.2');
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
note "> Testing each column of the row";
do_the_tests(\@test_row);
$test_sample = [$inds[$index], $test_row[9]];
$ind_info  = $parser->get_raw_individuals_info($inds[$index]);
is_deeply($test_sample, $ind_info->[$index], 'Individual data (DEPRECATED)');
$sample_info = $parser->get_raw_samples_info($inds[$index]);
is_deeply($test_sample, $sample_info->[$index], 'Sample data');

note "Record 6";
ok ($parser->next(), "Loading sixth record");
@test_row = (qw(4	18665128	.	T	<DUP:TANDEM>	11	PASS), 'SVTYPE=DUP;END=18665204;SVLEN=76;CIPOS=-10,10;CIEND=-10,10', 'GT:GQ:CN:CNQ', './.:0:5:8.3');
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
note "> Testing each column of the row";
do_the_tests(\@test_row);
$test_sample = [$inds[$index], $test_row[9]];
$ind_info  = $parser->get_raw_individuals_info($inds[$index]);
is_deeply($test_sample, $ind_info->[$index], 'Individual data (DEPRECATED)');
$sample_info = $parser->get_raw_samples_info($inds[$index]);
is_deeply($test_sample, $sample_info->[$index], 'Sample data');

note "Testing the SV specific getters (only for the last record):";
ok($parser->get_alternative_description('DUP:TANDEM') eq 'Tandem Duplication', 'get_alternative_description');
ok($parser->get_outer_start == 18665119, 'get_outer_start');
ok($parser->get_start == 18665129, 'get_start');
ok($parser->get_inner_start == 18665139, 'get_inner_start');
ok($parser->get_inner_end == 18665194, 'get_inner_end');
ok($parser->get_end == 18665204, 'get_end');
ok($parser->get_outer_end == 18665214, 'get_outer_end');

note "> Testing format validation";
$parser->reset();
$parser->shift_block();
ok ($parser->validate(), "Validating vcf format");

ok ($parser->close(), "Closing file");

done_testing();


sub do_the_tests {
  my $test = shift;

  ok($test->[0] eq $parser->get_raw_seqname,        'Chromosome');
  ok($test->[1] eq $parser->get_raw_start,          'Start');
  ok($test->[2] eq $parser->get_raw_IDs,            'Variant ID');
  ok($test->[3] eq $parser->get_raw_reference,      'Reference');
  ok($test->[4] eq $parser->get_raw_alternatives,   'Alternative(s)');
  ok($test->[5] eq $parser->get_raw_score,          'Score');
  ok($test->[6] eq $parser->get_raw_filter_results, 'Filter');
  ok($test->[7] eq $parser->get_raw_info,           'Info');
  ok($test->[8] eq $parser->get_raw_formats,        'Formats');
}
