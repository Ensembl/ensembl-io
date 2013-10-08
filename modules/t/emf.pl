use strict;
use warnings;
use Data::Dumper;

use Bio::EnsEMBL::IO::Parser::EMFParser;

my $test_file = 'modules/t/Compara.13_eutherian_mammals_EPO.chr1_26.emf';

my $parser = Bio::EnsEMBL::IO::Parser::EMFParser->open($test_file);

my $next_record = $parser->next;
print STDERR "FORMAT: ", $parser->format(), "\n";

#print STDERR "NEXT RECORD: $next_record\n";

print STDERR Dumper $parser->sequences;

