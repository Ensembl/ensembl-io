=pod

=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

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
    $self->set_fields;
    $self->set_minimum_column_count;
    $self->set_maximum_column_count;
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
    while (my ($field, $info) = each (%{$format->field_info})) {
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
  chomp $self->{'current_block'};
  $self->{'record'} = [ split($self->{'delimiter'},$self->{'current_block'}) ] ;
}

=head2 validate
    
    Description : Validates a format, using a Format definition if available 
    Returntype  : Boolean

=cut

sub validate {
  my $self = shift;
  my $valid = 0;
  my $count = 0;
  my $record_limit = 1; ## For now, just check first record

  my $format = $self->format;

  if ($format) {
    while ($self->next) {
      next if $self->{'current_block'} !~ /\w/;
      if ($self->is_metadata) {
        $valid = $self->validate_metadata;
      }
      else {
        $valid = $self->validate_record;
        $count++;
        if ($valid == 0) {
          ## Bail out if we hit an invalid record
          return 0;
        }
        elsif ($count == $record_limit) {
          return $valid;
        }
      }
    }
  }
  else {
    $valid = $self->_validate_basic;
  }

  return $valid;
}

=head2 validate_record

  Description : Validate a record based on definitions in the Format object
  Returntype  : Boolean

=cut

sub validate_record {
  my $self = shift;
  my $format = $self->format;
  return 0 unless $format;

  my $field_info  = $format->get_field_info;
  my $field_order = $format->get_field_order;
  my $valid       = 0;

  foreach my $key (@$field_order) {
    my $accessor  = $field_info->{$key}{'accessor'} || $key;
    my $method    = 'get_'.$accessor;
    my $value     = $self->$method;
    my $type      = $field_info->{$key}{'type'};
    my $match     = $field_info->{$key}{'match'};
    $valid        = $format->validate_as($type, $value, $match);
    return 0 if $valid = 0;
  }

  return 1;
}

=head2 _validate_basic 

  Description : Performs basic validation for parsers with no corresponding Format module  
  Returntype  : Boolean

=cut

sub _validate_basic {
  my $self = shift;
  my $valid = 0;

  while ($self->next) {

    next if $self->is_metadata;
    next if $self->{'current_block'} !~ /\w/;

    $self->read_record;

    ## Check we have the minimum number of columns for this format
    my $col_count = scalar(@{$self->{'record'}});

    if ($col_count >= $self->get_minimum_column_count
          && $col_count <= $self->get_maximum_column_count) {
      $valid = 1;
    }
    else {
      $valid = 0;
    }

    if ($self->get_start && $self->get_start =~ /^\d+$/ && $self->get_start > 0 
          && $self->get_end && $self->get_end =~ /^\d+$/) {
      $valid = 1;
    }
    else {
      $valid = 0;
    }

    ## Additional format-specific validation
    if ($self->can('_validate')) {
      $valid = $self->_validate($col_count) ? 1 : 0;
    }

    last;
  }

  ## Finished validating, so return parser to beginning of file
  $self->reset;

  return $valid;
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
