use strict;
use warnings;

use Test::More;

use Bio::EnsEMBL::IO::Parser::WigParser;

my $test_file = "data.wig";

my $parser = Bio::EnsEMBL::IO::Parser::WigParser->open($test_file);
ok ($parser->next(), "Loading first record");

## NB: WIG files can contain BED format rows - that's what we're testing here!
my $test_desc = 'BED format';
is_deeply($parser->get_track_description, $test_desc, "Testing track description");
ok ($parser->get_wiggle_type() eq 'bedGraph', 'bedGraph');
ok ($parser->get_seqname() eq 19, 'SeqName');
ok ($parser->get_start() eq 58302001, 'Start');
ok ($parser->get_end() eq 58302300, 'End');
ok ($parser->get_score() eq '-1.0', 'Score');
## Load rest of track
for (my $i = 2; $i < 10; $i++) {
	ok ($parser->next(), "Loading record " . $i);
}

## Checking WIG format variableStep
ok ($parser->next(), "Loading first record of second track");
$test_desc = 'variableStep format';
is_deeply($parser->get_track_description, $test_desc, "Testing track description");
my $type = $parser->get_wiggle_type();
ok ($parser->get_wiggle_type() eq 'variableStep', 'Variable Step format');
ok ($parser->get_seqname() eq 19, 'SeqName');
ok ($parser->get_start() eq 58304701, 'Start');
ok ($parser->get_end() eq 58304850, 'End');
ok ($parser->get_score() eq '10.0', 'Score');
## Load rest of track
for (my $i = 11; $i < 19; $i++) {
	ok ($parser->next(), "Loading record " . $i);
}

## Checking WIG format fixedStep
ok ($parser->next(), "Loading first record of third track");
$test_desc = 'fixed step';
is_deeply($parser->get_track_description, $test_desc, "Testing track description");
$type = $parser->get_wiggle_type();
ok ($parser->get_wiggle_type() eq 'fixedStep', 'Fixed Step format');
ok ($parser->next(), "Loading second record of third track");
ok ($parser->get_seqname() eq 19, 'SeqName');
ok ($parser->get_start() eq 58307701, 'Start');
ok ($parser->get_end() eq 58307900, 'End');
ok ($parser->get_score() eq '900', 'Score');
## Load rest of track
for (my $i = 21; $i < 29; $i++) {
	ok ($parser->next(), "Loading record " . $i);
}

ok (!$parser->next(), "Reaching end of file");
ok ($parser->close(), "Closing file");

done_testing();
