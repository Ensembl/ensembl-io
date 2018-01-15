=pod

=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2018] EMBL-European Bioinformatics Institute

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

Format - an abstract class for defining file formats

If extending this class, you _must_ supply a field order and also 
define a validation type for each field. Validation types already defined
in this module include:

* boolean
* string
* integer
* floating_point

* range
* comma_separated
* case_insensitive
* strand_integer
* strand_plusminus
* sequence
* dna_sequence
* colour
* rgb_string

Additional custom validation types can be defined in the subclass, but
should be added to this class unless they are very specialised

=cut

package Bio::EnsEMBL::IO::Format;

use strict;
use warnings;

use Bio::EnsEMBL::IO::NamedColours;

=head2 new

    Description : constructor
    Returntype  : Bio::EnsEMBL::IO::Format object

=cut

sub new {
  my $class = shift;

  my $self = {
              'name'            => '',
              'extensions'      => ['txt'],
              'can_multitrack'  => 0,
              'can_metadata'    => 0,
              'metadata_info'   => {},
              'field_info'      => {},
              'field_order'     => [], 
  };

  bless $self, $class;

  return $self;
}

######## BASIC ACCESSORS #############

=head2 name

    Description : getter for format name
    Returntype  : String

=cut

sub name {
  my $self = shift;
  return $self->{'name'} || '';
}

=head2 extensions

    Description : getter for allowed file extension(s)
    Returntype  : Arrayref

=cut

sub extensions {
  my $self = shift;
  return $self->{'extensions'} || [];
}

=head2 delimiter

    Description : getter for delimiter (if format has one)
    Returntype  : String

=cut

sub delimiter {
  my $self = shift;
  return $self->{'delimiter'};
}

=head2 can_multitrack 

    Description : getter for multitrack flag
    Returntype  : 1 if format can have multiple tracks, 0 if it can't 
=cut

sub can_multitrack {
  my $self = shift;
  return $self->{'can_multitrack'} || 0;
}

=head2 can_metadata 

    Description : getter for metadata flag
    Returntype  : 0 if format cannot have metadata, 1 if metadata is mandatory,
                  -1 if metadata is optional
=cut

sub can_metadata {
  my $self = shift;
  return $self->{'can_metadata'};
}

=head2 get_metadata_info 

    Description : getter for information about valid metadata
    Returntype  : Hashref

=cut

sub get_metadata_info {
  my $self = shift;
  return $self->{'metadata_info'};
}

=head2 set_field_info 

    Description : setter for information about valid fields. Needed by formats
                  that can have optional fields, e.g. BED
    Returntype  : Void 

=cut

sub set_field_info {
  my ($self, $info) = @_;
  if (ref $info eq 'HASH' && keys %$info) {
    $self->{'field_info'} = $info;
  }
  else {
    die "Input must be a non-empty hashref";
  }
}

=head2 get_field_info 

    Description : getter for information about valid fields
    Returntype  : Hashref

=cut

sub get_field_info {
  my $self = shift;
  return $self->{'field_info'};
}

=head2 set_field_order 

    Description : setter for field order. Needed by formats
                  that can have optional fields, e.g. BED
    Returntype  : Void

=cut

sub set_field_order {
  my ($self, $order) = @_;
  if (ref $order eq 'ARRAY' && scalar @$order) {
    $self->{'field_order'} = $order;
  }
  else {
    die "Input must be a non-empty arrayref";
  }
}

=head2 get_field_order 

    Description : getter for order of fields 
    Returntype  : Arrayref

=cut

sub get_field_order {
  my $self = shift;
  return $self->{'field_order'};
}

############ OTHER ACCESSORS ####################

=head2 get_info_for_field

    Description : fetch all information about a given field
    Returntype  : Hashref 

=cut

sub get_info_for_field {
  my ($self, $field) = @_;
  return unless $field;
  my $info = $self->{'field_info'}{$field};
  return $info || {};
}

=head2 get_value_for_field

    Description : fetch a specific value from a field's information
    Returntype  : Undef/String/Arrayref/Hashref

=cut

sub get_value_for_field {
  my ($self, $field, $value) = @_;
  return unless $field && $value;
  my $info = $self->{'field_info'}{$field};
  return unless $info && ref $info eq 'HASH';
  return $info->{$value};
}

########## VALIDATION METHODS #################

=head2 validate_as

    Description : wrapper around more specific validators, for easy processing
    Args        : Errors - hash of existing errors
                : Type - validation type
                : Value - value to be checked
                : Match (optional) - a specific value or range to be compared against
    Returntype  : Boolean

=cut

sub validate_as {
  my ($self, $errors, $key, $type, $value, $match) = @_;
  return unless ($type && defined($value));
  my $method = 'validate_as_'.$type;
  if ($self->can($method)) {
    my $error = $self->$method($value, $match);
    $errors->{$key} = $error if $error;    
  }
}

=head2 validate_as_boolean 

    Description : Validator for fields that should contain either 0 or 1
    Args        : Value - value to be checked
    Returntype  : Boolean

=cut

sub validate_as_boolean {
  my ($self, $value) = @_;
  return ($value == 0 || $value == 1) ? undef : "Value $value is not boolean";;
}

=head2 validate_as_string 

    Description : Validator for fields that should contain alphanumeric characters, 
                    punctuation and/or spaces
    Args        : Value - value to be checked
                : Exemplar (optional) - a specific value or range to be compared against
    Returntype  : Boolean

=cut

sub validate_as_string {
  my ($self, $value, $match) = @_;
  my $error;
  if ($match) {
    $error = "String $value does not match $match" unless $value eq $match;
  }
  else {
    $error = "Value $value is not a string" unless $value =~ /[[:print:]]+/;
  }
  return $error;
}

=head2 validate_as_integer 

    Description : Validator for fields that should contain an unsigned integer 
    Args        : Value - value to be checked
    Returntype  : Boolean

=cut

sub validate_as_integer {
  my ($self, $value) = @_;
  return $value =~ /^-?\d+$/ ? undef : "Value $value is not an integer";;
}

=head2 validate_as_floating_point 

    Description : Validator for fields that should contain a floating point number
    Args        : Value - value to be checked
    Returntype  : Boolean

=cut

sub validate_as_floating_point {
  my ($self, $value) = @_;
  return $value =~ /^-?\d+\.?\d*$/ ? undef : "Value $value is not a floating point number";
}

=head2 validate_as_range

    Description : Validator for fields that can contain a range of numerical values
    Args        : Value - value to be checked
                : Match - range to be compared against
    Returntype  : Boolean

=cut

sub validate_as_range {
  my ($self, $value, $match) = @_;
  return undef unless ($match && ref $match eq 'ARRAY');
  my ($min, $max) = @$match;
  return ($value <= $max && $value >= $min) ? undef : "Value $value is not in the range $min - $max";
}

=head2 validate_as_comma_separated

    Description : Validator for fields that should contain alphanumeric strings and commas
                  Note that it is valid for a comma-separated field to end in a comma
    Args        : Value - value to be checked
    Returntype  : Boolean

=cut

sub validate_as_comma_separated {
  my ($self, $value) = @_;
  return $value =~ /^(\w+,?)+$/ ? undef : "Value $value is not comma-separated";
}

=head2 validate_as_case_insensitive 

    Description : Validator for fields that should contain a specific value but can
                    case-insensitive
    Args        : Value - value to be checked
    Returntype  : Boolean

=cut

sub validate_as_case_insensitive {
  my ($self, $value, $match) = @_;
  return undef unless $match;
  return $value =~ /$match/i ? undef : "Value $value does not match $match";
}

=head2 validate_as_strand_integer

    Description : Validator for fields that should contain a strand as 0, 1 or -1
    Args        : Value - value to be checked
    Returntype  : Boolean

=cut

sub validate_as_strand_integer {
  my ($self, $value) = @_;
  return $value =~ /^0|1|-1$/ ? undef : "Value $value is not an integer-formatted strand";
}

=head2 validate_as_strand_plusminus
    Description : Validator for fields that should contain a strand as + or -
    Args        : Type - validation type
                : Value - value to be checked
    Returntype  : Boolean
=cut

sub validate_as_strand_plusminus {
  my ($self, $value) = @_;
  return $value =~ /^\+|-$/ ? undef : "Value $value is not a plus/minus strand";
}

=head2 validate_as_rgb_string

    Description : Validator for fields that should contain an RGB colour as a comma-separated string 
    Args        : Value - value to be checked
    Returntype  : Boolean

=cut

sub validate_as_rgb_string {
  my ($self, $value) = @_;

  ## Technically 0 is not a valid colour, but it's used instead of '.' in some UCSC examples
  return undef if $value eq '0';

  return $value =~ /^(\d){1,3},(\d){1,3},(\d){1,3}$/ ? undef : "Value $value is not an RGB string";
}

=head2 validate_as_colour 

    Description : Validator for fields that should hold a colour, either as RGB, hex or name
    Args        : Value - value to be checked
    Returntype  : Boolean
=cut

sub validate_as_colour {
  my ($self, $value) = @_;

  ## Technically 0 is not a valid colour, but it's used instead of '.' in some UCSC examples
  return undef if $value eq 0;

  ## Try RGB first, as that's most usual
  my $error = $self->validate_as_rgb_string($value);

  ## If not, how about web-friendly hex colours, e.g. #ffcc00?
  if ($error) {
    $error = undef if ($value =~ /^#?[A-Fa-f0-9]{3}/ || $value =~ /^#?[A-Fa-f0-9]{6}/);
  }
  ## Fall back to checking Unix named colours
  if ($error) {
    my $lookup = Bio::EnsEMBL::IO::NamedColours::named_colours;
    $error = $lookup->{$value} ? undef : "Value $value is not a named colour";
  }

  return $error;
}

=head2 validate_as_sequence

    Description : Validator for fields that should contain sequence (DNA, RNA or protein) 
    Args        : Value - value to be checked
    Returntype  : Boolean

=cut

sub validate_as_sequence {
  my ($self, $value) = @_;
  return $value =~ /^[ACDEFGHIKLMNPQRSTUVWY]+$/i ? undef : "Value $value is not nucleic acid or protein sequence";;
}

=head2 validate_as_dna_sequence

    Description : Validator for fields that should contain DNA sequence only 
    Args        : Value - value to be checked
    Returntype  : Boolean

=cut

sub validate_as_dna_sequence {
  my ($self, $value) = @_;
  return $value =~ /^[ACGTN]+$/i ? undef : "Value $value is not DNA sequence";
}

1;
