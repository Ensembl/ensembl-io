#!/bin/env perl

# Copyright [2020] EMBL-European Bioinformatics Institute
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



# Sample VCF4 serializer using the new ensembl-io methodology.
#

use strict;
use warnings;
#use Data::Dumper;

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::IO::Translator::StructuralVariationFeature;
use Bio::EnsEMBL::IO::Writer::VCF4;
use Bio::EnsEMBL::IO::Object::VCF4Metadata;

$|++;

my $db_version = Bio::EnsEMBL::ApiVersion->software_version;

# Connect to the Ensembl Registry to access the databases
Bio::EnsEMBL::Registry->load_registry_from_db(
    -host => 'ensembldb.ensembl.org',
    -user => 'anonymous',
    -db_version => $db_version
);

# Create your slice adaptor to search for chromosomes
my $adaptor = Bio::EnsEMBL::Registry->get_adaptor( "human", "core", "Slice" );
my $svfa = Bio::EnsEMBL::Registry->get_adaptor( "human", "variation", "StructuralVariationFeature" );
#   $vfa->db->use_vcf(1);
my $dba = $adaptor->db();

my @info = ('SVTYPE','END','Parent','SVLEN','CIPOS','CIEND','IMPRECISE');

my @alt  = ('CNV','CNV:GAIN','CNV:LOSS',
            'DEL',
            'DUP','DUP:TANDEM',
            'INS','INS:ME','INS:ME:ALU',
            'INV',
            'SA','CSA','CS','INDEL',
            'TL','TL:Inter','TL:Intra',
            'BP:InterC','BP:IntraC'
           );

my $translator = Bio::EnsEMBL::IO::Translator::StructuralVariationFeature->new(\@info);
my $serializer = Bio::EnsEMBL::IO::Writer::VCF4->new($translator);
$serializer->open('/tmp/test_sv.vcf');


# Fetch in chromosome 1
my $chr   = 1;
my $start = 27000; #230710000
my $end   = 177500; #230711000
#my $slice = $adaptor->fetch_by_region('chromosome', 1,230710000,230711000);
my $slice = $adaptor->fetch_by_region('chromosome', $chr, $start, $end);

# Include the supporting evidence
my $features = $svfa->fetch_all_by_Slice($slice,1);

print STDOUT "Number of features found: ".scalar(@$features)."\n";

###
#
#  Print the VCF4 metadata/headers
#
###

# File format
$serializer->write(Bio::EnsEMBL::IO::Object::VCF4Metadata->directive('fileformat', 'VCFv4.2'));
# INFO
foreach my $i (@info) {
  $serializer->write(Bio::EnsEMBL::IO::Object::VCF4Metadata->info($i));
}
# ALT
foreach my $i (@alt) {
  $serializer->write(Bio::EnsEMBL::IO::Object::VCF4Metadata->alt($i));
}
# HEADER
$serializer->write(Bio::EnsEMBL::IO::Object::VCF4Metadata->header());


###
#
#  Cycle through and print the features
#
###

while(my $svf = shift @{$features}) {
  # Write the variant with its genotypes
  $serializer->write($svf);
}

