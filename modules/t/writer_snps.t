# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
# Copyright [2016-2018] EMBL-European Bioinformatics Institute
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

use strict;
use warnings;

use Test::More;

use Bio::EnsEMBL::IO::Writer;
  
my $writer = Bio::EnsEMBL::IO::Writer->new('Bed', 'output.bed');
ok($writer);

=pod
use Bio::EnsEMBL::Registry;

## Get some data from the db
my $registry = 'Bio::EnsEMBL::Registry';
$registry->load_registry_from_db(
                      -host => 'ensembldb.ensembl.org',
                      -user => 'anonymous',
                      );
                      
my $dba = $registry->get_DBAdaptor('human', 'core', 'no alias check');

SKIP: {
  skip 'No database adaptor can be found for human. Probably not live yet.', 1 unless $dba;
  my $slice_adaptor = $dba->get_SliceAdaptor();
  my $vf_adaptor  = $registry->get_adaptor('Human', 'Variation', 'VariationFeature');
  my $slice = $slice_adaptor->fetch_by_region('chromosome', '6', 133e6, 134e6);
  my $vfs = $vf_adaptor->fetch_all_by_Slice($slice);

  ok(scalar(@$vfs) > 0);

  ## Create dataset to pass to writer
  my $datasets = [{
                'metadata' => {'name' => 'Test 3', 'description' => 'Test of writing SNPs to a BED file'},
                'data'     => $vfs, 
              }];

  ## Create writer and write data to file
  $writer->output_file($datasets);
};
=cut
 
done_testing();
