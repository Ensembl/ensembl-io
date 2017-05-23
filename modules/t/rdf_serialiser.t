# Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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

use IO::String;

use Bio::EnsEMBL::IO::Translator::Slice;
use Bio::EnsEMBL::IO::Translator::BulkFetcherFeature;
use Bio::EnsEMBL::IO::Writer::RDF;
use Bio::EnsEMBL::IO::Object::RDF;

# create some slices and features as a subset of a BulkFetcher dump
my @slices;
my @features;

# create target feature/xref RDF strings
my ($fh, $xrefs_fh);

# translators for slices and (bulk fetcher derived) features
my $slice_trans = Bio::EnsEMBL::IO::Translator::Slice->new(version => $version,
							   production_name => $prod_name,
							   meta_adaptor => $meta_adaptor);
my $feature_trans = Bio::EnsEMBL::IO::Translator::BulkFetcherFeature->new(version => $version,
									  production_name => $prod_name,
									  xref_mapping_file => $config_file,
									  ontology_adaptor => $meta_adaptor);

my $feature_writer = Bio::EnsEMBL::IO::Writer::RDF->new(); # do not pass translator, pass it when writing since we need the slice and feature translators
my $xrefs_writer = Bio::EnsEMBL::IO::Writer::RDFXRefs->new($feature_trans);

# open string FH for features and xrefs files
$feature_writer->open($fh);
$xrefs_writer->open($xrefs_fh);

# write namespaces (both main and xrefs), take default prefixes from Bio::EnsEMBL::Utils::RDF
my $namespaces = Bio::EnsEMBL::IO::Object::RDF->namespaces();
$feature_writer->write($namespaces);
$xrefs_writer->write($namespaces);

# write species info
my ($taxon_id, $scientific_name, $common_name);
$feature_writer->write(Bio::EnsEMBL::IO::Object::RDF->species(taxon_id => $taxon_id,
							      scientific_name => $scientific_name,
							      common_name => $common_name);

map { $feature_writer->write($_, $slice_trans) } @slices;
map { $feature_writer->write($_, $feature_trans) } @features;
map { $xrefs_writer->write($_) } @features;

done_testing();
