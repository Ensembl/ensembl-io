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

Bio::EnsEMBL::IO::Writer::ColumnBasedGeneric - Generic writer for column based formats

=head1 SYNOPSIS

  The class should not be directly instantiated, but derived to a subclass
  based on the format.

=head1 Description


=cut

package Bio::EnsEMBL::IO::Writer::RDF;

use base qw/Bio::EnsEMBL::IO::Writer/;

use strict;
use warnings;
use Carp;

use Bio::EnsEMBL::Utils::RDF qw/u prefix/;

=head2 new

=cut

sub new {
    my $class = shift;
    my $translator = shift;

    my $self = $class->SUPER::new();

    $self->translator($translator) if $translator;

    return $self;
}

=head2 write

    Description: Write a record to the output, it will use the given
                 translator to interrogate the object for the needed fields
    Args[1]    : Object to write out
    Args[2]    : an alternative translator to use for this record

=cut

sub write {
    my $self = shift;
    my $object = shift;
    my $translator = shift;

    if($object->isa('Bio::EnsEMBL::IO::Object::RDF')) {
      print { $self->{writer_handle} } $object->create_record(), "\n";
    } else {
      print { $self->{writer_handle} } $self->create_record($object, $translator), "\n";
    }
    
}

=head2 create_record

    Description: Create the record in native format to write out to the file
    Args[1]    : Object to format
    Args[2]    : Translator
    Returntype : String

=cut

sub create_record {
  my $self = shift;
  my $object = shift;

  # Use the default translator if we haven't been given one
  my $translator = shift || $self->translator;
  return unless $translator;

  return $self->_create_seq_region_record($object, $translator)
    if $object->isa('Bio::EnsEMBL::Slice');
    
  return $self->_create_bulk_fetcher_feature_record($object, $translator);
}

sub _create_seq_region_record {
  my ($class, $object, $translator) = @_;

  my ($version, $region_name, $cs_name, $cs_version, $scientific_name) =
    $translator->batch_fields($object, [qw/version name cs_name cs_version scientific_name/]);
  my ($version_uri, $non_version_uri) = $translator->uri($object);

  my $record;
  
  # we also create a non versioned URI that is a superclass e.g. 
  $record = sprintf "%s\n", triple($version_uri, 'rdfs:subClassOf', $non_version_uri);
  
  if ($cs_name eq 'chromosome') { 
    $record .= sprintf "%s\n", triple($non_version_uri, 'rdfs:subClassOf', 'obo:SO_0000340');
    # Find SO term for patches and region in general?
  } else {
    $record .= sprintf "%s\n%s\n",
      triple($non_version_uri, 'rdfs:subClassOf', 'term:'.$cs_name),
      triple('term:'.$cs_name, 'rdfs:subClassOf', 'term:EnsemblRegion');
  }
  $record .= sprintf "%s\n%s\n%s\n%s\n%s",
    triple($non_version_uri, 'rdfs:label', qq("$scientific_name $cs_name $region_name")),
    triple($version_uri, 'rdfs:label', qq("$scientific_name $region_name ($cs_version)")),
    triple($version_uri, 'dc:identifier', qq("$region_name")),
    triple($version_uri, 'term:inEnsemblSchemaNumber', qq("$version")),
    triple($version_uri, 'term:inEnsemblAssembly', qq("$cs_version"));

  return $record;
}

sub _create_bulk_fetcher_feature_record {
  my ($class, $object, $translator) = @_;

  my $record;

  return $record;
}

1;
