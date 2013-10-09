use strict;
use warnings;
use Data::Dumper;

use Bio::EnsEMBL::IO::Parser::EMFParser;

#my $test_file = 'modules/t/Compara.13_eutherian_mammals_EPO.chr1_26.emf';
my $test_file = 'modules/t/Homo_sapiens.GRCh37.73.resequencing.chromosome.21.emf';
my $parser = Bio::EnsEMBL::IO::Parser::EMFParser->open($test_file);

my $next_record = $parser->next;
print STDERR "FORMAT: ", $parser->format(), "\n";
print STDERR "TREE: ", $parser->tree, "\n";
print STDERR Dumper $parser->score_types;
print STDERR Dumper $parser->sequences;

while (my $column = $parser->get_next_column) {
  print STDERR "Next column is: ", Dumper $column;
}
