=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2017] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

  RDFlib - library of functions for turning Ensembl data into RDF turtle

=head1 SYNOPSIS

  use Bio::EnsEMBL::RDF::RDFlib qw/u triple prefix/;
  print triple( u(prefix('ensembl').':'.$id) , 'rdf:label', 'insignificant text' );
  
  # More commonly you can use the shorthand to define namespaces
  print name_spaces;
  print triple('ensembl:ENSG001', 'rdf:label', 'inconsequential text');

=head1 DESCRIPTION

  A bunch of common shortcuts for formatting RDF for printing and supplying things like unique bnode IDs.

=cut

package Bio::EnsEMBL::Utils::RDF;

use Modern::Perl;
use parent 'Exporter';
our @EXPORT_OK = qw(u triple escape clean_for_uri taxon_triple prefix name_spaces compatible_name_spaces);
our %EXPORT_TAGS = (all => [qw(u triple escape clean_for_uri taxon_triple prefix name_spaces compatible_name_spaces)],
                    query => [qw(prefix compatible_name_spaces escape clean_for_uri)]);

use Carp;
use URI::Escape;

# common prefixes used
our %prefix = (
  blastprodom => "http://purl.uniprot.org/prodom/",
  dataset     => 'http://rdf.ebi.ac.uk/dataset/ensembl/',
  dc          => 'http://purl.org/dc/elements/1.1/',
  dcat        => 'http://www.w3.org/ns/dcat#',
  dcmit       => 'http://purl.org/dc/dcmitype/',
  dcterms     => 'http://purl.org/dc/terms/',
  dctypes     => 'http://purl.org/dc/dcmitype/',
  ensembl     => 'http://rdf.ebi.ac.uk/resource/ensembl/',
  ensembl_variant => 'http://rdf.ebi.ac.uk/resource/ensembl.variant/',
  ensemblvariation => 'http://rdf.ebi.ac.uk/terms/ensemblvariation/',
  exon        => 'http://rdf.ebi.ac.uk/resource/ensembl.exon/',
  faldo       => 'http://biohackathon.org/resource/faldo#',
  freq        => 'http://purl.org/cld/freq/',
  foaf        => 'http://xmlns.com/foaf/0.1/',
  gene3d      => "http://purl.uniprot.org/gene3d/",
  hamap       => "http://purl.uniprot.org/hamap/",
  hmmpanther  => "http://purl.uniprot.org/panther/",
  ident_type  => 'http://idtype.identifiers.org/',
  identifiers => 'http://identifiers.org/',
  interpro    => "http://purl.uniprot.org/interpro/",
  oa          => "http://www.w3.org/ns/oa#",
  oban        => 'http://purl.org/oban/',
  obo         => 'http://purl.obolibrary.org/obo/',
  panther     => "http://purl.uniprot.org/panther/",
  pav         => 'http://purl.org/pav/',
  pfam        => "http://purl.uniprot.org/pfam/",
  pfscan      => "http://purl.uniprot.org/profile/",
  pirsf       => "http://purl.uniprot.org/pirsf/",
  prints      => "http://purl.uniprot.org/prints/",
  prodom      => "http://purl.uniprot.org/prodom/",
  prosite_patterns => "http://purl.uniprot.org/prosite/",
  prosite_profiles => "http://purl.uniprot.org/prosite/",
  protein     => 'http://rdf.ebi.ac.uk/resource/ensembl.protein/',
  prov        => 'http://www.w3.org/ns/prov#',
  rdf         => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
  rdfs        => 'http://www.w3.org/2000/01/rdf-schema#',
  scanprosite => "http://purl.uniprot.org/prosite/",
  sio         => 'http://semanticscience.org/resource/',
  skos        => 'http://www.w3.org/2004/02/skos/core#',
  smart       => "http://purl.uniprot.org/smart/",
  superfamily => "http://purl.uniprot.org/supfam/",
  taxon       => 'http://identifiers.org/taxonomy/',
  term        => 'http://rdf.ebi.ac.uk/terms/ensembl/',
  tigrfam     => "http://purl.uniprot.org/tigrfams/",
  transcript  => 'http://rdf.ebi.ac.uk/resource/ensembl.transcript/',
  uniprot_gn  => 'http://purl.uniprot.org/uniprot/',
  uniparc     => 'http://purl.uniprot.org/uniparc/',
  void        => 'http://rdfs.org/ns/void#',
  xml         => 'http://www.w3.org/XML/1998/namespace',
  xsd         => 'http://www.w3.org/2001/XMLSchema#',
);

# Set of RDF-writing utility functions

# URI-ify
sub u {
  my $stuff= shift;
  return '<'.$stuff.'>';
}

sub triple {
    my ($subject,$predicate,$object) = @_;    
    return sprintf "%s %s %s .\n",$subject,$predicate,$object;
}

sub escape {
  my $string = shift;
  $string =~s/\n//g; # Newlines do not belong in dumped data.
  $string =~s/(["])/\\$1/g;
  return $string;
}

sub clean_for_uri {
  my $string = shift;
  $string =~ s/[\s:]/_/g;
  return $string;
}

sub taxon_triple {
  my ($subject, $taxon_id) = @_;
  return triple($subject, 'obo:RO_0002162', 'taxon:'.$taxon_id);
}

# prefix('faldo') etc.
sub prefix {
  my $key = shift;
  return $prefix{lc($key)};
}

# Hand URIs out to calling code with correct namespacing etc.
sub feature_uri {
  my ($id, $type) = @_;
  confess "Cannot generate URIs without both a feature ID and its type"
    unless $id && $type;

  my %type2prefix =
    (
     gene => 'ensembl',
     transcript => 'transcript',
     exon => 'exon',
     translation => 'protein',
     variation => 'ensemblvariation',
     variant => 'ensembl_variant',
    );
  
  my $prefix = $type2prefix{$type};
  confess "Cannot map feature type '$type' to a prefix"
    unless $prefix;
  
  my $namespace = prefix($prefix);
  $id = uri_escape($id);
  return prefix($prefix) . uri_escape($id);
}

# These namespaces are useful for turtle 1.0 serialisation, but not SPARQL. For SPARQL, use compatible_name_spaces()
sub name_spaces {
  return join "\n",map { sprintf '@prefix %s: %s .',$_,u($prefix{$_}) } keys %prefix;  
}

sub compatible_name_spaces {
  return join "\n",map { sprintf 'PREFIX %s: %s',$_,u($prefix{$_}) } keys %prefix;  
}

# bnodes must only be unique within a single document, hence a single run of this module is sufficient for the state.
my $b_node_count = 0;
sub new_bnode {
  my $self = shift;
  $b_node_count++;
  return '_'.$b_node_count;
}

1;
