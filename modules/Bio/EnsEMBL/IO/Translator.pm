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

Bio::EnsEMBL::IO::Translator - Base class for object translator

=head1 SYNOPSIS

  The class should not be directly instantiated, but derived to a subclass
  based on the object type being interrogated.

  use Bio::EnsEMBL::IO::Translator;

  my $translator = Bio::EnsEMBL::IO::Translator->new();

  my @values = $translator->batch_fields($object, @fields);
  my $value = $translator->get_field($object, 'fieldname');

  $translator->add_callbacks($ref_of_hash_of_callbacks);

=head1 Description

Base class for a translator, the purpose of a translator is to translate between the object types
being serialized and the writer. The translator for a specific object type should know how to
access the needed attributes requested by the writer, either directly from the object or if
more complicated lookups are needed how to do those lookups.

=cut

package Bio::EnsEMBL::IO::Translator;

use strict;
use warnings;
use Carp;

my %field_callbacks;

=head2 new

    Returntype   : Bio::EnsEMBL::IO::Translator

=cut

sub new {
  my ($class) = @_;
  
  my $self = {};

  bless $self, $class;

  return $self;

}

=head2 get_field

    Description: Fetch a field from the object, use the callback set by
                 derived classes to access the field from the object. If
                 the callback doesn't exist, return undef
    Args[1]    : Object to fetch fields from
    Args[2]    : Field name
    Returntype : String, hashref or undef

=cut

sub get_field {
    my $self = shift;
    my $object = shift;
    my $field = shift;

    # If we have the requested field, return it
    if(defined( $field_callbacks{$field} )) {
	return $field_callbacks{$field}->($object);
    }

    # If the field doesn't exist, return undef
    return undef;
}

=head2 batch_fields

    Description: Fetch a list of fields from the object in one call, fields are returned
                 in the same order requested
    Args[1]    : Object to fetch fields from
    Args[2]    : List of fields to return
    Returntype : Array

=cut

sub batch_fields {
    my $self = shift;
    my $object = shift;
    my $fields = shift;

    my @values;

    # Cycle through fields and fetch values
    foreach my $field (@{$fields}) {
	my $value = $self->$field($object);
	push @values, $value;
    }
    
    return @values;
}

=head2 add_callbacks

    Description: Add additional field callbacks to the translator
    Args[1]    : Hashref, list of fields and callbacks
    Returntype : None

=cut

sub add_callbacks {
    my $self = shift;
    my $callbacks = shift;

    # Splice new callbacks in to existing set, overwritting any
    # previous callback
    @field_callbacks{ keys %$callbacks } = values %$callbacks;
}

=head2 fetch_callback

    Description: Fetch a field's callback, if set
    Args[1]    : Field name
    Returntype : String or undef

=cut

sub fetch_callback {
    my $self = shift;
    my $field = shift;

     # If we have the requested field, return it
    if(defined( $field_callbacks{$field} )) {
	return $field_callbacks{$field};
    }

    # If the field doesn't exist, return undef
    return undef
}

1;
