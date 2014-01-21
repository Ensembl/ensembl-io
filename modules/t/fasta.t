use strict;
use warnings;

use Test::More;

use Bio::EnsEMBL::IO::Parser::FastaParser;

my $test_file = "data.fasta";

######################################################
## Test 1
######################################################
my $parser = Bio::EnsEMBL::IO::Parser::FastaParser->open($test_file);
ok($parser->next());
ok(length($parser->getHeader()) == 44, "Check length of header");
ok(scalar(@{$parser->getRawSequence()}) == 17,"Check size of first FASTA block");
ok($parser->next());
ok(scalar(@{$parser->getRawSequence()}) == 14,"Check size of second FASTA block");
ok(!$parser->next(), "Final attempt to read returns nothing.");
ok($parser->close());

done_testing;
