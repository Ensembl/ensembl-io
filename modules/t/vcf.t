use strict;
use warnings;

use Test::More;
use Bio::EnsEMBL::IO::Parser::VCF4Parser;

my $test_file = "data.vcf";

my ($test_info, $ind_info); 

my $parser = Bio::EnsEMBL::IO::Parser::VCF4Parser->open($test_file);

print "# Record 1\n";
ok ($parser->next(), "Loading first record");
my @test_row = (qw(20	14370	rs6054257	G	A	29	PASS	NS=3;DP=14;AF=0.5;DB;H2	GT:GQ:DP:HQ),	'0|0:48:1:51,51', '1|0:48:8:51,51', '1/1:43:5:.,.');
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
print "\n> Testing each column of the row\n";
do_the_tests(\@test_row);
$test_info = "NA00001:$test_row[9]";
$ind_info  = $parser->getRawIndividualsInfo;
ok($test_info eq $ind_info->[0], 'Individual data');


print "\n\n# Record 2\n";
ok ($parser->next(), "Loading second record");
@test_row = (qw(20	17330	.	T	A	3	q10	NS=3;DP=11;AF=0.017	GT:GQ:DP:HQ),	'0|0:49:3:58,50', '0|1:3:5:65,3', '0/0:41:3');
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
print "\n> Testing each column of the row\n";
do_the_tests(\@test_row);
$test_info = "NA00002:$test_row[10]";
$ind_info  = $parser->getRawIndividualsInfo;
ok($test_info eq $ind_info->[1], 'Individual data');


print "\n\n# Record 3\n";
ok ($parser->next(), "Loading third record");
@test_row = (qw(20	1110696	rs6040355	A), 'G,T', 67, 'PASS', 'NS=2;DP=10;AF=0.333,0.667;AA=T;DB', 'GT:GQ:DP:HQ', '1|2:21:6:23,27', '2|1:2:0:18,2', '2/2:35:4');
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
print "\n> Testing each column of the row\n";
do_the_tests(\@test_row);
$test_info = "NA00003:$test_row[11]";
$ind_info  = $parser->getRawIndividualsInfo;
ok($test_info eq $ind_info->[2], 'Individual data');


print "\n\n# Record 4\n";
ok ($parser->next(), "Loading fourth record");
@test_row = (qw(20	1230237	.	T	.	47	PASS	NS=3;DP=13;AA=T	GT:GQ:DP:HQ),	'0|0:54:7:56,60', '0|0:48:4:51,51', '0/0:61:2');
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
print "\n> Testing each column of the row\n";
do_the_tests(\@test_row);
$test_info = "NA00001:$test_row[9]";
$ind_info  = $parser->getRawIndividualsInfo;
ok($test_info eq $ind_info->[0], 'Individual data');


print "\n\n# Record 5\n";
ok ($parser->next(), "Loading fifth record");
@test_row = (qw(20	1234567	microsat1	GTC), 'G,GTCT', 50, 'PASS', qw(NS=3;DP=9;AA=G	GT:GQ:DP	0/1:35:4	0/2:17:2	1/1:40:3));
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
print "\n> Testing each column of the row\n";
do_the_tests(\@test_row);
$test_info = "NA00001:$test_row[9]";
$ind_info  = $parser->getRawIndividualsInfo;
ok($test_info eq $ind_info->[0], 'Individual data');

print "\n> Testing the getters (only for the last record):\n";
ok($parser->getSeqName eq '20', 'getSeqName');
ok($parser->getStart == 1234568, 'getStart');
ok($parser->getEnd == 1234570, 'getEnd');
ok($parser->getIDs->[0] eq 'microsat1', 'getIDs');
ok($parser->getReference eq 'GTC', 'getReference');
ok($parser->getAlternatives->[0] eq 'G', 'getAlternatives');
ok($parser->getScore == 50, 'getScore');
ok($parser->getFilterResults->[0] eq 'PASS' , 'getFilterResults');
ok($parser->getInfo->{'NS'} eq '3' , 'getInfo');
ok($parser->getInformationDescription('NS') eq 'Number of Samples With Data' , 'getInformationDescription');
ok($parser->getFormats->[0] eq 'GT', 'getFormats');
ok($parser->getFormatDescription('GT') eq 'Genotype' , 'getFormatDescription');
ok($parser->getIndividualsInfo->{'NA00001'}{'GT'} eq '0/1', 'getIndividualsInfo');
ok($parser->getIndividualsGenotypes->{'NA00001'} eq 'GTC|G', 'getIndividualsGenotypes');

print "\n> Testing the metadata getters:\n";
ok($parser->getMetadataKeyList eq 'FILTER, FORMAT, INFO, contig, fileDate, fileformat, header, phasing, reference, source', 'getMetadataKeyList');
ok($parser->getMetadataByPragma('fileDate') eq '20090805', 'getMetadataByPragma');
ok($parser->getVCFversion eq 'VCFv4.2', 'getVCFversion');
ok($parser->getMetaDescription('INFO', 'AA') eq 'Ancestral Allele', 'getMetaDescription'); 

print "\n";

ok ($parser->close(), "Closing file");

done_testing();


sub do_the_tests {
  my $test = shift;
  
  ok($test->[0] eq $parser->getRawSeqName,       'Chromosome');
  ok($test->[1] eq $parser->getRawStart,         'Start');
  ok($test->[2] eq $parser->getRawIDs,           'Variant ID');
  ok($test->[3] eq $parser->getRawReference,     'Reference');
  ok($test->[4] eq $parser->getRawAlternatives,  'Alternative(s)');
  ok($test->[5] eq $parser->getRawScore,         'Score');
  ok($test->[6] eq $parser->getRawFilterResults, 'Filter');
  ok($test->[7] eq $parser->getRawInfo,          'Info');
  ok($test->[8] eq $parser->getRawFormats,       'Formats');
}
