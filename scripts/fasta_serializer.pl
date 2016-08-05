#!/bin/env perl

$|=1;

use strict;
use warnings;
use Data::Dumper;

use Bio::EnsEMBL::Registry;
Bio::EnsEMBL::Registry->load_registry_from_db(
  -host       => 'ensembldb.ensembl.org',
  -user       => 'anonymous',
  -db_version => '85'
);

my $slice_adaptor = Bio::EnsEMBL::Registry->get_adaptor( "human", "core", "slice" );

use Bio::EnsEMBL::IO::Writer::Fasta;
my $writer     = Bio::EnsEMBL::IO::Writer::Fasta->new();

use Bio::EnsEMBL::IO::Translator::Slice;
my $translator = Bio::EnsEMBL::IO::Translator::Slice->new();

$writer->translator($translator);

# For writing to files:
# $writer->open('/tmp/test.fasta');
$writer->open(*STDOUT);

my $slice = $slice_adaptor->fetch_by_region( 'chromosome', '20', 1e6, 1e6 + 1000 );

$writer->write($slice);
