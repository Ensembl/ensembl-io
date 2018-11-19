#!/bin/env perl

# Sample GFF3 serializer using the new ensembl-io methodology.
#
# Recreates the current human GFF3 serializer used by production
# almost identically (a few extra attributes appear in this dump)
#
# Dumper chromosome 1 only for size/speed, takes about 20 minutes
#

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::IO::Translator::Feature;
use Bio::EnsEMBL::IO::Writer::GTF;
use Bio::EnsEMBL::IO::Object::GXFMetadata;
use Bio::EnsEMBL::IO::Object::GTF;

$|++;

my $dbhost = 'ensembldb.ensembl.org';
my $dbuser = 'anonymous';
my $dbpass;
my $dbport = 3306;
my $dbversion = Bio::EnsEMBL::ApiVersion->software_version;
my $outfile = '/tmp/test.gtf';

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

my $translator = Bio::EnsEMBL::IO::Translator::Feature->new();
my $serializer = Bio::EnsEMBL::IO::Writer::GTF->new($translator);

# Two ways to override the callback table
$translator->add_callbacks( { attributes => sub { $translator->gtf_attributes(@_) } } );

$serializer->open($outfile);

# Fetch chromosome 1
my $features = [$adaptor->fetch_by_region('chromosome', 1)];


###
#
#  Print the Ensembl GTF headers
#
###

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

    # Cycle through and print chromosomes, depends on DB ordering, not likely
    # good for production
    my $genes = $ga->fetch_all_by_Slice($chromosome);
    while(my $gene = shift @{$genes}) {
	my %seen_exons = ();
	$serializer->write($gene);
  
	# Serialize transcripts in start/end order for a gene
	foreach my $transcript (sort { $a->start() <=> $b->start() } @{$gene->get_all_Transcripts()}) {
	    # We're shifting logic about sub-objects and special attributes to be
	    # handled by the calling code
	    my $translation = $transcript->translation();
	    my $selenocysteines; my $has_selenocysteines;
	    
	    if($translation) {
		$selenocysteines = $translation->get_all_selenocysteine_SeqEdits();
		if(@{$selenocysteines}) {
		    $has_selenocysteines = 1;
		    $transcript->{extra_attrs}->{tag} = 'seleno';
		}
	    }

	    $serializer->write($transcript);

	    # Handle selenocysteine
	    if($translation && @{$selenocysteines}) {
		foreach my $edit (@{$selenocysteines}) {
		    my $edit_start = $edit->start();
		    my @projections = $transcript->pep2genomic($edit_start, $edit_start);
		    foreach my $projection (@projections) {
			# Make a GTF object to store the Selenocysteine record
			my $obj = Bio::EnsEMBL::IO::Object::GTF->new(Bio::EnsEMBL::IO::Object::GTF->fields());
			$obj->set_fields( {seqname => $transcript->seq_region_name(),
					      source  => $transcript->source,
					      type    => 'Selenocysteine',
					      start   => $projection->start(),
					      end     => $projection->end(),
					      score   => '.',
					      strand  => $transcript->strand(),
					      phase   => '.',
					      attributes => $translator->attributes($transcript),
					     } );
#			$obj->{extra_attrs} = $translator->attributes($transcript);
			$serializer->write($obj, $obj);
		    }
		}
	    }

	    # Collect the sub-transcript level features for serialization
	    my @exons_cds_and_utrs = @{$transcript->get_all_ExonTranscripts()};
	    push @exons_cds_and_utrs, @{$transcript->get_all_five_prime_UTRs()};
	    push @exons_cds_and_utrs, @{$transcript->get_all_three_prime_UTRs()};
	    push @exons_cds_and_utrs, @{$transcript->get_all_CDS()};

	    # Sort by start and end, and serialize
	    foreach my $feature (sort { $a->start() <=> $b->start() || $a->end() <=> $b->end() } @exons_cds_and_utrs) {
		$feature->{extra_attrs}->{tag} = 'seleno' if $has_selenocysteines;
		$serializer->write($feature);
	    }

	}

    }
}
