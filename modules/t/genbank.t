# See the NOTICE file distributed with this work for additional information
# regarding copyright ownership.
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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

@features = @{ $parser->get_features };
cmp_ok(scalar @features,'==', 3, "Testing number of features");
$feature = $features[2];
is($feature->{gene}->[0],'si:dkey-111e8.5','Check correct gene extracted from feature block');
is_deeply($feature->{db_xref}, ['GeneID:566993','ZFIN:ZDB-GENE-060526-192'], 'Xrefs extracted from feature are correct');

ok ($parser->next(), "Loading third record");
is($parser->get_accession,'NC_011032',"Testing get_accession");
is($parser->get_sequence_name,'NC_011032.1',"Testing get_sequence_name");
is($parser->get_sequence_version,'1',"Testing get_sequence_version");
is($parser->get_length,'135199',"Testing get_length");
is($parser->get_organism,'Brachypodium distachyon',"Testing get_organism");
is($parser->get_description,'Brachypodium distachyon chloroplast, complete genome.',"Testing get_description with multiline definition");
is($parser->get_locus_id,'NC_011032',"Testing get_locus_id");
is($parser->get_sequence_type,'DNA',"Testing get_sequence_type");
is($parser->get_modification_date,'26-MAR-2010',"Testing get_modification_date");
is($parser->get_source,'chloroplast Brachypodium distachyon (stiff brome)',"Testing get_source");
is($parser->get_taxon_id,'15368',"Testing get_taxon_id");
cmp_ok($parser->is_circular, '==', 1, "Testing is_circular");
ok($parser->get_length == length($parser->get_sequence), "Testing length of the sequence");

@features = @{ $parser->get_features };
cmp_ok(scalar @features,'==', 294, "Testing number of features");
$feature = $features[1];
is($feature->{gene}->[0],'rps12','Check correct gene extracted from feature block');
is($feature->{trans_splicing}->[0],'1','Check valueless feature trans_splicing extracted from feature block');
is_deeply($feature->{db_xref}, ['GeneID:6439811'], 'Xrefs extracted from feature are correct');

ok ($parser->close(), "Closing file");

done_testing();
