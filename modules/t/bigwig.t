use strict;
use warnings;

use Test::More;
use Bio::EnsEMBL::IO::Parser::BigWigParser;

######################################################
## Test 1
######################################################
my $parser = Bio::EnsEMBL::IO::Parser::BigWigParser->open("data-variableStep.bw");

ok($parser->next);
ok($parser->getChrom eq 'chr1');
ok($parser->getStart == 1);
ok($parser->getEnd == 1);
ok($parser->getScore == 1);

for (my $i = 0; $i < 4; $i++) {
  ok($parser->next);
  ok($parser->getChrom eq 'chr1');
  ok($parser->getStart == 2 + 2 * $i);
  ok($parser->getEnd == 2 + 2 * $i);
  ok($parser->getScore == 2 + $i);
}

ok(!$parser->next);

$parser->close();

######################################################
## Test 2
######################################################
$parser = Bio::EnsEMBL::IO::Parser::BigWigParser->open('data-fixedStep.bw');

for (my $i = 0; $i < 10; $i ++) {
  ok($parser->next);
  ok($parser->getChrom eq 'chr1');
  ok($parser->getStart == 1 + $i);
  ok($parser->getEnd == 1 + $i);
  ok($parser->getScore == $i);
}

ok(!$parser->next);

$parser->close();

done_testing;
