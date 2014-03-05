use strict;
use warnings;

use Test::More;
use Test::Deep;

use Bio::EnsEMBL::IO::Parser::EMBLParser;

my $test_file = "data.embl";
my $parser = Bio::EnsEMBL::IO::Parser::EMBLParser->open($test_file);

$parser->next;
my $accessions = $parser->getAccessions();
is_deeply($accessions,[qw(X56734 S46826)],'Accessions from first record');

is($parser->getDescription,'Trifolium repens mRNA for non-cyanogenic beta-glucosidase','Description correct');

my $keywords = ['beta-glucosidase'];
is_deeply($parser->getKeywords,$keywords,'Keyword extraction');

is($parser->getSpecies,'Trifolium repens (white clover)','Species name intact');

my $taxonomy = [ 'Eukaryota', 'Viridiplantae', 'Streptophyta', 'Embryophyta', 'Tracheophyta',
                    'Spermatophyta', 'Magnoliophyta', 'eudicotyledons', 'core eudicotyledons', 'rosids',
                    'fabids', 'Fabales', 'Fabaceae', 'Papilionoideae', 'Trifolieae', 'Trifolium' ];
is_deeply($parser->getClassification,$taxonomy,'Taxonomy correct');


my $seq = 'aaacaaaccaaatatggattttattgtagccatatttgctctgtttgttattagctcattcacaattacttccacaaatgcagttgaagcttctactcttcttgacataggtaacctgagtcggagcagttttcctcgtggcttcatctttggtgctggatcttcagcataccaatttgaaggtgcagtaaacgaaggcggtagaggaccaagtatttgggataccttcacccataaatatccagaaaaaataagggatggaagcaatgcagacatcacggttgaccaatatcaccgctacaaggaagatgttgggattatgaaggatcaaaatatggattcgtatagattctcaatctcttggccaagaatactcccaaagggaaagttgagcggaggcataaatcacgaaggaatcaaatattacaacaaccttatcaacgaactattggctaacggtatacaaccatttgtaactctttttcattgggatcttccccaagtcttagaagatgagtatggtggtttcttaaactccggtgtaataaatgattttcgagactatacggatctttgcttcaaggaatttggagatagagtgaggtattggagtactctaaatgagccatgggtgtttagcaattctggatatgcactaggaacaaatgcaccaggtcgatgttcggcctccaacgtggccaagcctggtgattctggaacaggaccttatatagttacacacaatcaaattcttgctcatgcagaagctgtacatgtgtataagactaaataccaggcatatcaaaagggaaagataggcataacgttggtatctaactggttaatgccacttgatgataatagcataccagatataaaggctgccgagagatcacttgacttccaatttggattgtttatggaacaattaacaacaggagattattctaagagcatgcggcgtatagttaaaaaccgattacctaagttctcaaaattcgaatcaagcctagtgaatggttcatttgattttattggtataaactattactcttctagttatattagcaatgccccttcacatggcaatgccaaacccagttactcaacaaatcctatgaccaatatttcatttgaaaaacatgggatacccttaggtccaagggctgcttcaatttggatatatgtttatccatatatgtttatccaagaggacttcgagatcttttgttacatattaaaaataaatataacaatcctgcaattttcaatcactgaaaatggtatgaatgaattcaacgatgcaacacttccagtagaagaagctcttttgaatacttacagaattgattactattaccgtcacttatactacattcgttctgcaatcagggctggctcaaatgtgaagggtttttacgcatggtcatttttggactgtaatgaatggtttgcaggctttactgttcgttttggattaaactttgtagattagaaagatggattaaaaaggtaccctaagctttctgcccaatggtacaagaactttctcaaaagaaactagctagtattattaaaagaactttgtagtagattacagtacatcgtttgaagttgagttggtgcacctaattaaataaaagaggttactcttaacatatttttaggccattcgttgtgaagttgttaggctgttatttctattatactatgttgtagtaataagtgcattgttgtaccagaagctatgatcataactataggttgatccttcatgtatcagtttgatgttgagaatactttgaattaaaagtctttttttatttttttaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
is($parser->getSequence(),$seq,'Sequence correctly cleaned up');

$parser->next;
$accessions = $parser->getAccessions();
note(join ' ',@$accessions);
cmp_deeply($accessions,[qw(P15056 A4D1T4 B6HY61 B6HY62 B6HY63 B6HY64 B6HY65 B6HY66 Q13878 Q3MIN6 Q9UDP8 Q9Y6T3)],'Accessions from second multiline record');

$keywords = ['3D-structure', 'Acetylation', 'ATP-binding', 'Cardiomyopathy', 'Cell membrane', 'Chromosomal rearrangement', 'Complete proteome', 
                'Cytoplasm', 'Deafness', 'Direct protein sequencing', 'Disease mutation', 'Ectodermal dysplasia', 'Kinase', 'Membrane', 'Mental retardation', 
                'Metal-binding', 'Methylation', 'Nucleotide-binding', 'Nucleus', 'Phosphoprotein', 'Polymorphism', 'Proto-oncogene', 'Reference proteome', 
                'Serine/threonine-protein kinase', 'Transferase', 'Ubl conjugation', 'Zinc', 'Zinc-finger'];
is_deeply($parser->getKeywords,$keywords,'Keyword extraction, second record');

ok(!$parser->next, 'Check end-of-file behaviour');
$parser->close;

done_testing;