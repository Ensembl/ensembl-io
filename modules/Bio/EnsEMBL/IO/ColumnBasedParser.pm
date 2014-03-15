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

=cut

sub open {
    my ($caller, $filepath, $delimiter, @other_args) = @_;
    my $class = ref($caller) || $caller;
    my $self;

    $self = $class->SUPER::open($filepath, @other_args);
    $self->{'fields'}    = $self->set_fields;
    $self->{'delimiter'} = $delimiter;
    my @delimiters       = split('\|', $delimiter);
    $self->{'default_delimiter'} = $delimiters[0];
    return $self;
}

=head2 fields

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


=head2 read_record

    Description: Splits the current block along predefined delimiters
    Returntype : Void 

=cut


sub read_record {
    my $self = shift;
    chomp $self->{'current_block'};
    $self->{'record'} = [ split($self->{'delimiter'},$self->{'current_block'}) ] ;
}

#---------- OUTPUT METHODS --------------

=head2 create_record

    Description: Generic method to create a single record from an object
                  Can be overridden in children for efficiency 
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
