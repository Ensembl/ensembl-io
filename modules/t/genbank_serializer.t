=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

use strict;
use warnings;

use Test::More;
use Test::Differences;
use FindBin qw( $Bin );
use File::Temp qw/ tempfile tempdir /;
use Bio::EnsEMBL::Registry;

BEGIN { use_ok 'Bio::EnsEMBL::IO::Translator::GenePlus'; }
BEGIN { use_ok 'Bio::EnsEMBL::IO::Object::Genbank'; }
BEGIN { use_ok 'Bio::EnsEMBL::IO::Writer::Genbank'; }

# Connect to the Ensembl Registry to access the database
Bio::EnsEMBL::Registry->load_registry_from_db(
    -host => 'ensembldb.ensembl.org',
    -user => 'anonymous',
    -db_version => '85'
    );

# Create your slice adaptor to search for chromosomes
#
# Currently this was setup to be bushbaby to match what was done before, but these will be
# updated in the future to use a specific human release. Cases required to be tested are listed
# below.
my $adaptor = Bio::EnsEMBL::Registry->get_adaptor( "bushbaby", "core", "Slice" );
my $ga = Bio::EnsEMBL::Registry->get_adaptor( "bushbaby", "core", "Gene" );

#make a test object to write out
my $gene ;
my $transcript ;

#setup objects
my $translator = Bio::EnsEMBL::IO::Translator::GenePlus->new();
my $serializer = Bio::EnsEMBL::IO::Writer::Genbank->new($translator);

#setup output file
my $dir = File::Temp->newdir();
my $testfile = $dir."/test.genbank" ;
$testfile = $Bin."/test.genbank" ;
printf("testfile opened at $testfile\n") ;
$serializer->open( $testfile ) ;

my $num_written_objects = 0 ;
my $num_required_objects = 3 ;

my $features = [$adaptor->fetch_by_region('scaffold', 'GL873520.1')];
my $chromosome = shift @{$features} ;
my $genes = $ga->fetch_all_by_Slice($chromosome);

while( my $gene = shift @{$genes} )
{
  $num_written_objects++ ;
  printf( "Writing object $num_written_objects \n" ) ;
  my $transcript = $gene->canonical_transcript ;
  my %gene_plus_hash ;
  $gene_plus_hash{'gene'} = $gene ;
  $gene_plus_hash{'transcript'} = $transcript ;
  $serializer->write(\%gene_plus_hash);
  if( $num_written_objects > $num_required_objects )
  {
    goto WRITING_DONE ;
  }
}


WRITING_DONE:
$serializer->close() ;

# Cases we want to test are
# 1. gene with canonical transcript forward strand
# 2. gene with canonical transcript reverse strand
# 3. gene with no translation
# 4. gene with no translation, reverse strand
#
# And amongst these we want a single/multiple exon, single/multiple db xrefs
#  protein ids, check that transcript ids match up for 1,2 in the gene and CDS fields
#
# Plus file and per section header tests will be wanted down the line so we will need to dump for multiple regions
#
# As these will be determined more precisely in the future for now the test will use a high level file comparison.
my $acceptance_file = "acceptance/genbank_serializer.acceptance.dat" ;
open TEST_FILE, $testfile ;
open ACCEPTANCE_FILE, $acceptance_file ;

my $line = 0 ;
while( my $expected=<ACCEPTANCE_FILE> )
{
  $line++ ;
  my $got = <TEST_FILE> ;
  cmp_ok($got, 'eq', $expected, "File compare line ".$line ) ;
}

done_testing();
