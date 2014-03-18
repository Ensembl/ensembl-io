use strict;
use warnings;

use Test::More;

use Bio::EnsEMBL::Utils::IO qw( work_with_file );
use Bio::EnsEMBL::IO::Parser::VEP_input;

my $test_file = "modules/t/data.vepi";

my $parser = Bio::EnsEMBL::IO::Parser::VEP_input->open($test_file);
ok ($parser->next(), "Loading first record");
ok ($parser->get_seqname() eq 19);
ok ($parser->get_start() == 66520);
ok ($parser->get_end() == 66520);
ok ($parser->get_allele() eq 'G/A');
ok ($parser->get_strand() == 1);
ok ($parser->get_id() eq 'var1');
ok ($parser->next(), "Loading second record");
ok ($parser->close(), "Closing file");

done_testing();
