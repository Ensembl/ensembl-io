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
use Bio::EnsEMBL::IO::Parser::GVF;

my $test_file = "modules/t/input/data.gvf";

my $parser = Bio::EnsEMBL::IO::Parser::GVF->open($test_file);

print "\n# First record:\n";
ok ($parser->next(), "Loading first record");
my @test_row = (qw(Y	dbSNP	SNV	10015	10015	.	+	.	ID=1;Variant_seq=C;Dbxref=dbSNP_137:rs113469508;evidence_values=Frequency;Reference_seq=A));
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");

print "\n# Test the getters (only for the first row):\n";
ok($parser->get_seqname eq 'Y', 'get_seqname');
ok($parser->get_start == 10015, 'get_start');
ok($parser->get_end == 10015, 'get_end');
ok($parser->get_strand == 1, 'get_strand');
ok($parser->get_source eq 'dbSNP', 'get_source');
ok($parser->get_type eq 'SNV', 'get_type');
ok(!defined($parser->get_score), 'get_score');
ok(!defined($parser->get_phase), 'get_phase');
ok(join(',',sort(keys(%{$parser->get_attributes}))) eq 'Dbxref,ID,Reference_seq,Variant_seq,evidence_values', 'get_attributes');
ok($parser->get_ID eq '1', 'get_ID');
ok($parser->get_variant_seq eq 'C', 'get_variant_seq');
ok($parser->get_reference_seq eq 'A', 'get_reference_seq');

print "\n# Second record:\n";
ok ($parser->next(), "Loading second record");
@test_row = (qw(Y	dbSNP	insertion	10035	10036	.	+	.	ID=2;Variant_seq=CC;Dbxref=dbSNP_137:rs201278642;Reference_seq=-;global_minor_allele_frequency=0|0.0535714|117));
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
ok($parser->get_variant_seq eq 'CC', 'get_variant_seq');

print "\n# Methods to retrieve metadata:\n";
ok($parser->get_metadata_key_list eq 'data-source, feature-ontology, file-date, file-version, genome-build, gff-version, gvf-version, sequence-region, species', 'get_metadata_key_list');
ok($parser->get_gvf_version eq '1.06', 'get_gvf_version');
ok($parser->get_genome_build eq 'ensembl GRCh37', 'get_genome_build');
ok($parser->get_sequence_region_list->[0] eq 'Y 1 59373566', 'get_sequence_region_list');
ok($parser->get_metadata_by_pragma('file-version') eq '73', 'get_metadata_by_pragma');

print "\n";

ok ($parser->close(), "Closing file");

done_testing();
