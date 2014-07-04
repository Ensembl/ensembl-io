use strict;
use warnings;

use Test::More;
use Bio::EnsEMBL::IO::Parser::BigWig;

######################################################
## Test 1
######################################################
my $parser = Bio::EnsEMBL::IO::Parser::BigWig->open("modules/t/data-variableStep.bw");

ok($parser->next);
ok($parser->get_chrom eq 'chr1');
ok($parser->get_start == 1);
ok($parser->get_end == 1);
ok($parser->get_score == 1);

for (my $i = 0; $i < 4; $i++) {
  ok($parser->next);
  ok($parser->get_chrom eq 'chr1');
  ok($parser->get_start == 2 + 2 * $i);
  ok($parser->get_end == 2 + 2 * $i);
  ok($parser->get_score == 2 + $i);
}

ok(!$parser->next);

$parser->close();

######################################################
## Test 2
######################################################
$parser = Bio::EnsEMBL::IO::Parser::BigWig->open('modules/t/data-fixedStep.bw');

for (my $i = 0; $i < 10; $i ++) {
  ok($parser->next);
  ok($parser->get_chrom eq 'chr1');
  ok($parser->get_start == 1 + $i);
  ok($parser->get_end == 1 + $i);
  ok($parser->get_score == $i);
}

ok(!$parser->next);

$parser->close();

done_testing;
