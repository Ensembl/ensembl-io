use strict;
use warnings;

use Data::Dumper;
use Test::More;
use Test::Exception;

BEGIN { use_ok('Bio::EnsEMBL::IO::Parser::BLASTFormatter'); } 

my $parser;
my $test_file = "blast_test.6.default.tab";

###########################################
#
# Test invalid argument exception handling
#
throws_ok { $parser = Bio::EnsEMBL::IO::Parser::BLASTFormatter->open() }
	  qr/Must provide name/, 'No file name argument caught';
throws_ok { $parser = Bio::EnsEMBL::IO::Parser::BLASTFormatter->open('non_existant_file') }
	  qr/Check file/, 'Non existant or unreadable file caught';
throws_ok { $parser = Bio::EnsEMBL::IO::Parser::BLASTFormatter->open($test_file) }
	  qr/Must provide format/, 'No format argument caught';

my $outfmt = 'aaa';
throws_ok { $parser = Bio::EnsEMBL::IO::Parser::BLASTFormatter->open($test_file, $outfmt) }
	  qr/must begin with number/, 'Non numeric output format argument caught';
$outfmt = '1';
throws_ok { $parser = Bio::EnsEMBL::IO::Parser::BLASTFormatter->open($test_file, $outfmt) }
	  qr/must be either/, 'Invalid format argument caught';
#
###########################################

################################################################
#
# Test parsing of format specifiers from output format argument
#
$outfmt = 6; # default format specifiers
$parser = Bio::EnsEMBL::IO::Parser::BLASTFormatter->open($test_file, $outfmt);
is($parser->{delimiter}, '\t', 'Tab delimiter');

my $default_fields = [ qw/qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore/ ];
my $got_fields = $parser->get_fields();
is_deeply($got_fields, $default_fields, 'Default format specifiers with tab-separated values');

$outfmt = '7 qacc sacc evalue score rident pident qstart qend sstart send length positive ppos qseq sseq';
$parser = Bio::EnsEMBL::IO::Parser::BLASTFormatter->open($test_file, $outfmt);
is($parser->{delimiter}, '\t', 'Tab delimiter');
my $compara_fields = [ qw/qacc sacc evalue score rident pident qstart qend sstart send length positive ppos qseq sseq/ ];
$got_fields = $parser->get_fields();
is_deeply($got_fields, $compara_fields, 'Compara format specifiers');

$outfmt = 10;
$parser = Bio::EnsEMBL::IO::Parser::BLASTFormatter->open($test_file, $outfmt);
is($parser->{delimiter}, ',', 'Comma-delimiter');
$got_fields = $parser->get_fields();
is_deeply($got_fields, $default_fields, 'Default format specifiers with comma-separated values');
#
################################################################

#################################################################
#
# Test invalid calls to automatically generated accessor methods
#
$outfmt = 6; # default format specifiers
$parser = Bio::EnsEMBL::IO::Parser::BLASTFormatter->open($test_file, $outfmt);
throws_ok { $parser->get_raw_qacc() }
	  qr/Invalid attribute method/, 'Invalid attribute getter call caught';
throws_ok { $parser->get_score() }
	  qr/Invalid attribute method/, 'Invalid attribute getter call caught';
throws_ok { $parser->get_gapopen() }
	  qr/Cannot get attribute/, 'Invalid attribute getter call caught';

$outfmt = '7 qacc sacc evalue score rident pident qstart qend sstart send length positive ppos qseq sseq';
$parser = Bio::EnsEMBL::IO::Parser::BLASTFormatter->open($test_file, $outfmt);
throws_ok { $parser->get_raw_sseqid() }
	  qr/Invalid attribute method/, 'Invalid attribute getter call caught';
throws_ok { $parser->get_mismatch() }
	  qr/Invalid attribute method/, 'Invalid attribute getter call caught';
#
#################################################################

#######################################################
#
# Test parsing tabular format with default specifiers
#
$outfmt = 6; # default format specifiers
$test_file = "blast_test.6.default.tab";
$parser = Bio::EnsEMBL::IO::Parser::BLASTFormatter->open($test_file, $outfmt);
ok($parser->next(), "Loading first record");
my @expected_record = ( qw/gnl|MYDB|1	gi|405832|gb|U00001.1|HSCDC27	100.00	720	0	0	1	720	1	720	0.0	1330/ );
is_deeply($parser->{record}, \@expected_record, "First record");
is($parser->get_qseqid, 'gnl|MYDB|1', 'Query seq-id');
is($parser->get_length, 720, 'Alignment length');
ok($parser->get_evalue == 0.0, 'E-value');
ok($parser->get_bitscore == 1330, 'Bit score');

# seek to sixth record
map { $parser->next() } (1 .. 5);
@expected_record = ( qw/gnl|MYDB|1	gi|578831755|ref|XR_429935.1|	100.00	714	0	0	7	720	76	789	0.0	1319/);
is_deeply($parser->{record}, \@expected_record, "Sixth record");
ok($parser->get_pident == 100, 'Percentage of identical matches');
is($parser->get_length, 714, 'Alignment length');
is($parser->get_qstart, 7, 'Start of alignment in query');
is($parser->get_send, 789, 'End of alignment in query');

# seek to last record
diag("Parse last record");
map { $parser->next() } (1 .. 245); 
ok($parser->get_pident == 92.79, 'Percentage of identical matches');
is($parser->get_mismatch, 46, 'Number of mismatches');
is($parser->get_bitscore, 924, 'Bit score');
ok(!$parser->next(), 'No more records');
#
#######################################################

#####################################################################################
# Test parsing tabular format with comment lines, compara-specific format specifiers 
#
$outfmt = '7 qacc sacc evalue score rident pident qstart qend sstart send length positive ppos qseq sseq';
$test_file = "blast_test.7.compara.tab";
$parser = Bio::EnsEMBL::IO::Parser::BLASTFormatter->open($test_file, $outfmt);

#
#####################################################################################

# my $default_fields = [ qw/qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore/ ];
done_testing();
