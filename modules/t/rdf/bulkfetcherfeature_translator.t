# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
# Copyright [2016-2019] EMBL-European Bioinformatics Institute
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

use FindBin qw/$Bin/;
use Test::More;
use Test::Deep;
use Test::Differences;
use Test::Exception;
use JSON;

use Bio::EnsEMBL::Test::MultiTestDB;

use_ok 'Bio::EnsEMBL::IO::Translator::BulkFetcherFeature';

my $multi = Bio::EnsEMBL::Test::MultiTestDB->new(undef, "$Bin/..");
my $adaptor = $multi->get_DBAdaptor('core');
my $meta_adaptor = $adaptor->get_MetaContainer();
my ($version, $production_name) =
  (
   $meta_adaptor->list_value_by_key('schema_version')->[0],
   $meta_adaptor->list_value_by_key('species.production_name')->[0]
  );

my $translator = Bio::EnsEMBL::IO::Translator::BulkFetcherFeature->new(
    version           => $version,
    xref_mapping_file => "$Bin/xref_LOD_mapping.json",
    adaptor           => $adaptor
);

ok($translator->version == $version, 'version');
ok($translator->production_name eq $production_name, 'production name');

# read in a sample gene structure fetched by the bulk fetcher
my $gene = from_json(slurp_file("$Bin/gene.json"));

#
# test various accessors
#
# compare gene
#
my %gene_attrs = (
   type => 'gene',
   id   => 'ENSG00000127720',
   name => 'METTL25',
   description => 'methyltransferase like 25 [Source:HGNC Symbol;Acc:HGNC:26228]',
   seq_region_name => 12,
   coord_system_name => 'chromosome',
   coord_system_version => 'GRCh38',
   start => 82358497,
   end   => 82479236,
   strand => 1,
   biotype => 'protein_coding',
   taxon_id => 9606,
   provenance => 'ANNOTATED',
   so_term => 'SO:0001217'
);

foreach my $attr (keys %gene_attrs) {
  is($translator->$attr($gene), $gene_attrs{$attr}, "gene $attr");
}

cmp_deeply($translator->synonyms($gene), [ 'C12orf26', 'FLJ22789' ], 'gene synonyms');
cmp_deeply(
    $translator->xrefs($gene)->[5],
     {display_id => 'METTL25',
       primary_id => 84190,
       info_type  => 'DEPENDENT',
       info_text  => '',
       description => 'methyltransferase like 25',
       dbname     => 'WikiGene' }, 'gene xref');
cmp_deeply($translator->homologues($gene)->[1],
     { stable_id => 'ENSGGOG00000023239',
       genome => 'gorilla_gorilla',
       description => 'ortholog_one2one' }, 'homolog');
is($translator->uri($gene), "http://rdf.ebi.ac.uk/resource/ensembl/ENSG00000127720", 'gene URI');

# compare transcript
my $transcripts = $translator->transcripts($gene);
is(scalar @{$transcripts}, 11, 'number of transcripts');
my $transcript = $transcripts->[0];
my %transcript_attrs = (
   id => 'ENST00000248306',
   type => 'transcript',
   name => 'METTL25-201',
   description => undef,
   seq_region_name => 12,
   coord_system_name => 'chromosome',
   coord_system_version => 'GRCh38',
   start => 82358497,
   end   => 82479236,
   strand => 1,
   biotype => 'protein_coding',
   taxon_id => 9606,
   provenance => 'INFERRED_FROM_TRANSCRIPT',
   so_term => 'SO:0000234'
);

foreach my $attr (keys %transcript_attrs) {
  is($translator->$attr($transcript), $transcript_attrs{$attr}, "transcript $attr");
}

cmp_deeply($translator->synonyms($transcript), [], 'transcript synonyms');
is(scalar @{$translator->xrefs($transcript)}, 19, 'number of transcript xrefs');
cmp_deeply($translator->xrefs($transcript)->[13],
     {
      'display_id' => 'NM_001319675.1',
      'primary_id' => 'NM_001319675',
      'info_type' => 'DIRECT',
      'info_text' => 'Generated via otherfeatures',
      'description' => '',
      'dbname' => 'RefSeq_mRNA'
     }, 'transcript xref');
is($translator->uri($transcript), "http://rdf.ebi.ac.uk/resource/ensembl.transcript/ENST00000248306", 'transcript URI');

# compare exon
is(scalar @{$translator->exons($transcript)}, 12, 'number of transcript exons');
my $exon = $translator->exons($transcript)->[3];
my %exon_attrs = (
   end => 82476718,
   seq_region_name => '12',
   coord_system_name => 'chromosome',
   coord_system_version => 'GRCh38',
   strand => '1',
   id => 'ENSE00003483236',
   type => 'exon',
   rank => 10,
   start => 82476644,
   so_term => undef
);

foreach my $attr (keys %exon_attrs) {
  is($translator->$attr($exon), $exon_attrs{$attr}, "exon $attr");
}

is($translator->uri($exon), "http://rdf.ebi.ac.uk/resource/ensembl.exon/ENSE00003483236", 'exon URI');

# compare translation, its xrefs and protein features
is(scalar @{$translator->translations($transcript)}, 1, 'number of translations');
my $translation = $translator->translations($transcript)->[0];
is($translator->id($translation), 'ENSP00000248306', 'translation id');
is($translator->type($translation), 'translation', 'translation type');
is(scalar @{$translator->xrefs($translation)}, 18, 'number of translation xrefs');
cmp_deeply($translator->xrefs($translation)->[17],
     {
      display_id => 'Q8N6Q8',
      primary_id => 'Q8N6Q8',
      info_type => 'DIRECT',
      info_text => 'Generated via direct',
      description => 'Methyltransferase-like protein 25 ',
      dbname => 'Uniprot/SWISSPROT'
     }, 'translation xref');
is($translator->uri($translation), "http://rdf.ebi.ac.uk/resource/ensembl.protein/ENSP00000248306", 'translation URI');
my $protein_features = $translator->protein_features($translation);
is(scalar @{$protein_features}, 7, 'number of protein features');
cmp_deeply($protein_features->[4],
     {
      name => 'PTHR12496:SF0',
      translation_id => 'ENSP00000248306',
      description => undef,
      interpro_ac => undef,
      dbname => 'PANTHER',
      end => 265,
      start => 1
     }, 'protein feature attributes');

sub slurp_file {
  my $file = shift;
  defined $file or die "Undefined file";
  
  my $string;
  {
    local $/=undef;
    open my $FILE, '<', $file or die "Couldn't open file: $!";
    $string = <$FILE>;
    close $FILE;
  }
  
  return $string;
}

done_testing();
