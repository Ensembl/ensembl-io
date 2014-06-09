use strict;
use warnings;

use Test::More;

use Bio::EnsEMBL::Utils::IO qw( work_with_file );
use Bio::EnsEMBL::IO::Parser::SimpleList;

my $test_file = "modules/t/data.txt";

my $parser = Bio::EnsEMBL::IO::Parser::SimpleList->open($test_file);
ok ($parser->next(), "Loading first record");
ok ($parser->get_value() eq 'ENSMUST00000062783');
ok ($parser->next(), "Loading second record");
ok ($parser->close(), "Closing file");

done_testing();
