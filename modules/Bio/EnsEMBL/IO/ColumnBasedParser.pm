=pod

=head1 LICENSE

  Copyright (c) 1999-2013 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

  http://www.ensembl.org/info/about/code_licence.html

=head1 NAME

Bio::EnsEMBL::IO::Parser::ColumnBasedParser - An abstract parser class 
specialised for files where a single line constitutes an entire record

=cut

package Bio::EnsEMBL::IO::ColumnBasedParser;

use strict;
use warnings;

use Bio::EnsEMBL::Utils::Exception qw/throw/;

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
    $self->set_fields;
    $self->set_minimum_column_count;
    $self->set_maximum_column_count;
    $self->{'delimiter'} = $delimiter;
    my @delimiters       = split('\|', $delimiter);
    $self->{'default_delimiter'} = $delimiters[0];
    return $self;
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

    Description: Placeholder for user-defined list of fields
    Returntype : Void 

=cut

sub set_fields {
    throw("Method not implemented. This is really important");
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

    Description: Placeholder for user-defined minimum field count (defaults to 1)
    Returntype : Void 

=cut

sub set_minimum_column_count {
    my $self = shift;
    $self->{'min_col_count'} = 1;
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
    
    Description: Performs very basic validation on the content
    Returntype: Boolean

=cut

sub validate {
    my $self = shift;

    my $valid   = 0;

    while ($self->next) {

      next if $self->is_metadata;

      $self->read_record;

      ## Check we have the minimum number of columns for this format
      my $col_count = scalar(@{$self->{'record'}});

      if ($col_count >= $self->get_minimum_column_count
            && $col_count <= $self->get_maximum_column_count) {
        $valid = 1;
      }

      if ($self->start =~ /\d+/ && $self->start > 0 && $self->end =~ /\d+/) {
        $valid = 1;
      }

      ## Additional format-specific validation
      if ($self->_validate) {
        $valid = 1;
      }
      last;
    }

    return $valid;
}

=head2 _validate 

    Description: Stub - most formats will require additional validation
    Returntype: Boolean

=cut

sub _validate {
    my $self = shift;
    return 1;
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
