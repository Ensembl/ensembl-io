use strict;
use warnings;

use Test::More;
use Test::Deep;

use Bio::EnsEMBL::IO::Parser::EMBL;

my $test_file = "modules/t/input/data.embl";
my $parser = Bio::EnsEMBL::IO::Parser::EMBL->open($test_file);

$parser->next;
my $accessions = $parser->get_accessions();
is_deeply($accessions,[qw(X56734 S46826)],'Accessions from first record');

is($parser->get_description,'Trifolium repens mRNA for non-cyanogenic beta-glucosidase','Description correct');

my $keywords = ['beta-glucosidase'];
is_deeply($parser->get_keywords,$keywords,'Keyword extraction');

is($parser->get_species,'Trifolium repens (white clover)','Species name intact');

my $taxonomy = [ 'Eukaryota', 'Viridiplantae', 'Streptophyta', 'Embryophyta', 'Tracheophyta',
                    'Spermatophyta', 'Magnoliophyta', 'eudicotyledons', 'core eudicotyledons', 'rosids',
                    'fabids', 'Fabales', 'Fabaceae', 'Papilionoideae', 'Trifolieae', 'Trifolium' ];
is_deeply($parser->get_classification,$taxonomy,'Taxonomy correct');


my $seq = 'aaacaaaccaaatatggattttattgtagccatatttgctctgtttgttattagctcattcacaattacttccacaaatgcagttgaagcttctactcttcttgacataggtaacctgagtcggagcagttttcctcgtggcttcatctttggtgctggatcttcagcataccaatttgaaggtgcagtaaacgaaggcggtagaggaccaagtatttgggataccttcacccataaatatccagaaaaaataagggatggaagcaatgcagacatcacggttgaccaatatcaccgctacaaggaagatgttgggattatgaaggatcaaaatatggattcgtatagattctcaatctcttggccaagaatactcccaaagggaaagttgagcggaggcataaatcacgaaggaatcaaatattacaacaaccttatcaacgaactattggctaacggtatacaaccatttgtaactctttttcattgggatcttccccaagtcttagaagatgagtatggtggtttcttaaactccggtgtaataaatgattttcgagactatacggatctttgcttcaaggaatttggagatagagtgaggtattggagtactctaaatgagccatgggtgtttagcaattctggatatgcactaggaacaaatgcaccaggtcgatgttcggcctccaacgtggccaagcctggtgattctggaacaggaccttatatagttacacacaatcaaattcttgctcatgcagaagctgtacatgtgtataagactaaataccaggcatatcaaaagggaaagataggcataacgttggtatctaactggttaatgccacttgatgataatagcataccagatataaaggctgccgagagatcacttgacttccaatttggattgtttatggaacaattaacaacaggagattattctaagagcatgcggcgtatagttaaaaaccgattacctaagttctcaaaattcgaatcaagcctagtgaatggttcatttgattttattggtataaactattactcttctagttatattagcaatgccccttcacatggcaatgccaaacccagttactcaacaaatcctatgaccaatatttcatttgaaaaacatgggatacccttaggtccaagggctgcttcaatttggatatatgtttatccatatatgtttatccaagaggacttcgagatcttttgttacatattaaaaataaatataacaatcctgcaattttcaatcactgaaaatggtatgaatgaattcaacgatgcaacacttccagtagaagaagctcttttgaatacttacagaattgattactattaccgtcacttatactacattcgttctgcaatcagggctggctcaaatgtgaagggtttttacgcatggtcatttttggactgtaatgaatggtttgcaggctttactgttcgttttggattaaactttgtagattagaaagatggattaaaaaggtaccctaagctttctgcccaatggtacaagaactttctcaaaagaaactagctagtattattaaaagaactttgtagtagattacagtacatcgtttgaagttgagttggtgcacctaattaaataaaagaggttactcttaacatatttttaggccattcgttgtgaagttgttaggctgttatttctattatactatgttgtagtaataagtgcattgttgtaccagaagctatgatcataactataggttgatccttcatgtatcagtttgatgttgagaatactttgaattaaaagtctttttttatttttttaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
is($parser->get_sequence(),$seq,'Sequence correctly cleaned up');

$parser->next;
$accessions = $parser->get_accessions();
note(join ' ',@$accessions);
cmp_deeply($accessions,[qw(P15056 A4D1T4 B6HY61 B6HY62 B6HY63 B6HY64 B6HY65 B6HY66 Q13878 Q3MIN6 Q9UDP8 Q9Y6T3)],'Accessions from second multiline record');

$keywords = ['3D-structure', 'Acetylation', 'ATP-binding', 'Cardiomyopathy', 'Cell membrane', 'Chromosomal rearrangement', 'Complete proteome', 
                'Cytoplasm', 'Deafness', 'Direct protein sequencing', 'Disease mutation', 'Ectodermal dysplasia', 'Kinase', 'Membrane', 'Mental retardation', 
                'Metal-binding', 'Methylation', 'Nucleotide-binding', 'Nucleus', 'Phosphoprotein', 'Polymorphism', 'Proto-oncogene', 'Reference proteome', 
                'Serine/threonine-protein kinase', 'Transferase', 'Ubl conjugation', 'Zinc', 'Zinc-finger'];
is_deeply($parser->get_keywords,$keywords,'Keyword extraction, second record');

ok(!$parser->next, 'Check end-of-file behaviour');
$parser->close;

done_testing;
