use strict;
use warnings;

use Test::More;

use Bio::EnsEMBL::Utils::IO qw( work_with_file );
use Bio::EnsEMBL::IO::Parser::GenbankParser;

my $test_file = "data.gbk";

my $parser = Bio::EnsEMBL::IO::Parser::GenbankParser->open($test_file);
ok ($parser->next(), "Loading first record");
is($parser->getAccession,'NC_012920',"Testing getAccession");
is($parser->getSeqName,'NC_012920.1',"Testing getSeqName");
is($parser->getSeqVersion,'1',"Testing getSeqVersion");
is($parser->getLength,'16569',"Testing getLength");
is($parser->getGenbankId,'251831106',"Testing getGenbankId");
is($parser->getOrganism,'Homo sapiens',"Testing getOrganism");
is($parser->getDescription,'Homo sapiens mitochondrion, complete genome.',"Testing getDescription");
is($parser->getLocusId,'NC_012920',"Testing getLocusId");
is($parser->getType,'DNA',"Testing getType");
is($parser->getModificationDate,'02-JAN-2014',"Testing getModificationDate");
is($parser->getSource,'mitochondrion Homo sapiens (human)',"Testing getSource");
is($parser->getTaxonId,'9606',"Testing getTaxonId");
ok($parser->is_circular, "Testing is_circular");
ok($parser->getLength == length($parser->getSequence), "Testing lenght of the sequence");
is(scalar(@{$parser->getFeatures}), 106, "Testing number of features");
ok ($parser->close(), "Closing file");

done_testing();
