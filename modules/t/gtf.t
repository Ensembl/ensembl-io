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

use Bio::EnsEMBL::IO::Parser::GTF;

#seq
#source
#feature
#start
#end
#score
#strand
#frame
#attributes

#1	ensembl	CDS	144373415	144373470	.	-	2	gene_id "ENSGALG00000016887"; gene_version "3"; transcript_id "ENSGALT00000027289"; transcript_version "3"; exon_number "21"; gene_source "ensembl"; gene_biotype "protein_coding"; transcript_source "ensembl"; transcript_biotype "protein_coding"; protein_id "ENSGALP00000027238"; protein_version "3";

my $test_file = "modules/t/input/data.gtf";
my $parser    = Bio::EnsEMBL::IO::Parser::GTF->open($test_file);

## First record
ok( $parser->next(), "Loading first record" );
my $expected_raw_attributes =
'gene_id "ENSGALG00000016887"; gene_version "3"; transcript_id "ENSGALT00000027289"; transcript_version "3"; exon_number "21"; gene_source "ensembl"; gene_biotype "protein_coding"; transcript_source "ensembl"; transcript_biotype "protein_coding"; protein_id "ENSGALP00000027238"; protein_version "3";';
my $expected_attributes = {
    gene_id            => 'ENSGALG00000016887',
    gene_version       => '3',
    transcript_id      => 'ENSGALT00000027289',
    transcript_version => '3',
    exon_number        => '21',
    gene_source        => 'ensembl',
    gene_biotype       => 'protein_coding',
    transcript_source  => 'ensembl',
    transcript_biotype => 'protein_coding',
    protein_id         => 'ENSGALP00000027238',
    protein_version    => '3',
};
is( $parser->get_seqname, '1',         'Testing get_seqname' );
is( $parser->get_type,    'CDS',       'Testing get_type' );
is( $parser->get_source,  'ensembl',   'Testing get_source' );
is( $parser->get_start,   '144373415', 'Testing get_start' );
is( $parser->get_end,     '144373470', 'Testing get_end' );
ok( !defined $parser->get_score, 'Testing get_score' );
is( $parser->get_strand,     '-1', 'Testing get_strand' );
is( $parser->get_raw_strand, '-',  'Testing get_raw_strand' );
is( $parser->get_phase,      '2',  "Testing get_phase" );
is( $parser->get_raw_attributes, $expected_raw_attributes,
    'Testing get_raw_attributes' );
is_deeply( $parser->get_attributes(),
    $expected_attributes, "Testing attributes" );
is( $parser->get_attribute_by_name('gene_id'),
    'ENSGALG00000016887', "Testing get attribute by name (gene_id)" );
is( $parser->get_attribute_by_name('exon_number'),
    '21', "Testing get attribute by name (exon_number)" );
is( $parser->get_attribute_by_name('transcript_source'),
    'ensembl', "Testing get attribute by name (transcript_source)" );

#25	ensembl	gene	1386032	1419314	.	-	.	gene_id "ENSGALG00000014638"; gene_version "4"; gene_name "ASH1L"; gene_source "ensembl"; gene_biotype "protein_coding";

## Second record
ok( $parser->next(), "Loading second record" );
$expected_raw_attributes =
'gene_id "ENSGALG00000014638"; gene_version "4"; gene_name "ASH1L"; gene_source "ensembl"; gene_biotype "protein_coding";';
$expected_attributes = {
    gene_id      => 'ENSGALG00000014638',
    gene_version => '4',
    gene_name    => 'ASH1L',
    gene_source  => 'ensembl',
    gene_biotype => 'protein_coding',
};
is( $parser->get_seqname, '25',         'Testing get_seqname' );
is( $parser->get_type,    'gene',       'Testing get_type' );
is( $parser->get_source,  'ensembl',   'Testing get_source' );
is( $parser->get_start,   '1386032', 'Testing get_start' );
is( $parser->get_end,     '1419314', 'Testing get_end' );
is( $parser->get_score, '7', 'Testing get_score' );
is( $parser->get_strand,     '1', 'Testing get_strand' );
is( $parser->get_raw_strand, '+',  'Testing get_raw_strand' );
ok( !defined $parser->get_phase,  "Testing get_phase" );
is( $parser->get_raw_attributes, $expected_raw_attributes,
    'Testing get_raw_attributes' );
is_deeply( $parser->get_attributes(),
    $expected_attributes, "Testing attributes" );
is( $parser->get_attribute_by_name('gene_id'),
    'ENSGALG00000014638', "Testing get attribute by name (gene_id)" );
is( $parser->get_attribute_by_name('gene_name'),
    'ASH1L', "Testing get attribute by name (gene_name)" );

ok( !$parser->next(), "No more records" );

done_testing();
