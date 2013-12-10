use strict;
use warnings;

use Test::More;
use Bio::EnsEMBL::IO::Parser::VCF4Parser;

my $test_file = "data_sv.vcf";

my ($test_info, $ind_info); 

my $parser = Bio::EnsEMBL::IO::Parser::VCF4Parser->open($test_file, mustParseMetadata => 1);

print "# Record 1\n";
ok ($parser->next(), "Loading first record");
my @test_row = (qw(1	2827694	rs2376870	CGTGGATGCGGGGAC	C	.	PASS	SVTYPE=DEL;END=2827762;HOMLEN=1;HOMSEQ=G;SVLEN=-68	GT:GQ	1/1:13.9));
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
print "> Testing each column of the row\n";
do_the_tests(\@test_row);
$test_info = "NA00001:$test_row[9]";
$ind_info  = $parser->getRawIndividualsInfo;
ok($test_info eq $ind_info->[0], 'Individual data');


print "\n# Record 2\n";
ok ($parser->next(), "Loading second record");
@test_row = (qw(2	321682	.	T	<DEL>	6	PASS	SVTYPE=DEL;END=321887;SVLEN=-205;CIPOS=-56,20;CIEND=-10,62	GT:GQ	0/1:12));
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
print "> Testing each column of the row\n";
do_the_tests(\@test_row);
$test_info = "NA00001:$test_row[9]";
$ind_info  = $parser->getRawIndividualsInfo;
ok($test_info eq $ind_info->[0], 'Individual data');


print "\n# Record 3\n";
ok ($parser->next(), "Loading third record");
@test_row = (qw(2	14477084	.	C	<DEL:ME:ALU>	12	PASS	SVTYPE=DEL;END=14477381;SVLEN=-297;CIPOS=-22,18;CIEND=-12,32	GT:GQ	0/1:12));
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
print "> Testing each column of the row\n";
do_the_tests(\@test_row);
$test_info = "NA00001:$test_row[9]";
$ind_info  = $parser->getRawIndividualsInfo;
ok($test_info eq $ind_info->[0], 'Individual data');


print "\n# Record 4\n";
ok ($parser->next(), "Loading fourth record");
@test_row = (qw(3	9425916	.	C	<INS:ME:L1>	23	PASS	SVTYPE=INS;END=9425916;SVLEN=6027;CIPOS=-16,22	GT:GQ	1/1:15));
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
print "> Testing each column of the row\n";
do_the_tests(\@test_row);
$test_info = "NA00001:$test_row[9]";
$ind_info  = $parser->getRawIndividualsInfo;
ok($test_info eq $ind_info->[0], 'Individual data');


print "\n# Record 5\n";
ok ($parser->next(), "Loading fifth record");
@test_row = (qw(3	12665100	.	A	<DUP>	14	PASS	SVTYPE=DUP;END=12686200;SVLEN=21100;CIPOS=-500,500;CIEND=-500,500	GT:GQ:CN:CNQ	./.:0:3:16.2));
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
print "> Testing each column of the row\n";
do_the_tests(\@test_row);
$test_info = "NA00001:$test_row[9]";
$ind_info  = $parser->getRawIndividualsInfo;
ok($test_info eq $ind_info->[0], 'Individual data');

print "\n# Record 6\n";
ok ($parser->next(), "Loading sixth record");
@test_row = (qw(4	18665128	.	T	<DUP:TANDEM>	11	PASS	SVTYPE=DUP;END=18665204;SVLEN=76;CIPOS=-10,10;CIEND=-10,10	GT:GQ:CN:CNQ	./.:0:5:8.3));
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
print "> Testing each column of the row\n";
do_the_tests(\@test_row);
$test_info = "NA00001:$test_row[9]";
$ind_info  = $parser->getRawIndividualsInfo;
ok($test_info eq $ind_info->[0], 'Individual data');

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
