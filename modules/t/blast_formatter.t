use strict;
use warnings;

use Data::Dumper;
use Test::More;
use Test::Exception;

BEGIN { use_ok('Bio::EnsEMBL::IO::Parser::BLASTFormatter'); } 

my $parser;
my $test_file = "blast_test.6.default.tab";

###########################################
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
my $got_fields = $parser->get_fields();
is_deeply($got_fields, $default_fields, 'Default format specifiers with comma-separated values');
#
################################################################

done_testing();
