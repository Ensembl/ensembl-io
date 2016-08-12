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

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::IO::Translator::EnsFeature;
use Bio::EnsEMBL::IO::Writer::GFF3;

# Connect to the Ensembl Registry to access the databases
Bio::EnsEMBL::Registry->load_registry_from_db(
    -host => 'ensembldb.ensembl.org',
    -user => 'anonymous',
    -db_version => '84'
    );

# Create your slice adaptor to search for chromosomes
my $adaptor = Bio::EnsEMBL::Registry->get_adaptor( "human", "core", "Slice" );
my $ga = Bio::EnsEMBL::Registry->get_adaptor( "human", "core", "Gene" );

my $translator = Bio::EnsEMBL::IO::Translator::EnsFeature->new();
my $serializer = Bio::EnsEMBL::IO::Writer::GFF3->new($translator);
$serializer->open('/tmp/test.gff');

# Fetch chromosome 1
my $features = [$adaptor->fetch_by_region('chromosome', 1)];

###
#
#  Missing: GFF3 headers print, coming soon, not yet in GFF3 serializer!
#
###

# Designed to go through multiple chromosomes if you take the
# chr1 restriction off the fetch_by_region()
while(my $chromosome = shift @{$features}) {

    # Write the chromosome
    $serializer->write($chromosome);

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

###
#
# Missing: GFF3 end of section separators, not yet in GFF3 serializer,
#          coming soon!
#
###

    }
}
