# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
# Copyright [2016-2018] EMBL-European Bioinformatics Institute
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

use Bio::EnsEMBL::IO::Parser::GFF3;

my $test_file = "modules/t/input/data.gff3";
my $test_with_fasta_file = "modules/t/input/data_with_fasta.gff3";

my $parser = Bio::EnsEMBL::IO::Parser::GFF3->open($test_file);
## First record
ok ($parser->next(), "Loading first record");
ok ($parser->get_seqname eq 'NC_000001.11', 'Testing get_seqname');
ok ($parser->get_type eq 'region', 'Testing get_type');
ok ($parser->get_source eq 'RefSeq', 'Testing get_source');
ok ($parser->get_start eq '1', 'Testing get_start');
ok ($parser->get_end eq '248956422', 'Testing get_end');
ok ($parser->get_raw_phase eq '.', 'Testing get_raw_phase');
ok (!defined $parser->get_score, 'Testing get_score');
ok ($parser->get_strand eq '1', 'Testing get_strand');
ok ($parser->get_raw_phase eq '.', 'Testing get_raw_phase');
ok (!defined $parser->get_phase, 'Testing get_phase');
my %attributes = (ID => 'id0', Dbxref => 'taxon:9606', Name => '1', chromosome => '1', gbkey => 'Src', genome => 'chromosome', mol_type => 'genomic DNA');
is_deeply ($parser->get_attributes, \%attributes, 'Testing get_attributes');
## second record
ok ($parser->next(), "Loading second record");
ok (exists $parser->get_attributes->{'pseudo'}, 'Testing get_attribute_by_name');
ok ($parser->get_attributes->{'pseudo'} eq 'true', 'Testing get_attribute_by_name');
ok ($parser->get_attribute_by_name('Name') eq 'DDX11L1', 'Testing get_attribute_by_name');
ok ($parser->next(), "Loading next record");
ok ($parser->get_raw_attributes eq 'ID=rna0;Parent=gene0;Dbxref=GeneID:100287102,Genbank:NR_046018.2,HGNC:HGNC:37102;Name=NR_046018.2;gbkey=misc_RNA;gene=DDX11L1;product=DEAD/H (Asp-Glu-Ala-Asp/His) box helicase 11 like 1;transcript_id=NR_046018.2', 'Testing get_raw_attributes');
for (1..4) {
    $parser->next;
}
ok (!exists $parser->get_attributes->{'pseudo'}, 'Testing get_attribute_by_name');
ok ($parser->get_raw_attributes eq 'ID=gene4;Dbxref=GeneID:645520,HGNC:HGNC:32334;Name=FAM138A;description=family with sequence similarity 138%2C member A;gbkey=Gene;gene=FAM138A;gene_synonym=F379,FAM138F', 'Testing get_raw_attributes');
ok ($parser->get_attribute_by_name('description') eq 'family with sequence similarity 138, member A', 'Testing decode_string in get_attribute_by_name');
for (1..8) {
    $parser->next;
}
ok ($parser->get_raw_phase eq '0', 'Testing get_raw_phase');
ok ($parser->get_phase eq 0, 'Testing get_phase');
ok ($parser->close(), "Closing file");

# Testing reading a GFF3 with embedded Fasta
ok($parser = Bio::EnsEMBL::IO::Parser::GFF3->open($test_with_fasta_file), 'Open GFF3 with embedded Fasta');
ok($parser->next(), "Loading first record");
ok($parser->next(), "Loading second record");
ok($parser->next(), "Loading third record");
ok(!$parser->next(), "Should return empty, end of records");
ok($parser->in_fasta_mode(), "We should be in Fasta mode");
ok($parser->next_sequence(), "Read the first Fasta sequence");
ok($parser->getHeader() eq 'HSBGPG Human gene for bone gla protein (BGP)', "Checking fasta header");
ok($parser->next_sequence(), "Test jumping to the next record without reading the sequence");
ok(length($parser->getSequence()) == 1020, "Checking the sequence is the correct length");
ok(!$parser->next_sequence(), "Should return empty, end of sequences");

done_testing();
