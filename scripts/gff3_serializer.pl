#!/bin/env perl

# Sample GFF3 serializer using the new ensembl-io methodology.
#
# Recreates the current human GFF3 serializer used by production
# almost identically (a few extra attributes appear in this dump)
#
# Dumper chromosome 1 only for size/speed, takes about 20 minutes
#

$|++;

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::IO::Translator::EnsFeature;
use Bio::EnsEMBL::IO::Writer::GFF3;
use Bio::EnsEMBL::IO::Object::GXFMetadata;

my $dbhost = 'ensembldb.ensembl.org';
my $dbuser = 'anonymous';
my $dbpass;
my $dbport = 3306;
my $dbversion = Bio::EnsEMBL::ApiVersion->software_version;
my $outfile = '/tmp/test.gff';

GetOptions(
    'dbuser|user=s'     => \$dbuser,
    'dbpass|pass=s'     => \$dbpass,
    'dbhost|host=s'     => \$dbhost,
    'dbport|port=i'     => \$dbport,
    'version|version=s' => \$dbversion,
    'outfile=s'         => \$outfile,
    );

# Connect to the Ensembl Registry to access the databases
Bio::EnsEMBL::Registry->load_registry_from_db(
    -host       => $dbhost,
    -user       => $dbuser,
    -pass       => $dbpass,
    -port       => $dbport,
    -db_version => $dbversion
    );

# Create your slice adaptor to search for chromosomes
my $adaptor = Bio::EnsEMBL::Registry->get_adaptor( "human", "core", "Slice" );
my $ga = Bio::EnsEMBL::Registry->get_adaptor( "human", "core", "Gene" );
my $dba = $adaptor->db();

my $translator = Bio::EnsEMBL::IO::Translator::EnsFeature->new();
my $serializer = Bio::EnsEMBL::IO::Writer::GFF3->new($translator);
$serializer->open($outfile);

# Fetch chromosome 1
my $features = [$adaptor->fetch_by_region('chromosome', 1)];


###
#
#  Print the GFF3 headers
#
###

$serializer->write(Bio::EnsEMBL::IO::Object::GXFMetadata->directive('gff-version', 3));
foreach my $chromosome (@{$features}) {
    $serializer->write( Bio::EnsEMBL::IO::Object::GXFMetadata->directive('sequence-region', 
									  $chromosome->seq_region_name,
									  $chromosome->start,
									  $chromosome->end) );
}
my $mc = $dba->get_MetaContainer();
my $gc = $dba->get_GenomeContainer();

# Get the build. name gives us GRCh37.p1 where as default gives us GRCh37
my $assembly_name = $gc->get_assembly_name();
my $providers = $mc->list_value_by_key('provider.name') || '';
my $provider = join(";", @$providers);
$serializer->write(Bio::EnsEMBL::IO::Object::GXFMetadata->ens_directive('genome-build', $provider, $assembly_name)) if $assembly_name;
 
# Get the build default
my $version = $gc->get_version();
$serializer->write(Bio::EnsEMBL::IO::Object::GXFMetadata->ens_directive('genome-version', $version)) if $version;
  
# Get the date of the genome build
my $assembly_date = $gc->get_assembly_date();
$serializer->write(Bio::EnsEMBL::IO::Object::GXFMetadata->ens_directive('genome-date', $assembly_date)) if $assembly_date;
  
# Get accession and only print if it is there
my $accession = $gc->get_accession();
if($accession) {
    my $accession_source = $mc->single_value_by_key('assembly.web_accession_source');
    my $string;
    $string .= "$accession_source:" if $accession_source;
    $string .= "$accession";
    $serializer->write(Bio::EnsEMBL::IO::Object::GXFMetadata->ens_directive('genome-build-accession', $string));
}
  
# Genebuild last updated
my $genebuild_last_date = $gc->get_genebuild_last_geneset_update();
$serializer->write(Bio::EnsEMBL::IO::Object::GXFMetadata->ens_directive('genebuild_last_date', $genebuild_last_date)) if $genebuild_last_date;

###
#
#  Cycle through and print the features
#
###

# Designed to go through multiple chromosomes if you take the
# chr1 restriction off the fetch_by_region()
while(my $chromosome = shift @{$features}) {

    # Write the chromosome
    $serializer->write($chromosome);

    # Write out the end of section separator for the GFF3 (ie. ###)
    $serializer->fwd_ref_delimeter();

    # Cycle through and print chromosomes, depends on DB ordering, not likely
    # good for production
    my $genes = $ga->fetch_all_by_Slice($chromosome);
    while(my $gene = shift @{$genes}) {
	my %seen_exons = ();
	$serializer->write($gene);
  
	# Serialize transcripts in start/end order for a gene
	foreach my $transcript (sort { $a->start() <=> $b->start() } @{$gene->get_all_Transcripts()}) {
	    $serializer->write($transcript);

	    # Collect the sub-transcript level features for serialization
	    my @exons_cds_and_utrs = @{$transcript->get_all_ExonTranscripts()};
	    push @exons_cds_and_utrs, @{$transcript->get_all_five_prime_UTRs()};
	    push @exons_cds_and_utrs, @{$transcript->get_all_three_prime_UTRs()};
	    push @exons_cds_and_utrs, @{$transcript->get_all_CDS()};

	    # Sort by start and end, and serialize
	    foreach my $feature (sort { $a->start() <=> $b->start() || $a->end() <=> $b->end() } @exons_cds_and_utrs) {
		$serializer->write($feature);
	    }

	}

	# Write out the end of section separator for the GFF3 (ie. ###)
	$serializer->fwd_ref_delimeter();

    }
}
