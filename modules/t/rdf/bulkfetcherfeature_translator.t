# Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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
use Bio::EnsEMBL::IO::Translator::BulkFetcherFeature;

use_ok 'Bio::EnsEMBL::IO::Translator::BulkFetcherFeature';

my $omulti = Bio::EnsEMBL::Test::MultiTestDB->new('ontology', "$Bin/..");
my $ontology_adaptor =
  $omulti->get_DBAdaptor('ontology')->get_OntologyTermAdaptor();

my $multi = Bio::EnsEMBL::Test::MultiTestDB->new(undef, "$Bin/..");
my $meta_adaptor = $multi->get_DBAdaptor('core')->get_MetaContainer();
my ($version, $production_name) =
  (
   $meta_adaptor->list_value_by_key('schema_version')->[0],
   $meta_adaptor->list_value_by_key('species.production_name')->[0]
  );

my $translator =
  Bio::EnsEMBL::IO::Translator::BulkFetcherFeature->new(xref_mapping_file => "$Bin/xref_LOD_mapping.json",
							ontology_adaptor  => $ontology_adaptor,
							meta_adaptor      => $meta_adaptor);

ok($translator->version == $version, 'version');
ok($translator->production_name eq $production_name, 'production name');

# read in a sample gene structure fetched by the bulk fetcher
my $gene = from_json(slurp_file("$Bin/gene.json"));

# test various accessors
my %gene_attrs =
  (
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
   provenance => 'ANNOTATED'
  );
foreach my $attr (keys %gene_attrs) {
  is($translator->$attr($gene), $gene_attrs{$attr}, "gene $attr");
}
cmp_deeply($translator->synonyms($gene), [ 'C12orf26', 'FLJ22789' ], 'gene synonyms');
cmp_deeply($translator->xrefs($gene)->[5],
	   { display_id => 'METTL25',
	     primary_id => 84190,
	     info_type  => 'DEPENDENT',
	     info_text  => '',
	     description => 'methyltransferase like 25',
	     dbname     => 'WikiGene' }, 'gene xref');
cmp_deeply($translator->homologues($gene)->[1],
	   { stable_id => 'ENSGGOG00000023239',
	     genome => 'gorilla_gorilla',
	     description => 'ortholog_one2one' }, 'homolog');

my $transcripts = $translator->transcripts($gene);
is(scalar @{$transcripts}, 11, 'number of transcripts');
my $transcript = $transcripts->[];
my %trascript_attr =
  (
  );

sub slurp_file {
  my $file = shift;
  defined $file or die "Undefined file";
  
  my $string;
  {
    local $/=undef;
    open FILE, "<$file" or die "Couldn't open file: $!";
    $string = <FILE>;
    close FILE;
  }
  
  return $string;
}

done_testing();
