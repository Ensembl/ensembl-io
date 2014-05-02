use strict;
use warnings;

use Test::More;
use Bio::EnsEMBL::IO::Parser::VCF4;

my $test_file = "modules/t/data.vcf";

my ($test_info, $ind_info); 

my $parser = Bio::EnsEMBL::IO::Parser::VCF4->open($test_file);

print "# Record 1\n";
ok ($parser->next(), "Loading first record");
my @test_row = (qw(20	14370	rs6054257	G	A	29	PASS	NS=3;DP=14;AF=0.5;DB;H2	GT:GQ:DP:HQ),	'0|0:48:1:51,51', '1|0:48:8:51,51', '1/1:43:5:.,.');
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
print "\n> Testing each column of the row\n";
do_the_tests(\@test_row);
$test_info = "NA00001:$test_row[9]";
$ind_info  = $parser->get_raw_individuals_info;
ok($test_info eq $ind_info->[0], 'Individual data');


print "\n\n# Record 2\n";
ok ($parser->next(), "Loading second record");
@test_row = (qw(20	17330	.	T	A	3	q10	NS=3;DP=11;AF=0.017	GT:GQ:DP:HQ),	'0|0:49:3:58,50', '0|1:3:5:65,3', '0/0:41:3');
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
print "\n> Testing each column of the row\n";
do_the_tests(\@test_row);
$test_info = "NA00002:$test_row[10]";
$ind_info  = $parser->get_raw_individuals_info;
ok($test_info eq $ind_info->[1], 'Individual data');


print "\n\n# Record 3\n";
ok ($parser->next(), "Loading third record");
@test_row = (qw(20	1110696	rs6040355	A), 'G,T', 67, 'PASS', 'NS=2;DP=10;AF=0.333,0.667;AA=T;DB', 'GT:GQ:DP:HQ', '1|2:21:6:23,27', '2|1:2:0:18,2', '2/2:35:4');
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
print "\n> Testing each column of the row\n";
do_the_tests(\@test_row);
$test_info = "NA00003:$test_row[11]";
$ind_info  = $parser->get_raw_individuals_info;
ok($test_info eq $ind_info->[2], 'Individual data');


print "\n\n# Record 4\n";
ok ($parser->next(), "Loading fourth record");
@test_row = (qw(20	1230237	.	T	.	47	PASS	NS=3;DP=13;AA=T	GT:GQ:DP:HQ),	'0|0:54:7:56,60', '0|0:48:4:51,51', '0/0:61:2');
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
print "\n> Testing each column of the row\n";
do_the_tests(\@test_row);
$test_info = "NA00001:$test_row[9]";
$ind_info  = $parser->get_raw_individuals_info;
ok($test_info eq $ind_info->[0], 'Individual data');


print "\n\n# Record 5\n";
ok ($parser->next(), "Loading fifth record");
@test_row = (qw(20	1234567	microsat1	GTC), 'G,GTCT', 50, 'PASS', qw(NS=3;DP=9;AA=G	GT:GQ:DP	0/1:35:4	0/2:17:2	1/1:40:3));
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
print "\n> Testing each column of the row\n";
do_the_tests(\@test_row);
$test_info = "NA00001:$test_row[9]";
$ind_info  = $parser->get_raw_individuals_info;
ok($test_info eq $ind_info->[0], 'Individual data');

print "\n> Testing the getters (only for the last record):\n";
ok($parser->get_seqname eq '20', 'get_seqname');
ok($parser->get_start == 1234568, 'get_start');
ok($parser->get_end == 1234570, 'get_end');
ok($parser->get_IDs->[0] eq 'microsat1', 'get_IDs');
ok($parser->get_reference eq 'GTC', 'get_reference');
ok($parser->get_alternatives->[0] eq 'G', 'get_alternatives');
ok($parser->get_score == 50, 'get_score');
ok($parser->get_filter_results->[0] eq 'PASS' , 'get_filter_results');
ok($parser->get_info->{'NS'} eq '3' , 'get_info');
ok($parser->get_info_description('NS') eq 'Number of Samples With Data' , 'get_information_description');
ok($parser->get_formats->[0] eq 'GT', 'get_formats');
ok($parser->get_format_description('GT') eq 'Genotype' , 'get_format_description');
ok($parser->get_individuals_info->{'NA00001'}{'GT'} eq '0/1', 'get_Iindividuals_info');
ok($parser->get_individuals_genotypes->{'NA00001'} eq 'GTC|G', 'get_individuals_genotypes');

print "\n> Testing the metadata getters:\n";
ok($parser->get_metadata_key_list eq 'FILTER, FORMAT, INFO, contig, fileDate, fileformat, header, phasing, reference, source', 'getMetadataKeyList');
ok($parser->get_metadata_by_pragma('fileDate') eq '20090805', 'getMetadataByPragma');
ok($parser->get_vcf_version eq 'VCFv4.2', 'getVCFversion');
ok($parser->get_metadata_description('INFO', 'AA') eq 'Ancestral Allele', 'getMetaDescription'); 

print "\n";

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
