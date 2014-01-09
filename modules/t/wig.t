use strict;
use warnings;

use Test::More;

use Bio::EnsEMBL::Utils::IO qw( work_with_file );
use Bio::EnsEMBL::IO::Parser::WigParser;

my $test_file = "data.wig";

my $parser = Bio::EnsEMBL::IO::Parser::WigParser->open($test_file, 'mustParseMetadata'=>1);
ok ($parser->next(), "Loading first record");

## NB: WIG files can contain BED format rows - that's what we're testing here!
my $test_desc = 'BED format';
is_deeply($parser->getTrackDescription, $test_desc, "Test track description");
my @test_row = (qw(chr19 58302000 58302300 -1.0));
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a BED row");
ok ($parser->close(), "Closing file");

done_testing();
