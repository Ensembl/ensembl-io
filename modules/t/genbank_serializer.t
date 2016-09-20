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

BEGIN { use_ok 'Bio::EnsEMBL::IO::Translator::GenePlus'; }
BEGIN { use_ok 'Bio::EnsEMBL::IO::Object::Genbank'; }
BEGIN { use_ok 'Bio::EnsEMBL::IO::Writer::Genbank'; }

#make a test object to write out
my $gene ;
my $transcript ;

my %gene_plus_hash ;
$gene_plus_hash{'gene'} = $gene ;
$gene_plus_hash{'transcript'} = $transcript ;


#write it out
my $translator = Bio::EnsEMBL::IO::Translator::GenePlus->new();
my $serializer = Bio::EnsEMBL::IO::Writer::Genbank->new($translator);
my $testfile = $Bin.'tmp_test.genbank.dat' ;
$serializer->open( $testfile );
$serializer->write(\%gene_plus_hash);


#test the results


done_testing();