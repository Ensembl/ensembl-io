use strict;
use warnings;

use Test::More;

use Bio::EnsEMBL::Utils::IO qw( work_with_file );
use Bio::EnsEMBL::IO::Parser::Genbank;

my $test_file = 'modules/t/input/data.gbk';

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

my @features = @{ $parser->get_features };
cmp_ok(scalar @features,'==', 105, "Testing number of features");
my $feature = $features[2];
is($feature->{gene}->[0],'TRNF','Check correct gene extracted from feature block');
is_deeply($feature->{db_xref}, ['GeneID:4558','HGNC:7481','MIM:590070'], 'Xrefs extracted from feature are correct');


ok ($parser->close(), "Closing file");

done_testing();
