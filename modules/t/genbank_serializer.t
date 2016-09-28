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
use File::Slurp ;

BEGIN { use_ok 'Bio::EnsEMBL::IO::Translator::GenePlus'; }
BEGIN { use_ok 'Bio::EnsEMBL::IO::Object::Genbank'; }
BEGIN { use_ok 'Bio::EnsEMBL::IO::Writer::Genbank'; }

#make a test object to write out
my $gene ;
my $transcript ;

my @data_files = ("gene_plus_hash_0.dat", "gene_plus_hash_1.dat", "gene_plus_hash_2.dat") ;

#write the objects out
my $translator = Bio::EnsEMBL::IO::Translator::GenePlus->new();
my $serializer = Bio::EnsEMBL::IO::Writer::Genbank->new($translator);
my $testfile = $Bin.'tmp_test.genbank.dat' ;
$serializer->open( $testfile ) ;

foreach my $d (@data_files)
{
  # Read structure back in again
  my $input_file = $Bin."/input/".$d ;
  my %gene_plus_hash;
  {
    local $/=undef ;  # slurp mode
    open my $in, '<', $input_file  or die "input file $input_file not opened" ;
    my $object = <$in> ;
    close $in;
    %gene_plus_hash = %{ eval $object };
  }

  $serializer->write(\%gene_plus_hash);
}
$serializer->close() ;


#test the results


done_testing();