=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

Bio::EnsEMBL::IO::Translator::Slice

=head1 SYNOPSIS

=head1 DESCRIPTION

Translator for Ensembl slices.

=cut

package Bio::EnsEMBL::IO::Translator::Slice;

use base qw/Bio::EnsEMBL::IO::Translator/;

use strict;
use warnings;

use Carp;

use Bio::EnsEMBL::Utils::RDF;
use Bio::EnsEMBL::Utils::RDF::Mapper;
use Bio::EnsEMBL::Utils::SequenceOntologyMapper;

my %field_callbacks = (version         => 'version',
		       production_name => 'production_name',
		       taxon_id        => 'taxon_id',
		       scientific_name => 'scientific_name',
		       name            => 'name',
		       coord_system    => 'coord_system',
		       uri             => 'uri'
		      );

=head2 new

    Returntype   : Bio::EnsEMBL::IO::Translator::Slice

=cut

sub new {
  my ($class, %args) = @_;
  
  my @required_args = qw/release production_name meta_adaptor/;
  my @missing_args;
  map { push @missing_args, $args{$_} unless exists $args{$_} } @required_args;
  confess "Missing arguments required by Bio::EnsEMBL::IO::Translator::Feature: " . join(',', @missing_args)
    if scalar @missing_args;

  croak "Bio::EnsEMBL::IO::Translator::Slice requires a meta adaptor"
    unless $args{meta_adaptor}->isa('Bio::EnsEMBL::DBSQL::MetaContainer');

  my $self = $class->SUPER::new(\%args);

  # once we have the instance, add our customized callbacks to the translator
  $self->add_callbacks(\%field_callbacks);

  return $self;
}

sub version {
  my ($self, $version) = @_;
  
  $self->{version} = $version if $version;
  return $self->{version};
}

sub production_name {
  my $self = shift;
  return $self->{production_name};
}

sub meta_adaptor {
  my $self = shift;
  return $self->{meta_adaptor};
}

=head2 taxon_id

    Description: 
    Returntype : 

=cut

sub taxon_id {
  my ($self, $object) = @_;
  
  return $self->meta_adaptor->get_taxonomy_id;
}

=head2 scientific_name

    Description: 
    Returntype : 

=cut

sub scientific_name {
  my ($self, $object) = @_;
  
  return $self->meta_adaptor->get_scientific_name;
}

=head2 name

    Description: Wrapper around slice name field
    Returntype : String

=cut

sub name {
  my ($self, $object) = @_;
  
  return $object->{name};
}

=head2 coord_system

    Description: Wrapper around slice coord_system method
    Returntype : An Ensembl coord system object

=cut

sub coord_system {
  my ($self, $object) = @_;
  
  return $object->coord_system();
}

=head2 uri

    Description: 
    Returntype : ArrayRef

=cut

# TODO: implement seq_region_uri in Bio::EnsEMBL::Utils::RDF

sub uri {
  my ($self, $object) = @_;

  return seq_feature_uri($self->id($object), $self->type($object));
}

1;
