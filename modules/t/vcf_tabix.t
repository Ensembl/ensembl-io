use strict;
use warnings;

use Test::More;
use Bio::EnsEMBL::IO::Parser::VCF4Tabix;

my $test_file = "modules/t/data.vcf.gz";

my ($test_info, $ind_info); 

my $parser = Bio::EnsEMBL::IO::Parser::VCF4Tabix->open($test_file);

$parser->seek(1,875500,876000);

print "# Record 1\n";
ok ($parser->next(), "Loading first record");
my @test_row = qw(1	875539	rs4970377	C	A	.	PASS	AA=.;DP=129;GP=1:885676;BN=111	GT:GQ:DP	1|1:100:43	1|1:49:26	1|1:100:47);
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
print "\n> Testing each column of the row\n";
do_the_tests(\@test_row);
$test_info = "NA12891:$test_row[9]";
$ind_info  = $parser->get_raw_individuals_info;
ok($test_info eq $ind_info->[0], 'Individual data');


print "\n\n# Record 2\n";
ok ($parser->next(), "Loading second record");
@test_row = qw(1	875552	rs4970452	G	A	.	PASS	AA=.;DP=120;GP=1:885689;BN=111	GT:GQ:DP	1|1:100:33	1|1:57:26	1|1:100:49);
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
print "\n> Testing each column of the row\n";
do_the_tests(\@test_row);
$test_info = "NA12892:$test_row[10]";
$ind_info  = $parser->get_raw_individuals_info;
ok($test_info eq $ind_info->[1], 'Individual data');


print "\n\n# Record 3\n";
ok ($parser->next(), "Loading third record");
@test_row = qw(1	875562	rs4970376	A	G	.	PASS	AA=.;DP=118;GP=1:885699;BN=111	GT:GQ:DP	1|1:86:27	1|1:86:27	1|1:100:52);
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
print "\n> Testing each column of the row\n";
do_the_tests(\@test_row);
$test_info = "NA12878:$test_row[11]";
$ind_info  = $parser->get_raw_individuals_info;
ok($test_info eq $ind_info->[2], 'Individual data');


print "\n\n# Record 4\n";
ok ($parser->next(), "Loading fourth record");
@test_row = qw(1	875869	rs4970375	T	C	.	PASS	AA=.;DP=118;GP=1:886006;BN=111	GT:GQ:DP	1|1:83:27	1|1:76:30	1|1:100:51);
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
print "\n> Testing each column of the row\n";
do_the_tests(\@test_row);
$test_info = "NA12891:$test_row[9]";
$ind_info  = $parser->get_raw_individuals_info;
ok($test_info eq $ind_info->[0], 'Individual data');


print "\n> Testing the getters (only for the last record):\n";
ok($parser->get_seqname eq '1', 'get_seqname');
ok($parser->get_start == 875870, 'get_start');
ok($parser->get_end == 875870, 'get_end');
ok($parser->get_IDs->[0] eq 'rs4970375', 'get_IDs');
ok($parser->get_reference eq 'T', 'get_reference');
ok($parser->get_alternatives->[0] eq 'C', 'get_alternatives');
ok($parser->get_filter_results->[0] eq 'PASS' , 'get_filter_results');
ok($parser->get_info->{'BN'} eq '111' , 'get_info');
ok($parser->get_info_description('BN') eq 'First dbSNP build #' , 'get_information_description');
ok($parser->get_formats->[0] eq 'GT', 'get_formats');
ok($parser->get_format_description('GT') eq 'Genotype' , 'get_format_description');
ok($parser->get_individuals_info->{'NA12891'}{'GT'} eq '1|1', 'get_Iindividuals_info');
ok($parser->get_individuals_genotypes->{'NA12891'} eq 'C|C', 'get_individuals_genotypes');

print "\n> Testing the metadata getters:\n";
ok($parser->get_metadata_key_list eq 'FORMAT, INFO, fileformat, header, reference', 'getMetadataKeyList');
ok($parser->get_vcf_version eq 'VCFv4.2', 'getVCFversion');
ok($parser->get_metadata_description('INFO', 'DP') eq 'Total Depth', 'getMetaDescription'); 

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
