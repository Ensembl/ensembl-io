use strict;
use warnings;

use Test::More;

use Bio::EnsEMBL::Utils::IO qw( work_with_file );
use Bio::EnsEMBL::IO::Parser::Bed;

my $test_file = "modules/t/data.bed";

my $parser = Bio::EnsEMBL::IO::Parser::Bed->open($test_file);
ok ($parser->next(), "Loading first record");
ok ($parser->get_seqname() eq 19);
ok ($parser->get_start() == 6603910);
ok ($parser->get_end() == 6764455);
ok ($parser->get_name() eq 'RP11-635J19');
ok ($parser->get_score() eq 1000);
ok ($parser->get_strand() == -1);
ok ($parser->get_thickStart() == 6603909);
ok ($parser->get_thickEnd() == 6764455);
ok ($parser->get_itemRgb() == 0);
ok ($parser->get_blockCount() == 2);
my @test_starts = (407, 441);
is_deeply($parser->get_blockSizes(), \@test_starts, "Testing block sizes");
my @test_lengths = (0, 160105);
is_deeply($parser->get_blockStarts(), \@test_lengths, "Testing block starts");
ok ($parser->next(), "Loading second record");
ok ($parser->close(), "Closing file");

done_testing();
