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
use Bio::EnsEMBL::IO::Translator::GenePlus;
use Bio::EnsEMBL::IO::Writer::Genbank;
use Data::Dumper;

# Connect to the Ensembl Registry to access the databases
Bio::EnsEMBL::Registry->load_registry_from_db(
    -host => 'ensembldb.ensembl.org',
    -user => 'anonymous',
    -db_version => '85'
    );

# Create your slice adaptor to search for chromosomes
my $adaptor = Bio::EnsEMBL::Registry->get_adaptor( "bushbaby", "core", "Slice" );
my $ga = Bio::EnsEMBL::Registry->get_adaptor( "bushbaby", "core", "Gene" );

my $translator = Bio::EnsEMBL::IO::Translator::GenePlus->new();
my $serializer = Bio::EnsEMBL::IO::Writer::Genbank->new($translator);
$serializer->open('/tmp/test.genbank.dat');
print("Opened output file\n") ;

$Data::Dumper::Purity = 1;
my $dump_objects_required = 3 ;
my $dump_objects_count = 0 ;

# Fetch chromosome 1
my $features = [$adaptor->fetch_by_region('scaffold', 'GL873520.1')];
print("Features fetched\n") ;


# Designed to go through multiple chromosomes if you take the
# chr1 restriction off the fetch_by_region()
while(my $chromosome = shift @{$features})
{
    #TODO: Header for this section


    # Cycle through and print chromosomes, depends on DB ordering, not likely
    # good for production
    my $genes = $ga->fetch_all_by_Slice($chromosome);
    while(my $gene = shift @{$genes})
    {
      my $transcript = $gene->canonical_transcript ;
      my %gene_plus_hash ;
      $gene_plus_hash{'gene'} = $gene ;
      $gene_plus_hash{'transcript'} = $transcript ;
      $serializer->write(\%gene_plus_hash);

      #Allow dumping of objects, which can then be read in by
      if( $dump_objects_count < $dump_objects_required )
      {
        my $dump_file_name = "gene_plus_hash_".$dump_objects_count.".dat" ;
        open(my $DUMP_FILE, ">", $dump_file_name ) ;
        print $DUMP_FILE Dumper(\%gene_plus_hash);
        close($DUMP_FILE) ;
        $dump_objects_count++ ;
      }
    }


    #TODO: Footer for this section



}

print("Completed, closing file\n") ;
$serializer->close() ;
