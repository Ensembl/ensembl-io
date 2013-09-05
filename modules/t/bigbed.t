use strict;
use warnings;

use Test::More;
use Bio::EnsEMBL::IO::Parser::BigBedParser;

my $test_file = "data.bb";

######################################################
## Test 1
######################################################
my $parser = Bio::EnsEMBL::IO::Parser::BigBedParser->open($test_file);

ok($parser->next());
ok($parser->getChrom eq 'chr1');
ok($parser->getStart == 3);
ok($parser->getEnd == 6);
ok($parser->getStrand == 0);
ok($parser->getName eq 'Mo');
ok($parser->getScore == 1000);

ok($parser->next);
ok($parser->getChrom eq 'chr1');
ok($parser->getStart == 4);
ok($parser->getEnd == 8);
ok($parser->getStrand);
ok($parser->getName eq 'Larry');
ok($parser->getScore == 1000);

ok($parser->next);
ok($parser->getChrom eq 'chr2');
ok($parser->getStart == 2);
ok($parser->getEnd == 7);
ok($parser->getStrand == -1);
ok($parser->getName eq 'Curly');
ok($parser->getScore == 1000);

ok(!$parser->next);

$parser->close();


done_testing;
