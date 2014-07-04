use strict;
use warnings;

use Test::More;
use Bio::EnsEMBL::IO::Parser::BigBed;

######################################################
## Test 1
######################################################
my $parser = Bio::EnsEMBL::IO::Parser::BigBed->open('modules/t/data.bb');

ok($parser->next());
ok($parser->get_chrom eq 'chr1');
ok($parser->get_start == 3);
ok($parser->get_end == 6);
ok($parser->get_strand == 0);
ok($parser->get_name eq 'Mo');
ok($parser->get_score == 1000);

ok($parser->next);
ok($parser->get_chrom eq 'chr1');
ok($parser->get_start == 4);
ok($parser->get_end == 8);
ok($parser->get_strand);
ok($parser->get_name eq 'Larry');
ok($parser->get_score == 1000);

ok($parser->next);
ok($parser->get_chrom eq 'chr2');
ok($parser->get_start == 2);
ok($parser->get_end == 7);
ok($parser->get_strand == -1);
ok($parser->get_name eq 'Curly');
ok($parser->get_score == 1000);

ok(!$parser->next);

$parser->close();

done_testing;
