# See the NOTICE file distributed with this work for additional information
# regarding copyright ownership.
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
use IO::String;

use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::CoordSystem;
use Bio::EnsEMBL::Slice;

use Bio::EnsEMBL::IO::Translator::Slice;
use Bio::EnsEMBL::IO::Translator::BulkFetcherFeature;
use Bio::EnsEMBL::IO::Object::RDF;

use_ok 'Bio::EnsEMBL::IO::Writer::RDF';

my $omulti = Bio::EnsEMBL::Test::MultiTestDB->new('ontology', "$Bin/..");
my $multi = Bio::EnsEMBL::Test::MultiTestDB->new(undef, "$Bin/..");
my $adaptor = $multi->get_DBAdaptor('core');
my $meta_adaptor = $adaptor->get_MetaContainer();
my $version = $meta_adaptor->list_value_by_key('schema_version')->[0];

# create some slices and features as a subset of a BulkFetcher dump
my @slices = (
  Bio::EnsEMBL::Slice->new(
    -coord_system     => Bio::EnsEMBL::CoordSystem->new(
      -NAME    => 'chromosome',
      -VERSION => 'GRCh38',
      -RANK    => 1,
    ),
    -seq_region_name  => 1,
    -start            => 1,
    -end              => 248956422,
    -strand           => 1,
  )
);

# read in a sample gene structure fetched by the bulk fetcher
my $gene = from_json(slurp_file("$Bin/gene.json"));
# shrink the gene structure so that it has manageable number of sub-components (i.e. transcripts, exons, homologs)
splice @{$gene->{homologues}}, 1; # 1 homolog
splice @{$gene->{xrefs}}, 1; # 1 xref
splice @{$gene->{transcripts}}, 1; # 1 transcript
splice @{$gene->{transcripts}[0]{exons}}, 1; # 1 exon
splice @{$gene->{transcripts}[0]{translations}}, 1; # 1 translation
splice @{$gene->{transcripts}[0]{xrefs}}, 1; # 1 xref per transcript
splice @{$gene->{transcripts}[0]{translations}[0]{protein_features}}, 1; # 1 protein feature per translation
splice @{$gene->{transcripts}[0]{translations}[0]{xrefs}}, 1; # 1 xref per translation

my @features = ($gene);

# create target feature string
my $rdf_string = <<"RDF";
\@prefix blastprodom: <http://purl.uniprot.org/prodom/> .
\@prefix dataset: <http://rdf.ebi.ac.uk/dataset/ensembl/> .
\@prefix dc: <http://purl.org/dc/elements/1.1/> .
taxon:9606 rdfs:subClassOf obo:OBI_0100026 .
taxon:9606 skos:prefLabel \"Homo sapiens\" .
taxon:9606 skos:altLabel \"Human\" .
taxon:9606 dc:identifier \"9606\" .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/chromosome:GRCh38:1:1:248956422:1> rdfs:subClassOf <http://rdf.ebi.ac.uk/resource/ensembl/homo_sapiens/GRCh38/chromosome:GRCh38:1:1:248956422:1> .
<http://rdf.ebi.ac.uk/resource/ensembl/homo_sapiens/GRCh38/chromosome:GRCh38:1:1:248956422:1> rdfs:subClassOf obo:SO_0000340 .
<http://rdf.ebi.ac.uk/resource/ensembl/homo_sapiens/GRCh38/chromosome:GRCh38:1:1:248956422:1> rdfs:label \"Homo sapiens chromosome chromosome:GRCh38:1:1:248956422:1\" .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/chromosome:GRCh38:1:1:248956422:1> rdfs:label \"Homo sapiens chromosome:GRCh38:1:1:248956422:1 (GRCh38)\" .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/chromosome:GRCh38:1:1:248956422:1> dc:identifier \"chromosome:GRCh38:1:1:248956422:1\" .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/chromosome:GRCh38:1:1:248956422:1> term:inEnsemblSchemaNumber \"$version\" .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/chromosome:GRCh38:1:1:248956422:1> term:inEnsemblAssembly \"GRCh38\" .
<http://rdf.ebi.ac.uk/resource/ensembl/ENSG00000127720> rdf:type obo:SO_0001217 .
<http://rdf.ebi.ac.uk/resource/ensembl/ENSG00000127720> rdf:type term:protein_coding .
<http://rdf.ebi.ac.uk/resource/ensembl/ENSG00000127720> rdfs:label \"METTL25\" .
<http://rdf.ebi.ac.uk/resource/ensembl/ENSG00000127720> dc:description \"methyltransferase like 25 [Source:HGNC Symbol;Acc:HGNC:26228]\" .
<http://rdf.ebi.ac.uk/resource/ensembl/ENSG00000127720> obo:RO_0002162 taxon:9606 .
<http://rdf.ebi.ac.uk/resource/ensembl/ENSG00000127720> dc:identifier \"ENSG00000127720\" .
<http://rdf.ebi.ac.uk/resource/ensembl/ENSG00000127720> rdfs:seeAlso <http://identifiers.org/ensembl/ENSG00000127720> .
<http://identifiers.org/ensembl/ENSG00000127720> rdf:type identifiers:ensembl .
<http://identifiers.org/ensembl/ENSG00000127720> sio:SIO_000671 [a ident_type:ensembl; sio:SIO_000300 \"ENSG00000127720\"] .
<http://rdf.ebi.ac.uk/resource/ensembl/ENSG00000127720> faldo:location <http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82358497-82479236:1> .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82358497-82479236:1> rdfs:label \"chromosome 12:82358497-82479236:1\" .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82358497-82479236:1> rdf:type faldo:Region .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82358497-82479236:1> faldo:begin <http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82358497:1> .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82358497-82479236:1> faldo:end <http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82479236:1> .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82358497-82479236:1> faldo:reference <http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12> .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82358497:1> rdf:type faldo:ExactPosition .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82358497:1> rdf:type faldo:ForwardStrandPosition .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82358497:1> faldo:position 82358497 .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82358497:1> faldo:reference <http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12> .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82479236:1> rdf:type faldo:ExactPosition .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82479236:1> rdf:type faldo:ForwardStrandPosition .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82479236:1> faldo:position 82479236 .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82479236:1> faldo:reference <http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12> .
<http://rdf.ebi.ac.uk/resource/ensembl/ENSG00000127720> skos:altlabel \"C12orf26\" .
<http://rdf.ebi.ac.uk/resource/ensembl/ENSG00000127720> skos:altlabel \"FLJ22789\" .
<http://rdf.ebi.ac.uk/resource/ensembl.transcript/ENST00000248306> rdf:type obo:SO_0000234 .
<http://rdf.ebi.ac.uk/resource/ensembl.transcript/ENST00000248306> rdf:type term:protein_coding .
<http://rdf.ebi.ac.uk/resource/ensembl.transcript/ENST00000248306> rdfs:label \"METTL25-201\" .
<http://rdf.ebi.ac.uk/resource/ensembl.transcript/ENST00000248306> obo:RO_0002162 taxon:9606 .
<http://rdf.ebi.ac.uk/resource/ensembl.transcript/ENST00000248306> dc:identifier \"ENST00000248306\" .
<http://rdf.ebi.ac.uk/resource/ensembl.transcript/ENST00000248306> rdfs:seeAlso <http://identifiers.org/ensembl/ENST00000248306> .
<http://identifiers.org/ensembl/ENST00000248306> rdf:type identifiers:ensembl .
<http://identifiers.org/ensembl/ENST00000248306> sio:SIO_000671 [a ident_type:ensembl; sio:SIO_000300 \"ENST00000248306\"] .
<http://rdf.ebi.ac.uk/resource/ensembl.transcript/ENST00000248306> faldo:location <http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82358497-82479236:1> .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82358497-82479236:1> rdfs:label \"chromosome 12:82358497-82479236:1\" .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82358497-82479236:1> rdf:type faldo:Region .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82358497-82479236:1> faldo:begin <http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82358497:1> .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82358497-82479236:1> faldo:end <http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82479236:1> .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82358497-82479236:1> faldo:reference <http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12> .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82358497:1> rdf:type faldo:ExactPosition .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82358497:1> rdf:type faldo:ForwardStrandPosition .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82358497:1> faldo:position 82358497 .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82358497:1> faldo:reference <http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12> .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82479236:1> rdf:type faldo:ExactPosition .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82479236:1> rdf:type faldo:ForwardStrandPosition .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82479236:1> faldo:position 82479236 .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82479236:1> faldo:reference <http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12> .
<http://rdf.ebi.ac.uk/resource/ensembl.exon/ENSE00000910621> rdf:type obo:SO_0000147 .
<http://rdf.ebi.ac.uk/resource/ensembl.exon/ENSE00000910621> rdfs:label \"ENSE00000910621\" .
<http://rdf.ebi.ac.uk/resource/ensembl.transcript/ENST00000248306> obo:SO_has_part <http://rdf.ebi.ac.uk/resource/ensembl.exon/ENSE00000910621> .
<http://rdf.ebi.ac.uk/resource/ensembl.exon/ENSE00000910621> obo:RO_0002162 taxon:9606 .
<http://rdf.ebi.ac.uk/resource/ensembl.exon/ENSE00000910621> dc:identifier \"ENSE00000910621\" .
<http://rdf.ebi.ac.uk/resource/ensembl.exon/ENSE00000910621> rdfs:seeAlso <http://identifiers.org/ensembl/ENSE00000910621> .
<http://identifiers.org/ensembl/ENSE00000910621> rdf:type identifiers:ensembl .
<http://identifiers.org/ensembl/ENSE00000910621> sio:SIO_000671 [a ident_type:ensembl; sio:SIO_000300 \"ENSE00000910621\"] .
<http://rdf.ebi.ac.uk/resource/ensembl.exon/ENSE00000910621> faldo:location <http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82358497-82358824:1> .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82358497-82358824:1> rdfs:label \"chromosome 12:82358497-82358824:1\" .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82358497-82358824:1> rdf:type faldo:Region .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82358497-82358824:1> faldo:begin <http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82358497:1> .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82358497-82358824:1> faldo:end <http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82358824:1> .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82358497-82358824:1> faldo:reference <http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12> .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82358497:1> rdf:type faldo:ExactPosition .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82358497:1> rdf:type faldo:ForwardStrandPosition .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82358497:1> faldo:position 82358497 .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82358497:1> faldo:reference <http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12> .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82358824:1> rdf:type faldo:ExactPosition .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82358824:1> rdf:type faldo:ForwardStrandPosition .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82358824:1> faldo:position 82358824 .
<http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12:82358824:1> faldo:reference <http://rdf.ebi.ac.uk/resource/ensembl/$version/homo_sapiens/GRCh38/12> .
<http://rdf.ebi.ac.uk/resource/ensembl.transcript/ENST00000248306> sio:SIO_000974 <http://rdf.ebi.ac.uk/resource/ensembl.transcript/ENST00000248306#Exon_1> .
<http://rdf.ebi.ac.uk/resource/ensembl.transcript/ENST00000248306#Exon_1> rdf:type sio:SIO_001261 .
<http://rdf.ebi.ac.uk/resource/ensembl.transcript/ENST00000248306#Exon_1> sio:SIO_000628 <http://rdf.ebi.ac.uk/resource/ensembl.exon/ENSE00000910621> .
<http://rdf.ebi.ac.uk/resource/ensembl.transcript/ENST00000248306#Exon_1> sio:SIO_000300 1 .
<http://rdf.ebi.ac.uk/resource/ensembl.protein/ENSP00000248306> obo:RO_0002162 taxon:9606 .
<http://rdf.ebi.ac.uk/resource/ensembl.protein/ENSP00000248306> dc:identifier \"ENSP00000248306\" .
<http://rdf.ebi.ac.uk/resource/ensembl.protein/ENSP00000248306> rdfs:seeAlso <http://identifiers.org/ensembl/ENSP00000248306> .
<http://identifiers.org/ensembl/ENSP00000248306> rdf:type identifiers:ensembl .
<http://identifiers.org/ensembl/ENSP00000248306> sio:SIO_000671 [a ident_type:ensembl; sio:SIO_000300 \"ENSP00000248306\"] .
<http://rdf.ebi.ac.uk/resource/ensembl.transcript/ENST00000248306> obo:SO_translates_to <http://rdf.ebi.ac.uk/resource/ensembl.protein/ENSP00000248306> .
<http://rdf.ebi.ac.uk/resource/ensembl.protein/ENSP00000248306> rdf:type term:protein .
<http://rdf.ebi.ac.uk/resource/ensembl.protein/ENSP00000248306> rdfs:seeAlso gene3d:3.40.50.150 .
<http://rdf.ebi.ac.uk/resource/ensembl.transcript/ENST00000248306> obo:SO_transcribed_from <http://rdf.ebi.ac.uk/resource/ensembl/ENSG00000127720> .
<http://rdf.ebi.ac.uk/resource/ensembl/ENSG00000127720> sio:SIO_000558 ensembl:ENSPTRG00000005267 .

<http://rdf.ebi.ac.uk/dataset/ensembl/$version/homo_sapiens> <http://rdfs.org/ns/void#subset> <http://rdf.ebi.ac.uk/dataset/ensembl/$version> .
RDF

# 

# translators for slices and (bulk fetcher derived) features
my $slice_trans = Bio::EnsEMBL::IO::Translator::Slice->new(
  version => $version,
  meta_adaptor => $meta_adaptor
);

my $feature_trans = Bio::EnsEMBL::IO::Translator::BulkFetcherFeature->new(
  version           => $version,
  xref_mapping_file => "$Bin/xref_LOD_mapping.json",
  adaptor           => $adaptor
);

my $feature_writer = Bio::EnsEMBL::IO::Writer::RDF->new(); # do not pass translator, pass it when writing since we need the slice and feature translators

# open string FH for features and xrefs files
my $fh = IO::String->new();
$feature_writer->open($fh);

# write namespaces, pass minimal prefix set to reduce clutter
# my $namespaces = Bio::EnsEMBL::IO::Object::RDF->namespaces();
$feature_writer->write(
  Bio::EnsEMBL::IO::Object::RDF->namespaces(
    blastprodom => "http://purl.uniprot.org/prodom/",
    dataset     => 'http://rdf.ebi.ac.uk/dataset/ensembl/',
    dc          => 'http://purl.org/dc/elements/1.1/'
  )
);

# write species info
$feature_writer->write(
  Bio::EnsEMBL::IO::Object::RDF->species(
    taxon_id        => $meta_adaptor->get_taxonomy_id,
    scientific_name => $meta_adaptor->get_scientific_name,
    common_name     => $meta_adaptor->get_common_name
  )
);

map { $feature_writer->write($_, $slice_trans) } @slices;
map { $feature_writer->write($_, $feature_trans) } @features;

# finally write connecting triple to master RDF file
$feature_writer->write(
  Bio::EnsEMBL::IO::Object::RDF->dataset(
    version => $version,
    project => 'ensembl',
    production_name => 'homo_sapiens'
  )
);

eq_or_diff(${$fh->string_ref()}, $rdf_string, "serializer output matches expected RDF");

$feature_writer->close();

done_testing();

sub slurp_file {
  my $file = shift;
  defined $file or die "Undefined file";

  my $string;
  {
    local $/=undef;
    open my $FILE, '<', $file or die "Couldn't open file $file: $!";
    $string = <$FILE>;
    close $FILE;
  }

  return $string;
}
