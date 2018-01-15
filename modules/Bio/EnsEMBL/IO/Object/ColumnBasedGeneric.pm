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

Bio::EnsEMBL::IO::Object::ColumnBasedGeneric - Generic object for holding column/field based records

=head1 SYNOPSIS

  use Bio::EnsEMBL::IO::Object::ColumnBasedGeneric;

  $fields = qw/seqname source type start/;
  my $obj = Bio::EnsEMBL::IO::Object::ColumnBasedGeneric->new($fields);

  OR

  use Bio::EnsEMBL::IO::Object::ColumnBasedGeneric;
  use Bio::EnsEMBL::IO::Parser::GFF3;

  my $parser = Bio::EnsEMBL::IO::Parser::GFF3->open('myfile.gff3');
  my $obj = Bio::EnsEMBL::IO::Object::ColumnBasedGeneric->new($parser->get_fields);

  $obj->munrge_seqname('my_seq');

=head1 Description

An object to hold a generic column based format's record as a structure. Allows access to
elements via setters/getters. Setter/getters are dynamically added to the class on instantiation.

=cut

package Bio::EnsEMBL::IO::Object::ColumnBasedGeneric;

use strict;
use warnings;
use Carp;

sub new {
    my ($class, $fields) = @_;

    my $self = {};

    # We need to create accessors needed by the create_record()
    # function in parsers. This is an unfortunately dirty way
    # to do this, the list of accessors creeps larger an a different
    # set of fields is passed in during a subsequent instantiation
    foreach my $field (@$fields) {
	no strict "refs"; 
	# We don't want to redefine functions everytime
	# a new instance is created
	unless(defined *{$field}) {
	    *$field = sub :lvalue {
		my $me = shift;
		$me->{$field} = shift if @_;
		$me->{$field};
	    };
	}

	unless(defined *{"get_$field"}) {
	    *{"get_$field"} = sub {
		my $me = shift;
		$me->{$field};
	    };
	}

	unless(defined *{"munge_$field"}) {
	    *{"munge_$field"} = sub {
		my $me = shift;
		my $value = shift;
		$me->{$field} = $value;
	    };
	}
    }

    bless $self, $class;

    return $self;
}

=head2 create_record

    Description: Serialize the record to it's native format, pieces may
                 need to be overridden by inherited types.

=cut

sub create_record {
    my $self = shift;
    my @values;

    foreach my $field (@{$self->fields}) {
	my $value;
	if(defined($self->$field) && ref $self->$field eq 'HASH') {
	    $value = $self->combine_fields($self->$field);
	} else {
	    $value = $self->$field || '.';
	}

	push @values, $value;
    }

    return $self->concatenate_fields(\@values) . "\n";
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

=head2 length

    Description: If the object has a start and end attribute
                 calculate it's length and return that. Otherwise
                 return undef.

=cut

sub length {
    my $self = shift;

    if($self->can('start') && $self->can('end')) {
	return abs($self->end - $self->start);
    }
}

=head2 combine_fields

    Description: For fields that are composite fields (ie. attributes in
                 GXF), combine the pieces of the field using a delimiter

=cut

sub combine_fields {
    my $self = shift;
    my $values = shift;
    my $delimiter = shift || ';';
    my $inc_field = shift || 1;
    my $separator = shift || '=';
    my $valuequotes = shift || '';

    my @values;

    foreach my $field (keys %$values) {
	push @values, ($inc_field ? "$field$separator" : '') . $valuequotes . $values->{$field} . $valuequotes;
    }

    return join $delimiter, @values;
}

=head2 concatenate_fields

    Description: Put values together to create the final record, may need to
                 be overridden for non-GXF column based formats

=cut

sub concatenate_fields {
    my $self = shift;
    my $values = shift;
    my $delimiter = shift || "\t";

    return join $delimiter, @{$values};
}

1;
