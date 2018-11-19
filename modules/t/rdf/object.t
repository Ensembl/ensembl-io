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
use Test::Differences;
use Test::Exception;

use IO::String;

use_ok 'Bio::EnsEMBL::IO::Object::RDF';

my %prefix = (
	      blastprodom => "http://purl.uniprot.org/prodom/",
	      dataset     => 'http://rdf.ebi.ac.uk/dataset/ensembl/',
	      dc          => 'http://purl.org/dc/elements/1.1/');

my $namespaces = Bio::EnsEMBL::IO::Object::RDF->namespaces(%prefix);
isa_ok($namespaces, 'Bio::EnsEMBL::IO::Object::RDF');

my $namespaces_record =
  "\@prefix blastprodom: <http://purl.uniprot.org/prodom/> .\n" .
  "\@prefix dataset: <http://rdf.ebi.ac.uk/dataset/ensembl/> .\n" .
  "\@prefix dc: <http://purl.org/dc/elements/1.1/> .";
eq_or_diff($namespaces->create_record(), $namespaces_record, "Namespaces record match");

throws_ok { Bio::EnsEMBL::IO::Object::RDF->species() } qr/Undefined species/, "Throws with no arguments";
my $species = Bio::EnsEMBL::IO::Object::RDF->species(taxon_id => 9606,
						     scientific_name => 'Homo sapiens',
						     common_name => 'Human');

my $species_record =
  "taxon:9606 rdfs:subClassOf obo:OBI_0100026 .\n" .
  "taxon:9606 skos:prefLabel \"Homo sapiens\" .\n" .
  "taxon:9606 skos:altLabel \"Human\" .\n" .
  "taxon:9606 dc:identifier \"9606\" .";
eq_or_diff($species->create_record(), $species_record, "Species record match");

throws_ok { Bio::EnsEMBL::IO::Object::RDF->dataset(version => 89, production_name => 'homo_sapiens') }
  qr/Undefined/, "Throws with missing arguments";
my $dataset = Bio::EnsEMBL::IO::Object::RDF->dataset(version => 89,
						     project => 'ensembl',
						     production_name => 'homo_sapiens');

my $dataset_record =
  "<http://rdf.ebi.ac.uk/dataset/ensembl/89/homo_sapiens> <http://rdfs.org/ns/void#subset> <http://rdf.ebi.ac.uk/dataset/ensembl/89> .";
eq_or_diff($dataset->create_record(), $dataset_record, "Dataset record match");

done_testing();
