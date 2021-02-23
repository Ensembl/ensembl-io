# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
# Copyright [2016-2021] EMBL-European Bioinformatics Institute
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
use Test::Differences;

use Bio::EnsEMBL::CoordSystem;
use Bio::EnsEMBL::Slice;
use Bio::EnsEMBL::Gene;
use Bio::EnsEMBL::Transcript;
use IO::String;

use Bio::EnsEMBL::IO::Translator::Gene;
use Bio::EnsEMBL::IO::Writer::GTF;
use Bio::EnsEMBL::IO::Object::GXFMetadata;

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
    -SLICE      => $slice);
}

my $gtf_string = <<GTF;
##gtf-file yes
#!genome-build ensembl GRCh37
6	ensembl	gene	266085333	266097311	.	-	.	gene_biotype "protein_coding"; gene_id "ENSG00000093134"; gene_source "ensembl"; gene_version "1"
6	ensembl	gene	266115221	266116497	.	+	.	gene_biotype "protein_coding"; gene_id "ENSG00000234484"; gene_source "ensembl"; gene_version "1"
6	ensembl	gene	266106416	266126005	.	-	.	gene_biotype "protein_coding"; gene_id "ENSG00000112303"; gene_source "ensembl"; gene_version "1"
GTF

# Create a string file handle to write to
my $fh = IO::String->new();

my $translator = Bio::EnsEMBL::IO::Translator::Gene->new();
my $serializer = Bio::EnsEMBL::IO::Writer::GTF->new($translator);

# The default 'type' callback uses a so adaptor, this is obviously
# bad for testing, override it to something simpler
$translator->add_callbacks( { type => sub { my $object = shift; return $object->biotype(); } } );
$serializer->open($fh);

# Write headers
$serializer->write(Bio::EnsEMBL::IO::Object::GXFMetadata->directive('gtf-file', 'yes'));
$serializer->write(Bio::EnsEMBL::IO::Object::GXFMetadata->ens_directive('genome-build', 'ensembl', 'GRCh37'));

foreach my $feature (@features) {
    $serializer->write($feature);
}

eq_or_diff(${$fh->string_ref()}, $gtf_string, "Checking is serializer matches expected GTF");

done_testing();
