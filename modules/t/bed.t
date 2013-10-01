use strict;
use warnings;

use Test::More;

use Bio::EnsEMBL::Utils::IO qw( work_with_file );
use Bio::EnsEMBL::IO::Parser::BedParser;

my $test_file = "data.bed";

my $parser = Bio::EnsEMBL::IO::Parser::BedParser->open($test_file);
ok ($parser->next(), "Loading first record");
my @test_row = ('chr19', '6603909', '6764455', 'RP11-635J19', '1000',  '-', '6603909', '6764455', '0', '2', '407,441,',  '0,160105,');
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
ok ($parser->next(), "Loading second record");
@test_row = ('chr19', '6625260', '6722355', 'CTD-2240J22', '1000',  '+', '6625260', '6722355', '0', '2', '289,234,',  '0,96861,');
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
ok ($parser->close(), "Closing file");

done_testing();
