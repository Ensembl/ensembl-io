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

use Bio::EnsEMBL::IO::Parser::VEP_output;

my $test_file = "modules/t/input/data.vepo";

my $parser = Bio::EnsEMBL::IO::Parser::VEP_output->open($test_file);
ok ($parser->next(), "Loading first record");
ok ($parser->get_uploaded_variation() eq '11_224088_C/A');
ok ($parser->get_seqname() eq '11');
ok ($parser->get_start() == 224088);
ok ($parser->get_end() == 224088);
ok ($parser->get_allele() eq 'A');
ok ($parser->get_gene() eq 'ENSG00000142082');
ok ($parser->get_feature() eq 'ENST00000525319');
ok ($parser->get_feature_type() eq 'Transcript');
ok ($parser->get_consequence() eq 'missense_variant');
ok ($parser->get_cdna_position() == 742);
ok ($parser->get_cds_position() == 716);
ok ($parser->get_protein_position() == 239);
ok ($parser->get_amino_acids() eq 'T/N');
ok ($parser->get_codons() eq 'aCc/aAc');
ok ($parser->get_existing_variation() eq '-');
my $extra = $parser->get_extra;
ok ($extra->{'SIFT'} eq 'deleterious(0)');
ok ($parser->next(), "Loading second record");
ok ($parser->close(), "Closing file");

done_testing();
