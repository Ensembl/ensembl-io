use strict;
use warnings;

use Test::More;

use Bio::EnsEMBL::IO::Parser::PslParser;

my $test_file = "data.psl";

my $parser = Bio::EnsEMBL::IO::Parser::PslParser->open($test_file);
ok ($parser->next(), "Loading first record");
my $test_desc = 'Fish BLAT';
is_deeply($parser->getTrackDescription, $test_desc, "Test track description");
my @test_row = ('59', '9', '0', '0', '1', '823', '1', '96', '+-', 'FS_CONTIG_48080_1', '1955', '171', '1062', 'chr22', '47748585', '13073589', '13073753', '2', '48,20,',  '171,1042,',  '34674832,34674976,');
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
ok ($parser->next(), "Loading second record");
ok ($parser->next(), "Loading third record");
ok (!$parser->next(), "Reaching end of file");
ok ($parser->close(), "Closing file");

done_testing();
