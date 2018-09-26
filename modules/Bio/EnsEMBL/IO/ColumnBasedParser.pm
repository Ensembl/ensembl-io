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

Bio::EnsEMBL::IO::Parser::ColumnBasedParser - An abstract parser class 
specialised for files where a single line constitutes an entire record

=cut

package Bio::EnsEMBL::IO::ColumnBasedParser;

use strict;
use warnings;

use Carp;

use Bio::EnsEMBL::IO::Object::ColumnBasedGeneric;

use base qw/Bio::EnsEMBL::IO::TextParser/;

our %sub_strings = (
    '\n' => "\n",
    '\t' => "\t",
    #'\s' => "\s",
);

=head2 open

    Constructor
    Argument [1] : Filepath
    Argument [2] : delimiters
    Argument [2+]: Hash of parameters for configuration, e.g. buffer sizes or 
                   specific functions for handling headers or data
    Returntype   : Bio::EnsEMBL::IO::ColumnBasedParser

    Extension of the TextBasedParser that implements read_record.

    If you are extending this class you need to implement:
    - is_metadata: determines whether $self->{current_block} is metadata
    - read_metadata: reads $self->{current_block}, stores relevant data in $self->{metadata} hash ref
    - a bunch of getters.
    
    Optionally, you may want to implement:
    - seek: seeks coordinate in sorted/indexed file

=cut

sub open {
    my ($caller, $filepath, $delimiter, @other_args) = @_;
    my $class = ref($caller) || $caller;
    my $self;

    $self = $class->SUPER::open($filepath, @other_args);
    return unless $self;

    ## Add format object if available
    if ($self->can('add_format')) {
      $self->add_format;
    }
    
    $self->set_fields;
    $self->set_minimum_column_count;
    $self->set_maximum_column_count;
    $self->{'col_count'} = 0;
    $self->{'delimiter'} = $delimiter;
    my @delimiters       = split('\|', $delimiter);
    $self->{'default_delimiter'} = $delimiters[0];
    return $self;
  }

=head2 get_metadata_value

    Argument [1] : Parameter name
    Description: Getter for arbitrary parameter in track line 
    Returntype : String

=cut

sub get_metadata_value {
  my ($self, $key) = @_;
  return $self->{'metadata'}{$key} || '';
}

=head2 get_all_metadata {

    Description: Getter for all metadata
    Returntype : Hashref 

=cut

sub get_all_metadata {
  my $self = shift;
  return $self->{'metadata'} || {};
}

=head2 get_fields

    Description: Getter 
    Returntype : Arrayref

=cut

sub get_fields {
  my $self = shift;
  return $self->{'fields'} || [];
}

=head2 set_fields

    Description: Generic method for setting fields based on format definition (if available) 
    Returntype : Void 

=cut

sub set_fields {
  my $self = shift;
  my $format = $self->format;
  if (!$format) {
    confess("You need to either override this method or create a Format module to provide field definitions. This is really important");
  }

  my $fields = [];
  my $field_info  = $format->get_field_info;
  my $field_order = $format->get_field_order;

  foreach my $name (@$field_order) {
    ## The keys of the field_info hash are the official names from the format specification
    my $field = $field_info->{$name};
    ## however our internal name may be different, so look it up
    my $accessor = $field->{'accessor'} || $name;
    push @$fields, $accessor;
  }

  $self->{'fields'} = $fields;
}

=head2 get_column_count

    Description : Getter
    Returntype  : Integer

=cut

sub get_column_count {
    my $self = shift;
    return $self->{'col_count'};
}

=head2 set_column_count

    Description : Setter
    Returntype  : 

=cut

sub set_column_count {
    my ($self, $count) = @_;
    $count ||= 0;
    $self->{'col_count'} = $count;
}

=head2 get_minimum_column_count

    Description: Getter 
    Returntype : Integer

=cut

sub get_minimum_column_count {
    my $self = shift;
    return $self->{'min_col_count'};
}

=head2 set_minimum_column_count

    Description: Placeholder for user-defined minimum field count (defaults to 1 if no Format module is available)
    Returntype : Void 

=cut

sub set_minimum_column_count {
  my $self = shift;
  my $format = $self->format;

  if ($format) {
    my $count = 0;
    while (my ($field, $info) = each (%{$format->get_field_info||{}})) {
      $count++ if $info->{'optional'} == 0;
    }
  }
  else {
    $self->{'min_col_count'} = 1;
  }
}

=head2 get_maximum_column_count

    Description: Getter 
    Returntype : Integer

=cut

sub get_maximum_column_count {
  my $self = shift;
  return $self->{'max_col_count'};
}

=head2 set_maximum_column_count

    Description: Sets maximum number of fields - defaults to the number of defined fields 
                  but overridden in formats where columns are split to make extra fields
    Returntype : Void 

=cut

sub set_maximum_column_count {
  my $self = shift;
  $self->{'max_col_count'} = scalar(@{$self->{'fields'}});
}


=head2 read_record

    Description: Splits the current block along predefined delimiters
    Returntype : Void 

=cut

sub read_record {
  my $self = shift;
  return [] unless (defined $self->{'current_block'} && defined $self->{'delimiter'});
  chomp $self->{'current_block'};
  $self->{'record'} = [ split($self->{'delimiter'},$self->{'current_block'}) ] ;
}

=head2 validate
    
    Description : Validates a format, using a Format definition if available 
    Returntype  : Boolean

=cut

sub validate {
  my $self = shift;
  my $count = 0;
  my $record_limit = 1; ## For now, just check first record

  my $format = $self->format;

  if ($format) {
    while ($self->next) {

      ## Validate metadata
      next if $self->{'current_block'} !~ /\w/;
      $self->validate_metadata;
      if (keys %{$self->errors}) {
        ## Bail out if we hit an invalid record
        $self->reset;
        return $self->errors;
      }

      ## Now do record
      $self->set_column_count(scalar @{$self->{'record'}});
      $self->validate_record;
      $count++;
      my $errors = $self->errors;
      if (keys %$errors) {
        ## Bail out if we hit an invalid record
        $self->reset;
        return $errors;
      }
      elsif ($count == $record_limit) {
        $self->reset;
        return {};
      }
    }
  }
  else {
    $self->_validate_basic;
  }

  return $self->errors;
}

=head2 validate_metadata

=cut

sub validate_metadata {
  my $self = shift;
  ## Metadata is optional, so default is for it to be valid

  my $metadata; # = $self->metadata;
  if ($metadata) {
    ## TODO - implement validation! 
  }

  return undef;
}

=head2 validate_record

  Description : Validate a record based on definitions in the Format object
  Returntype  : Boolean

=cut

sub validate_record {
  my $self = shift;
  my $format = $self->format;
  return unless $format;

  my $field_info  = $format->get_field_info || {};
  my $field_order = $format->get_field_order || [];

  foreach my $key (@{$field_order}) {
    my $method    = "get_raw_$key";
    my $value     = $self->$method;
    ## Have we come to the end of the record?
    last if ($field_info->{$key}{'optional'} 
            && ! defined $value
            && scalar @{$self->{'record'}} < scalar @$field_order);
    ## Skip other optional fields
    next if ($field_info->{$key}{'optional'} && $value eq ($field_info->{$key}{'placeholder'} || '.'));
    my $type      = $field_info->{$key}{'validate_as'};
    my $match     = $field_info->{$key}{'match'};
    $format->validate_as($self->errors, $key, $type, $value, $match);
  }
}

=head2 _validate_basic 

  Description : Performs basic validation for parsers with no corresponding Format module  
  Returntype  : Boolean

=cut

sub _validate_basic {
  my $self = shift;

  while ($self->next) {

    next if $self->is_metadata;
    next if $self->{'current_block'} !~ /\w/;

    $self->read_record;

    ## Check we have the minimum number of columns for this format
    my $col_count = scalar(@{$self->{'record'}});

    if ($col_count < $self->get_minimum_column_count) {
      $self->{errors}{'columns'} = sprintf 'This format should have at least %s columns', $self->get_minimum_column_count;
      last;
    }
    elsif ($col_count > $self->get_maximum_column_count) {
      $self->{errors}{'columns'} = sprintf 'This format should have no more than %s columns', $self->get_maximum_column_count;
      last;
    }

    my ($start, $end) = ($self->get_start, $self->get_end);
    if (!$start || $start !~ /^\d+$/ || $start < 0) {
      $self->{errors}{'start'} = "Start coordinate $start is absent or invalid";
      last;
    }
    if (!$end || $end !~ /^\d+$/) {
      $self->{errors}{'end'} = "End coordinate $end is absent or invalid";
      last;
    }

    ## Additional format-specific validation
    if ($self->can('_validate')) {
      $self->_validate($col_count);
    }

    last;
  }
  $self->reset;
}

#---------- OUTPUT METHODS --------------

=head2 create_record

    Description: Generic method to create a single record from an object
                  May be overridden in children if format is very flexible! 
    Returntype : String 

=cut

sub create_record {
  my ($self, $translator, $object) = @_;
  my @values;

  foreach my $field (@{$self->get_fields}) {
    my $getter = 'get_'.$field;
    my $munger = 'munge_'.$field;
    my $value;
    if ($self->can($munger) && $translator->can($getter)) {
      $value = $self->$munger($translator->$getter($object)) || '.'; ## Column can't be undef
    }
    elsif ($translator->can($getter)) {
      $value = $translator->$getter($object) || '.'; ## Column can't be undef
    }
    else {
      $value = '.';
    }
    push @values, $value;
  }
  return $self->concatenate_fields(@values);
}

=head2

    Description: Create a generic object for a record with setters and accessors
                 for each column.
    Returntype : Bio::EnsEMBL::IO::Object::ColumnBasedGeneric

=cut

sub create_object {
    my $self = shift;
    my $obj = (@_ ? shift : Bio::EnsEMBL::IO::Object::ColumnBasedGeneric->new($self->get_fields) );

    foreach my $field (@{$self->get_fields}) {
	my $getter = 'get_'.$field;
	my $munger = 'munge_'.$field;
	if ($self->can($getter)) {
	    $obj->$munger($self->$getter);
	}
    }

    # Set the fields for this object
    $obj->fields($self->get_fields);

    return $obj;

}

sub concatenate_fields {
  my ($self, @fields) = @_;
  return unless @fields;

  my $delimiter = $self->{'default_delimiter'};
  my $record = join("$delimiter", @fields);
  ## Fix interpolation of whitespace characters
  $record =~ s/(\\n|\\t|\\s)/$sub_strings{$1}/gs;
  return "$record\n";
}

1;
