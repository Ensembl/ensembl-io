=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2020] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

package Bio::EnsEMBL::IO::Object::RDF;

use strict;
use warnings;
use Carp;

use Bio::EnsEMBL::Utils::RDF qw/u triple/;

sub new {
  my ($class) = @_;
  
  my $self = {};
  bless $self, $class;
  
  return $self;
}

=head2 namespaces

=cut

sub namespaces {
  my ($class, %prefix) = @_;
  %prefix = %Bio::EnsEMBL::Utils::RDF::prefix unless %prefix;
    
  return bless { type => 'namespaces', prefix => \%prefix }, $class;
}

=head2 species

=cut

sub species {
  my $class = shift;
  my %args = @_;
  exists $args{taxon_id} or croak "Undefined species taxon_id";
  exists $args{scientific_name} or croak "Undefined species scientific name";
  exists $args{common_name} or croak "Undefined species common name";
  
  return bless { type => 'species', %args }, $class;
}

sub dataset {
  my $class = shift;
  my %args = @_;
  exists $args{version} or croak "Undefined version";
  exists $args{project} or croak "Undefined project";
  exists $args{production_name} or croak "Undefined production name";

  return bless { type => 'dataset', %args}, $class;
}

sub create_record {
  my $self = shift;

  my $line;

  if($self->{type} eq 'namespaces') {
    return unless scalar keys %{$self->{prefix}};
    
    $line = join("\n", map { sprintf "\@prefix %s: %s .", $_, u($self->{prefix}{$_}) } sort keys %{$self->{prefix}});
  } elsif($self->{type} eq 'species') {
    my $taxon_id = $self->{taxon_id};
    my $scientific_name = $self->{scientific_name};
    my $common_name = $self->{common_name};

    # return global triples about the organism  
    $line = sprintf "%s\n%s\n%s\n%s",
      triple('taxon:'.$taxon_id, 'rdfs:subClassOf', 'obo:OBI_0100026'),
      triple('taxon:'.$taxon_id, 'skos:prefLabel', qq("$scientific_name")),
      triple('taxon:'.$taxon_id, 'skos:altLabel', qq("$common_name")),
      triple('taxon:'.$taxon_id, 'dc:identifier', qq("$taxon_id"));
  } elsif ($self->{type} eq 'dataset') {
    my ($version, $project, $production_name) =
      ($self->{version}, $self->{project}, $self->{production_name});
    my $version_graph_uri = sprintf "http://rdf.ebi.ac.uk/dataset/%s/%d", $project, $version;
    my $graph_uri = $version_graph_uri . "/" . $production_name;
    
    $line = triple(u($graph_uri), '<http://rdfs.org/ns/void#subset>', u($version_graph_uri)); 
  } else {
    croak "Unrecognised RDF object type";
  }

  return $line;
}

1;
