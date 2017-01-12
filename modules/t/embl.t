use strict;
use warnings;

use Test::More;
use Test::Deep;

use Bio::EnsEMBL::IO::Parser::EMBL;

my $test_file = "modules/t/input/data.embl";
my $parser = Bio::EnsEMBL::IO::Parser::EMBL->open($test_file);

$parser->next;

is($parser->get_id(), 'X56734', 'ID from first record');

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
is_deeply($parser->get_database_cross_references, ['EuropePMC:PMC99098'], 'DB xrefs from first record');

my $seq = 'aaacaaaccaaatatggattttattgtagccatatttgctctgtttgttattagctcattcacaattacttccacaaatgcagttgaagcttctactcttcttgacataggtaacctgagtcggagcagttttcctcgtggcttcatctttggtgctggatcttcagcataccaatttgaaggtgcagtaaacgaaggcggtagaggaccaagtatttgggataccttcacccataaatatccagaaaaaataagggatggaagcaatgcagacatcacggttgaccaatatcaccgctacaaggaagatgttgggattatgaaggatcaaaatatggattcgtatagattctcaatctcttggccaagaatactcccaaagggaaagttgagcggaggcataaatcacgaaggaatcaaatattacaacaaccttatcaacgaactattggctaacggtatacaaccatttgtaactctttttcattgggatcttccccaagtcttagaagatgagtatggtggtttcttaaactccggtgtaataaatgattttcgagactatacggatctttgcttcaaggaatttggagatagagtgaggtattggagtactctaaatgagccatgggtgtttagcaattctggatatgcactaggaacaaatgcaccaggtcgatgttcggcctccaacgtggccaagcctggtgattctggaacaggaccttatatagttacacacaatcaaattcttgctcatgcagaagctgtacatgtgtataagactaaataccaggcatatcaaaagggaaagataggcataacgttggtatctaactggttaatgccacttgatgataatagcataccagatataaaggctgccgagagatcacttgacttccaatttggattgtttatggaacaattaacaacaggagattattctaagagcatgcggcgtatagttaaaaaccgattacctaagttctcaaaattcgaatcaagcctagtgaatggttcatttgattttattggtataaactattactcttctagttatattagcaatgccccttcacatggcaatgccaaacccagttactcaacaaatcctatgaccaatatttcatttgaaaaacatgggatacccttaggtccaagggctgcttcaatttggatatatgtttatccatatatgtttatccaagaggacttcgagatcttttgttacatattaaaaataaatataacaatcctgcaattttcaatcactgaaaatggtatgaatgaattcaacgatgcaacacttccagtagaagaagctcttttgaatacttacagaattgattactattaccgtcacttatactacattcgttctgcaatcagggctggctcaaatgtgaagggtttttacgcatggtcatttttggactgtaatgaatggtttgcaggctttactgttcgttttggattaaactttgtagattagaaagatggattaaaaaggtaccctaagctttctgcccaatggtacaagaactttctcaaaagaaactagctagtattattaaaagaactttgtagtagattacagtacatcgtttgaagttgagttggtgcacctaattaaataaaagaggttactcttaacatatttttaggccattcgttgtgaagttgttaggctgttatttctattatactatgttgtagtaataagtgcattgttgtaccagaagctatgatcataactataggttgatccttcatgtatcagtttgatgttgagaatactttgaattaaaagtctttttttatttttttaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
is($parser->get_sequence(),$seq,'Sequence correctly cleaned up');

$parser->next;
is($parser->get_id(), 'BRAF_HUMAN', 'ID from second record');

$accessions = $parser->get_accessions();
note(join ' ',@$accessions);
cmp_deeply($accessions,[qw(P15056 A4D1T4 B6HY61 B6HY62 B6HY63 B6HY64 B6HY65 B6HY66 Q13878 Q3MIN6 Q9UDP8 Q9Y6T3)],'Accessions from second multiline record');

$keywords = ['3D-structure', 'Acetylation', 'ATP-binding', 'Cardiomyopathy', 'Cell membrane', 'Chromosomal rearrangement', 'Complete proteome', 
                'Cytoplasm', 'Deafness', 'Direct protein sequencing', 'Disease mutation', 'Ectodermal dysplasia', 'Kinase', 'Membrane', 'Mental retardation', 
                'Metal-binding', 'Methylation', 'Nucleotide-binding', 'Nucleus', 'Phosphoprotein', 'Polymorphism', 'Proto-oncogene', 'Reference proteome', 
                'Serine/threonine-protein kinase', 'Transferase', 'Ubl conjugation', 'Zinc', 'Zinc-finger'];
is_deeply($parser->get_keywords,$keywords,'Keyword extraction, second record');
my $xrefs = $parser->get_database_cross_references;
is($xrefs->[0], 'EMBL:M95712', 'Xref from second record');
is($xrefs->[18], 'UniGene:Hs.550061', 'Xref from second record');
is($xrefs->[187], 'PROSITE:PS50081', 'Xref from second record');

ok(!$parser->next, 'Check end-of-file behaviour');
$parser->close;

done_testing;
