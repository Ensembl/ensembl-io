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

use FindBin qw/$Bin/;
use Test::More;
use Test::Deep;
use Test::Differences;
use Test::Exception;
use JSON;
use IO::String;

use Bio::EnsEMBL::Test::MultiTestDB;

use Bio::EnsEMBL::Utils::SequenceOntologyMapper;

use Bio::EnsEMBL::IO::Translator::BulkFetcherFeature;
use Bio::EnsEMBL::IO::Object::RDF;

use_ok 'Bio::EnsEMBL::IO::Writer::RDF::XRefs';

my $omulti = Bio::EnsEMBL::Test::MultiTestDB->new('ontology', "$Bin/..");

my $multi = Bio::EnsEMBL::Test::MultiTestDB->new(undef, "$Bin/..");
my $adaptor = $multi->get_DBAdaptor('core');
my $version = $adaptor->get_MetaContainer()->list_value_by_key('schema_version')->[0];

# create some features as a subset of a BulkFetcher dump

# read in a sample gene structure fetched by the bulk fetcher
my $gene = from_json(slurp_file("$Bin/gene.json"));

# shrink the gene structure so that it has manageable number of sub-components (i.e. transcripts, exons, homologs)
splice @{$gene->{homologues}}, 1; # 1 homolog
splice @{$gene->{xrefs}}, 1; # 1 xref
splice @{$gene->{transcripts}}, 1; # 1 transcript
splice @{$gene->{transcripts}[0]{exons}}, 1; # 1 exon
splice @{$gene->{transcripts}[0]{translations}}, 1; # 1 translation
splice @{$gene->{transcripts}[0]{xrefs}}, 1; # 1 xref per transcript
# [ENSCORESW-2372]: re-add GO xref to transcript
push @{$gene->{transcripts}[0]{xrefs}},
  {
   'display_id' => 'GO:0032259',
   'primary_id' => 'GO:0032259',
   'associated_xrefs' => [],
   'linkage_types' => [
		       {
			'source' => {
				     'display_id' => 'Q8N6Q8',
				     'primary_id' => 'Q8N6Q8',
				     'description' => 'Methyltransferase-like protein 25 ',
				     'dbname' => 'Uniprot/SWISSPROT'
				    },
			'evidence' => 'IEA'
		       }
		      ],
   'description' => 'methylation',
   'dbname' => 'GO'
  };
splice @{$gene->{transcripts}[0]{translations}[0]{protein_features}}, 1; # 1 protein feature per translation
splice @{$gene->{transcripts}[0]{translations}[0]{xrefs}}, 1; # 1 xref per translation

my @features = ($gene);

# create target feature string
my $rdf_string = <<"RDF";
\@prefix blastprodom: <http://purl.uniprot.org/prodom/> .
\@prefix dataset: <http://rdf.ebi.ac.uk/dataset/ensembl/> .
\@prefix dc: <http://purl.org/dc/elements/1.1/> .
<http://rdf.ebi.ac.uk/resource/ensembl/ENSG00000127720> rdfs:seeAlso <http://identifiers.org/unigene/Hs.506222> .
<http://identifiers.org/unigene/Hs.506222> rdf:type identifiers:unigene .
<http://identifiers.org/unigene/Hs.506222> sio:SIO_000671 [a ident_type:unigene; sio:SIO_000300 \"Hs.506222\"] .
<http://identifiers.org/unigene/Hs.506222> rdf:type <http://rdf.ebi.ac.uk/terms/ensembl/EnsemblDBEntry> .
<http://rdf.ebi.ac.uk/resource/ensembl/ENSG00000127720> term:SEQUENCE_MATCH <http://identifiers.org/unigene/Hs.506222> .
<http://identifiers.org/unigene/Hs.506222> dc:identifier \"Hs.506222\" .
<http://identifiers.org/unigene/Hs.506222> rdfs:label \"Hs.506222\" .
<http://identifiers.org/unigene/Hs.506222> dc:description \"Methyltransferase like 25\" .
<http://rdf.ebi.ac.uk/resource/ensembl/UCSC/uc001szq.4> rdf:type <http://rdf.ebi.ac.uk/resource/ensembl/UCSC> .
<http://rdf.ebi.ac.uk/resource/ensembl/UCSC/uc001szq.4> rdf:type <http://rdf.ebi.ac.uk/terms/ensembl/EnsemblDBEntry> .
<http://rdf.ebi.ac.uk/resource/ensembl.transcript/ENST00000248306> term:COORDINATE_OVERLAP <http://rdf.ebi.ac.uk/resource/ensembl/UCSC/uc001szq.4> .
<http://rdf.ebi.ac.uk/resource/ensembl/UCSC/uc001szq.4> dc:identifier \"uc001szq.4\" .
<http://rdf.ebi.ac.uk/resource/ensembl/UCSC/uc001szq.4> rdfs:label \"uc001szq.4\" .
<http://rdf.ebi.ac.uk/resource/ensembl.transcript/ENST00000248306> rdfs:seeAlso <http://identifiers.org/go/GO:0032259> .
<http://identifiers.org/go/GO:0032259> rdf:type identifiers:go .
<http://identifiers.org/go/GO:0032259> sio:SIO_000671 [a ident_type:go; sio:SIO_000300 \"GO:0032259\"] .
<http://identifiers.org/go/GO:0032259> owl:sameAs <http://purl.obolibrary.org/obo/GO_0032259> .
<http://identifiers.org/go/GO:0032259> rdf:type <http://rdf.ebi.ac.uk/terms/ensembl/EnsemblDBEntry> .
<http://rdf.ebi.ac.uk/resource/ensembl.transcript/ENST00000248306> term:INFERRED_FROM_TRANSCRIPT <http://identifiers.org/go/GO:0032259> .
<http://identifiers.org/go/GO:0032259> dc:identifier \"GO:0032259\" .
<http://identifiers.org/go/GO:0032259> rdfs:label \"GO:0032259\" .
<http://identifiers.org/go/GO:0032259> dc:description \"methylation\" .
<http://rdf.ebi.ac.uk/resource/ensembl.protein/ENSP00000248306> rdfs:seeAlso <http://identifiers.org/uniparc/UPI000013CC3E> .
<http://identifiers.org/uniparc/UPI000013CC3E> rdf:type identifiers:uniparc .
<http://identifiers.org/uniparc/UPI000013CC3E> sio:SIO_000671 [a ident_type:uniparc; sio:SIO_000300 \"UPI000013CC3E\"] .
<http://purl.uniprot.org/uniparc/UPI000013CC3E> rdf:type <http://rdf.ebi.ac.uk/terms/ensembl/EnsemblDBEntry> .
<http://rdf.ebi.ac.uk/resource/ensembl.protein/ENSP00000248306> term:CHECKSUM <http://purl.uniprot.org/uniparc/UPI000013CC3E> .
<http://purl.uniprot.org/uniparc/UPI000013CC3E> dc:identifier \"UPI000013CC3E\" .
<http://purl.uniprot.org/uniparc/UPI000013CC3E> rdfs:label \"UPI000013CC3E\" .

RDF

my $feature_trans =
  Bio::EnsEMBL::IO::Translator::BulkFetcherFeature->new(version => $version,
							xref_mapping_file => "$Bin/xref_LOD_mapping.json",
							biotype_mapper    => Bio::EnsEMBL::Utils::SequenceOntologyMapper->new($omulti->get_DBAdaptor('ontology')->get_OntologyTermAdaptor()),
							adaptor      => $adaptor);

my $xrefs_writer = Bio::EnsEMBL::IO::Writer::RDF::XRefs->new($feature_trans);

# open string FH for features and xrefs files
my $fh = IO::String->new();
$xrefs_writer->open($fh);

# write namespaces, pass minimal prefix set to reduce clutter
$xrefs_writer->write(Bio::EnsEMBL::IO::Object::RDF->namespaces(blastprodom => "http://purl.uniprot.org/prodom/",
							       dataset     => 'http://rdf.ebi.ac.uk/dataset/ensembl/',
							       dc          => 'http://purl.org/dc/elements/1.1/'));
map { $xrefs_writer->write($_) } @features;

eq_or_diff(${$fh->string_ref()}, $rdf_string, "serializer output matches expected RDF");

$xrefs_writer->close();

done_testing();

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
