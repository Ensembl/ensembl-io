use strict;
use warnings;

use Test::More;

use Bio::EnsEMBL::IO::Parser::PslParser;

my $test_file = "data.psl";

my $parser = Bio::EnsEMBL::IO::Parser::PslParser->open($test_file);
ok ($parser->next(), "Loading first record");
my $test_desc = 'Fish BLAT';
is_deeply($parser->getTrackDescription, $test_desc, "Test track description");
ok ($parser->getMatches() eq 59, "Matches");
ok ($parser->getMisMatches() eq 9, 'MisMatches');
ok ($parser->getRepMatches() eq 0, 'RepMatches');
ok ($parser->getNCount() eq 0, 'NCount');
ok ($parser->getQNumInsert() eq 1, 'QNumInsert');
ok ($parser->getQBaseInsert() eq 823, 'QBaseInsert');
ok ($parser->getTNumInsert() eq 1, 'TNumInsert');
ok ($parser->getTBaseInsert() eq 96, 'TBaseInsert');
ok ($parser->getStrand() eq '-', 'Strand');
ok ($parser->getQName() eq 'FS_CONTIG_48080_1', 'QName');
ok ($parser->getQSize() eq 1955, 'QSize');
ok ($parser->getQStart() eq 171, 'QStart');
ok ($parser->getQEnd() eq 1062, 'QEnd');
ok ($parser->getTName() eq 22, 'TName');
ok ($parser->getTSize() eq 47748585, 'TSize');
ok ($parser->getTStart() eq 13073590, 'TStart');
ok ($parser->getTEnd() eq 13073753, 'TEnd');
ok ($parser->getBlockCount() eq 2, 'BlockCount');
my @A = $parser->getBlockSizes();
ok ($A[0] eq 48, 'BlockSizes');
my @B = $parser->getQStarts();
ok ($B[0] eq 171, 'QStarts');
my @C = $parser->getTStarts();
ok ($C[0] eq 34674832, 'TStarts');
ok ($parser->next(), "Loading second record");
ok ($parser->next(), "Loading third record");
ok (!$parser->next(), "Reaching end of file");
ok ($parser->close(), "Closing file");

done_testing();
