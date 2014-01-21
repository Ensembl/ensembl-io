use strict;
use warnings;

use Test::More;

use Bio::EnsEMBL::IO::Parser::WigParser;

my $test_file = "data.wig";

my $parser = Bio::EnsEMBL::IO::Parser::WigParser->open($test_file);
ok ($parser->next(), "Loading first record");

## NB: WIG files can contain BED format rows - that's what we're testing here!
my $test_desc = 'BED format';
is_deeply($parser->getTrackDescription, $test_desc, "Test track description");
for (my $i = 2; $i < 29; $i++) {
	ok ($parser->next(), "Loading record " . $i);
}
ok (!$parser->next(), "Reaching end of file");
ok ($parser->close(), "Closing file");

done_testing();
