use strict;
use warnings;

use Test::More;

use Bio::EnsEMBL::Utils::IO qw( work_with_file );
use Bio::EnsEMBL::IO::Parser::BedParser;

my $test_file = "data.bed";

my $parser = Bio::EnsEMBL::IO::Parser::BedParser->open($test_file);
ok ($parser->next(), "Loading first record");
ok ($parser->getSeqName() eq 19);
ok ($parser->getStart() == 6603910);
ok ($parser->getEnd() == 6764455);
ok ($parser->getName() eq 'RP11-635J19');
ok ($parser->getScore() eq 1000);
ok ($parser->getStrand() == -1);
ok ($parser->getThickStart() == 6603909);
ok ($parser->getThickEnd() == 6764455);
ok ($parser->getItemRGB() == 0);
ok ($parser->getBlockCount() == 2);
my @test_starts = (407, 441);
is_deeply($parser->getBlockSizes(), \@test_starts, "Testing block sizes");
my @test_lengths = (0, 160105);
is_deeply($parser->getBlockStarts(), \@test_lengths, "Testing block starts");
ok ($parser->next(), "Loading second record");
ok ($parser->close(), "Closing file");

done_testing();
