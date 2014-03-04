use strict;
use warnings;

use Test::More;

use Bio::EnsEMBL::Utils::IO qw( work_with_file );
use Bio::EnsEMBL::IO::Parser::GenbankParser;

my $test_file = "data.gbk";

my $parser = Bio::EnsEMBL::IO::Parser::GenbankParser->open($test_file);
ok ($parser->next(), "Loading first record");
my @test_row = (qw(mmscl   supported_mRNA  CDS 40759   41225   .   +   .   Parent=mmscl));
is_deeply($parser->getAccession,'NC_012920',"Testing getAccession");
ok ($parser->close(), "Closing file");

done_testing();
