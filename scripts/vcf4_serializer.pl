#!/bin/env perl

# Sample VCF4 serializer using the new ensembl-io methodology.
#

use strict;
use warnings;
#use Data::Dumper;

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::IO::Translator::SampleGenotypeFeature;
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
my $vfa = Bio::EnsEMBL::Registry->get_adaptor( "human", "variation", "VariationFeature" );
#   $vfa->db->use_vcf(1);
my $dba = $adaptor->db();

my @info    = ('AA','MA','MAF','MAC','NS');
my @formats = ('GT');
my @samples_list = ('NA18594','NA18573','NA12875','NA12874','HG00096','HG00099','HG00103');

my $translator = Bio::EnsEMBL::IO::Translator::SampleGenotypeFeature->new(\@info,\@formats,\@samples_list);
my $serializer = Bio::EnsEMBL::IO::Writer::VCF4->new($translator);
$serializer->open('/tmp/test.vcf');


# Fetch in chromosome 1
my $slice = $adaptor->fetch_by_region('chromosome', 1,230710000,230711000);
# Smaller region
#my $slice = $adaptor->fetch_by_region('chromosome', 1,230710045,230710048);

my $features = $vfa->fetch_all_by_Slice($slice);

print STDOUT "Number of features found: ".scalar(@$features)."\n";

###
#
#  Print the VCF4 metadata/headers
#
###

$serializer->write(Bio::EnsEMBL::IO::Object::VCF4Metadata->directive('fileformat', 'VCFv4.2'));
foreach my $i (@info) {
  $serializer->write(Bio::EnsEMBL::IO::Object::VCF4Metadata->info($i));
}
foreach my $f (@formats) {
  $serializer->write(Bio::EnsEMBL::IO::Object::VCF4Metadata->format($f));
}
$serializer->write(Bio::EnsEMBL::IO::Object::VCF4Metadata->header(\@samples_list));

###
#
#  Cycle through and print the features
#
###

while(my $vf = shift @{$features}) {

  # Write the variant with its genotypes
  $serializer->write($vf);
}
