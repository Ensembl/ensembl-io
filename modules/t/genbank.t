use strict;
use warnings;

use Test::More;

use Bio::EnsEMBL::Utils::IO qw( work_with_file );
use Bio::EnsEMBL::IO::Parser::Genbank;
use FindBin;

my $test_file = $FindBin::Bin . '/input/data.gbk';

my $parser = Bio::EnsEMBL::IO::Parser::Genbank->open($test_file);
ok ($parser->next(), "Loading first record");
is($parser->get_accession,'NC_012920',"Testing get_accession");
is($parser->get_sequence_name,'NC_012920.1',"Testing get_sequence_name");
is($parser->get_sequence_version,'1',"Testing get_sequence_version");
is($parser->get_length,'16569',"Testing get_length");
is($parser->get_genbank_id,'251831106',"Testing get_genbank_id");
is($parser->get_organism,'Homo sapiens',"Testing get_organism");
is($parser->get_description,'Arabidopsis thaliana MADS-box protein FLOWERING LOCUS C mRNA, complete cds.',"Testing get_description with multiline definition");
is($parser->get_locus_id,'NC_012920',"Testing get_locus_id");
is($parser->get_sequence_type,'DNA',"Testing get_sequence_type");
is($parser->get_modification_date,'02-JAN-2014',"Testing get_modification_date");
is($parser->get_source,'mitochondrion Homo sapiens (human)',"Testing get_source");
is($parser->get_taxon_id,'9606',"Testing get_taxon_id");
is($parser->get_raw_dblinks,'BioProject: PRJNA30353',"Testing get_raw_dblinks");
ok($parser->is_circular, "Testing is_circular");
ok($parser->get_length == length($parser->get_sequence), "Testing length of the sequence");
is(scalar @{$parser->get_db_xref_list_for_type('GeneID')}, 74, "Testing get_db_xref_list_for_type GeneID");
is(scalar @{$parser->get_coded_by_list}, 0, "Testing get_coded_by_list");
is($parser->get_dbsource, undef, "Testing get_dbsource");
is($parser->get_dbsource_acc, undef, "Testing get_dbsource_acc");
is(scalar @{$parser->get_protein_id_list}, 13, "Testing get_protein_id_list");

my @features = @{ $parser->get_features };
cmp_ok(scalar @features,'==', 105, "Testing number of features");
my $feature = $features[2];
is($feature->{gene}->[0],'TRNF','Check correct gene extracted from feature block');
is_deeply($feature->{db_xref}, ['GeneID:4558','HGNC:7481','MIM:590070'], 'Xrefs extracted from feature are correct');

ok ($parser->next(), "Loading second record");
is($parser->get_accession,'NM_001100954',"Testing get_accession");
is($parser->get_sequence_name,'NM_001100954.1',"Testing get_sequence_name");
is($parser->get_sequence_version,'1',"Testing get_sequence_version");
is($parser->get_length,'558',"Testing get_length");
is($parser->get_organism,'Danio rerio',"Testing get_organism");
is($parser->get_description,'Danio rerio si:dkey-111e8.5 (si:dkey-111e8.5), mRNA.',"Testing get_description with multiline definition");
is($parser->get_locus_id,'NM_001100954',"Testing get_locus_id");
is($parser->get_sequence_type,'mRNA',"Testing get_sequence_type");
is($parser->get_modification_date,'06-AUG-2017',"Testing get_modification_date");
is($parser->get_source,'Danio rerio (zebrafish)',"Testing get_source");
is($parser->get_taxon_id,'7955',"Testing get_taxon_id");
cmp_ok($parser->is_circular, '==', 0, "Testing is_circular");
ok($parser->get_length == length($parser->get_sequence), "Testing length of the sequence");
is(scalar @{$parser->get_db_xref_list_for_type('GeneID')}, 2, "Testing get_db_xref_list_for_type GeneID");
is(scalar @{$parser->get_coded_by_list}, 0, "Testing get_coded_by_list");
is($parser->get_dbsource, undef, "Testing get_dbsource");
is($parser->get_dbsource_acc, undef, "Testing get_dbsource_acc");
is(scalar @{$parser->get_protein_id_list}, 1, "Testing get_protein_id_list");

@features = @{ $parser->get_features };
cmp_ok(scalar @features,'==', 3, "Testing number of features");
$feature = $features[2];
is($feature->{gene}->[0],'si:dkey-111e8.5','Check correct gene extracted from feature block');
is_deeply($feature->{db_xref}, ['GeneID:566993','ZFIN:ZDB-GENE-060526-192'], 'Xrefs extracted from feature are correct');

ok ($parser->close(), "Closing file");

done_testing();
