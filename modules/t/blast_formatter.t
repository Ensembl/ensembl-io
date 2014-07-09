use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN { use_ok('Bio::EnsEMBL::IO::Parser::BLASTFormatter'); } 

my $test_file = "blast_test.6.default.tab";

my $parser;

throws_ok { $parser = Bio::EnsEMBL::IO::Parser::BLASTFormatter->open() }
	  qr/Must provide name/, 'No file name argument caught';
throws_ok { $parser = Bio::EnsEMBL::IO::Parser::BLASTFormatter->open('non_existant_file') }
	  qr/Check file/, 'Non existant or unreadable file caught';
throws_ok { $parser = Bio::EnsEMBL::IO::Parser::BLASTFormatter->open($test_file) }
	  qr/Must provide format/, 'No format argument caught';

my $outfmt = 'aaa';
throws_ok { $parser = Bio::EnsEMBL::IO::Parser::BLASTFormatter->open($test_file, $outfmt) }
	  qr/must begin with number/, 'Non numeric format argument caught';
$outfmt = '1';
throws_ok { $parser = Bio::EnsEMBL::IO::Parser::BLASTFormatter->open($test_file, $outfmt) }
	  qr/must be either/, 'Invalid format argument caught';

$outfmt = 6;
$parser = Bio::EnsEMBL::IO::Parser::BLASTFormatter->open($test_file, $outfmt);

done_testing();
