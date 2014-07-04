use strict;
use warnings;

use Test::More;

BEGIN { use_ok('Bio::EnsEMBL::IO::Parser::BLASTFormatter'); } 

my $test_file = "blast_formatter.data";
my $parser = Bio::EnsEMBL::IO::Parser::BLASTFormatter->open($test_file);

done_testing();
