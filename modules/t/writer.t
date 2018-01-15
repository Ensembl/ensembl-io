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
use Bio::EnsEMBL::CoordSystem;
use Bio::EnsEMBL::Slice;
use Bio::EnsEMBL::Gene;
use Bio::EnsEMBL::Transcript;

## Create some sample objects (we don't want unit tests to depend on a db connection
my $cs = Bio::EnsEMBL::CoordSystem->new(-NAME    => 'chromosome',
                                        -VERSION => 'GRCh37',
                                        -RANK    => 1,
                                        ); 
my $slice =  Bio::EnsEMBL::Slice->new(-coord_system     => $cs,
                                      -seq_region_name  => '6',
                                      -start            => 133041408,
                                      -end              => 133091407,
                                      -strand           => 1,
                                      );

my @gene_data = (
                  ['ENSG00000093134', 133043926, 133055904, -1],
                  ['ENSG00000234484', 133073814, 133075090,  1],
                  ['ENSG00000112303', 133065009, 133084598, -1],
                );

my @features = ();
foreach (@gene_data) {
  push @features, Bio::EnsEMBL::Gene->new(
    -STABLE_ID  => $_->[0],
    -START      => $_->[1],
    -END        => $_->[2],
    -STRAND     => $_->[3],
    -SLICE      => $slice,
  );
}

ok(scalar(@features) > 0);

## Create dataset to pass to writer
my $datasets = [{
                'metadata' => {'name' => 'Test 1', 'description' => 'Test of writing genes and their transcripts to a BED file'},
                'data'     => \@features, 
              }];

## Create writer and write data to file
#my $writer = Bio::EnsEMBL::IO::Writer->new('Bed', 'output.bed');
#$writer->output_dataset($datasets);

done_testing();
