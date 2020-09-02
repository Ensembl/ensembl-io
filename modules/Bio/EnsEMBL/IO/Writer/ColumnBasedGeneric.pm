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

Bio::EnsEMBL::IO::Writer::ColumnBasedGeneric - Generic writer for column based formats

=head1 SYNOPSIS

  The class should not be directly instantiated, but derived to a subclass
  based on the format.

=head1 Description

An object to hold a generic column based format's record as a structure. Allows access to
elements via setters/getters. Setter/getters are dynamically added to the class on instantiation.

=cut

package Bio::EnsEMBL::IO::Writer::ColumnBasedGeneric;

use parent qw/Bio::EnsEMBL::IO::Writer/;

use strict;
use warnings;
use Carp;

=head2 new

    Description: Constructor for a column based generic writer
    Args[1]    : Translator object for the type of object being written 
                 (ie. for Ensembl Features, etc)

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
    Args[2]    : Optional, alternative translator to use for this record

=cut

sub write {
    my $self = shift;
    my $object = shift;
    my $translator = shift;

    # Metadata are a specific case, they are format specific, if
    # you need to translate a feature in to a metadata record (ie. GFF3
    # chromosome list), create a metadata specific translator for that
    if($object->isa('Bio::EnsEMBL::IO::Object::Metadata')) {
	    print { $self->{writer_handle} } $object->create_record();
    } else {
	    # Use the default translator if we haven't been given one
	    $translator ||= $self->translator();
	    print { $self->{writer_handle} } $self->create_record($object, $translator);
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
    my $translator = shift || $self->translator;
    return unless $translator;

    # Maybe... but this would involve looping through the fields twice,
    # perhaps save this for formats like fasta
    my @values = $translator->batch_fields($object, $self->fields());

    return $self->concatenate_fields(\@values), "\n";
    
}

=head2 fields

    Description: Accessor/mutator for fields in record type

=cut

sub fields {
    my $self = shift;

    if(@_) {
	    my $arg = shift;
	    if(ref $arg eq 'ARRAY') {
	      $self->{fields} = $arg;
	    }
    } else {
	    return $self->{'fields'} || [];
    }
}

=head2 combine_fields

    Description: For fields that are composite fields (ie. attributes in
                 GXF), combine the pieces of the field using a delimiter
    Args[1]    : Hashref, values to be combined
    Args[2]    : String, Delimiter between values (optional, default ';')
    Args[3]    : Bool, Include the name of the field when combining values (optional, default true)
    Args[4]    : String, Separator between label and value (optional, default '=')
    Args[5]    : String, Character(s) to quote values with (optional, default '')
    Returntype : String of concatenated fields

=cut

sub combine_fields {
    my $self = shift;
    my $values = shift;
    my $order = shift || undef;
    my $delimiter = shift || ';';
    my $inc_field = shift || 1;
    my $separator = shift || '=';
    my $valuequotes = shift || '';
    my $multi_delimiter = shift || undef;

    my @values;
    my @keys;
    
    if($order) {
	    @keys = @{$order};
    } else {
	    @keys = sort keys %$values;
    }

    foreach my $field (@keys) {
	    next if( !defined($values->{$field}) );

	    if(ref($values->{$field}) eq 'ARRAY') {
	      if($multi_delimiter) {
		      push @values, ($inc_field ? "$field$separator" : '') . join($multi_delimiter, map {qq($valuequotes$_$valuequotes)} @{$values->{$field}});
	      } else {
		      foreach my $v (@{$values->{$field}}) {
		        push @values, ($inc_field ? "$field$separator" : '') . qq($valuequotes$v$valuequotes);
		      }
	      }
	    } elsif (ref($values->{$field}) eq 'HASH'){
                     push @values, $self->combine_fields($values->{$field}, $order, $delimiter, $inc_field, $separator, $valuequotes, $multi_delimiter);
            } else {
	      push @values, ($inc_field ? "$field$separator" : '') . $valuequotes . $values->{$field} . $valuequotes;
	    }
    }

    return join $delimiter, @values;
}

=head2 concatenate_fields

    Description: Put values together to create the final record, may need to
                 be overridden for non-GXF column based formats
    Args[1]    : Arrayref, Values to combine in to string
    Returntype : String

=cut

sub concatenate_fields {
    my $self = shift;
    my $values = shift;
    my $format = $self->format; 
    my @new_values;

    my $delimiter = defined $format?$format->delimiter:"\t";

    foreach (@{$values||[]}) {
      if (defined($_)) {
        if (ref $_ eq 'HASH') {
          push @new_values, $self->combine_fields($_); 
        }
        else {
          push @new_values, $_;
        }
      }
      else {
        push @new_values, $format->empty_column;
      }
    }

    return join $delimiter, @new_values;
}

1;
