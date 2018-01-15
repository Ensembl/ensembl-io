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
use Bio::EnsEMBL::IO::Parser::VCF4Tabix;

my $test_file = "modules/t/input/data.vcf.gz";

my ($test_sample, $sample_info, $ind_info); 

my $parser = Bio::EnsEMBL::IO::Parser::VCF4Tabix->open($test_file);

$parser->seek(1,875500,876000);

my @inds = ('NA12891','NA12892','NA12878');

note "Record 1";
ok ($parser->next(), "Loading first record");
my @test_row = qw(1	875539	rs4970377	C	A	.	PASS	AA=.;DP=129;GP=1:885676;BN=111	GT:GQ:DP	1|1:100:43	1|1:49:26	1|1:100:47);
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
note "Testing each column of the row";
do_the_tests(\@test_row);
my $index = 0;
my $row_index = 9 + $index;
$test_sample = [$inds[$index], $test_row[$row_index]];
$ind_info  = $parser->get_raw_individuals_info($inds[$index]);
is_deeply($test_sample, $ind_info->[$index], 'Individual data (DEPRECATED)');
$sample_info = $parser->get_raw_samples_info($inds[$index]);
is_deeply($test_sample, $sample_info->[$index], 'Sample data');


note "Record 2";
ok ($parser->next(), "Loading second record");
@test_row = qw(1	875552	rs4970452	G	A	.	PASS	AA=.;DP=120;GP=1:885689;BN=111	GT:GQ:DP	1|1:100:33	1|1:57:26	1|1:100:49);
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
note "Testing each column of the row";
do_the_tests(\@test_row);
$index = 1;
$row_index = 9 + $index;
$test_sample = [$inds[$index], $test_row[$row_index]];
$ind_info  = $parser->get_raw_individuals_info($inds[$index]);
is_deeply($test_sample, $ind_info->[$index], 'Individual data (DEPRECATED)');
$sample_info = $parser->get_raw_samples_info($inds[$index]);
is_deeply($test_sample, $sample_info->[$index], 'Sample data');


note "Record 3";
ok ($parser->next(), "Loading third record");
@test_row = qw(1	875562	rs4970376	A	G	.	PASS	AA=.;DP=118;GP=1:885699;BN=111	GT:GQ:DP	1|1:86:27	1|1:86:27	1|1:100:52);
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
note "Testing each column of the row";
do_the_tests(\@test_row);
$index = 2;
$row_index = 9 + $index;
$test_sample = [$inds[$index], $test_row[$row_index]];
$ind_info  = $parser->get_raw_individuals_info($inds[$index]);
is_deeply($test_sample, $ind_info->[$index], 'Individual data (DEPRECATED)');
$sample_info = $parser->get_raw_samples_info($inds[$index]);
is_deeply($test_sample, $sample_info->[$index], 'Sample data');


note "Record 4";
ok ($parser->next(), "Loading fourth record");
@test_row = qw(1	875869	rs4970375	T	C	.	PASS	AA=.;DP=118;GP=1:886006;BN=111	GT:GQ:DP	1|1:83:27	1|1:76:30	1|1:100:51);
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
note "Testing each column of the row";
do_the_tests(\@test_row);
$index = 0;
$row_index = 9 + $index;
$test_sample = [$inds[$index], $test_row[$row_index]];
$ind_info  = $parser->get_raw_individuals_info($inds[$index]);
is_deeply($test_sample, $ind_info->[$index], 'Individual data (DEPRECATED)');
$sample_info = $parser->get_raw_samples_info($inds[$index]);
is_deeply($test_sample, $sample_info->[$index], 'Sample data');


print "\n> Testing the getters (only for the last record):\n";
ok($parser->get_seqname eq '1', 'get_seqname');
ok($parser->get_start == 875869, 'get_start');
ok($parser->get_end == 875869, 'get_end');
ok($parser->get_IDs->[0] eq 'rs4970375', 'get_IDs');
ok($parser->get_reference eq 'T', 'get_reference');
ok($parser->get_alternatives->[0] eq 'C', 'get_alternatives');
ok($parser->get_filter_results->[0] eq 'PASS' , 'get_filter_results');
ok($parser->get_info->{'BN'} eq '111' , 'get_info');
ok($parser->get_info_description('BN') eq 'First dbSNP build #' , 'get_information_description');
ok($parser->get_formats->[0] eq 'GT', 'get_formats');
ok($parser->get_format_description('GT') eq 'Genotype' , 'get_format_description');
$index = 0;
ok($parser->get_individuals_info($inds[$index])->{$inds[$index]}->{'GT'} eq '1|1', 'get_individuals_info (DEPRECATED)');
ok($parser->get_individuals_genotypes($inds[$index])->{$inds[$index]} eq 'C|C', 'get_individuals_genotypes (DEPRECATED)');
ok($parser->get_samples_info($inds[$index])->{$inds[$index]}->{'GT'} eq '1|1', 'get_samples_info');
ok($parser->get_samples_genotypes($inds[$index])->{$inds[$index]} eq 'C|C', 'get_samples_genotypes');

note "> Testing the metadata getters:";
ok($parser->get_metadata_key_list eq 'FORMAT, INFO, fileformat, header, reference', 'getMetadataKeyList');
ok($parser->get_vcf_version eq 'VCFv4.2', 'getVCFversion');
ok($parser->get_metadata_description('INFO', 'DP') eq 'Total Depth', 'getMetaDescription'); 

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
