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

Bio::EnsEMBL::IO::Parser::GFF3 - A line-based parser devoted to GFF3

=cut

package Bio::EnsEMBL::IO::Parser::GFF3;

use strict;
use warnings;

use Bio::EnsEMBL::IO::Parser::Fasta;

use base qw/Bio::EnsEMBL::IO::Parser::GXF/;

sub open {
    my ($caller, $filename, @other_args) = @_;
    my $class = ref($caller) || $caller;

    my $self = $class->SUPER::open($filename, @other_args);

    # Metadata defaults
    if ($self->{'params'}->{'must_parse_metadata'}) {
       $self->{'metadata'}->{'gff-version'} = '3';
       $self->{'metadata'}->{'Type'} = 'DNA';
    }

    # Default we haven't reached the ##FASTA block
    $self->{'FASTA_found'} = 0;
    $self->{FASTA_read} = 0;

    # pre-load peek buffer
    $self->next_block();

    return $self;
}

sub read_block {
    my $self = shift;

    # Fetch the next line unless we've
    # entered the ##FASTA section of the file
    $self->SUPER::read_block()
	unless( $self->{'FASTA_found'} );

    # See if we've found the ##FASTA block, if so
    # remember and signal the file is finished reading
    # (for this section at least)
    if($self->{'waiting_block'}) {
	if( $self->{'waiting_block'} =~ /\#\#FASTA/ ) {
	    $self->{'waiting_block'} = undef;
	    $self->{'FASTA_found'} = 1;

	    # And pass it off to the Fasta parser...
	    $self->{'FASTA_handle'} = Bio::EnsEMBL::IO::Parser::Fasta->open( $self->{'filehandle'} );
	}
    }

    return $self->{'waiting_block'};
}

=head2 next_sequence

    Description: Read the next sequence from the ##FASTA section of the GFF,
                 only possible after you've cycled through all the line
                 based records with next() until false is returned.
    Returntype:  scalar

=cut

sub next_sequence {
    my $self = shift;

    # We're not in Fasta mode yet or none was found.
    return 0
	unless( $self->in_fasta_mode() );

    # Remember we've now read a fasta sequence
    $self->{FASTA_read} = 1;

    # Pass over to the Fasta parser if we have
    # any sequences in the remaining file
    return $self->{'FASTA_handle'}->next();

}

=head2 in_fasta_mode

    Description: Return if the parser has reached the ##FASTA section,
                 if it exists
    Returntype: scalar

=cut

sub in_fasta_mode {
    my $self = shift;

    return $self->{'FASTA_found'} && defined($self->{'FASTA_handle'})
}

sub read_metadata {
    my $self = shift;
    my $line = $self->{'current_block'};

    if ($line =~ /^\s*##(\S+)\s+(.+)/) {
        $self->{'metadata'}->{$1} = $2;
    }
    elsif ($line =~ /^#/ and $line !~ /^#\s*$/) {
        chomp $line;
        push(@{$self->{metadata}->{comments}}, $line);
    }
}

=head2 set_minimum_column_count

    Description: Sets minimum column count for a valid GFF file
    Returntype : Void

=cut

sub set_minimum_column_count {
    my $self = shift;
    $self->{'min_col_count'} = 5;
}

=head2 get_source
    Description : Return the name of the source of the data
    Returntype  : String
=cut

sub get_source {
    my $self = shift;
    return $self->decode_string($self->get_raw_source());
}

=head2 get_type
    Description : Return the class/type of the feature
    Returntype  : String
=cut

sub get_type {
    my $self = shift;
    return $self->decode_string($self->get_raw_type());
}

=head2 get_attribute_by_name
    Argument[1] : $name, name of the attribute
    Description : Return the value for attribute $name
                  If you want to use several attributes, use $self->get_attributes,
                  which returns a hashref where the key are the attribute names
    Returntype  : String
=cut

sub get_attribute_by_name {
    my ($self, $name) = @_;

    # We're looking at beginning of line or ';', then getting the attribute value.
    # We hope that people don't use the same attribute multiple times
    # This implementation is either very smart or pretty bad...
    my (undef, $value) = $self->get_raw_attributes =~ /(\A|;)$name=([^;]+)/;
    # If $value is not undef, return decoded $value
    return $value ? $self->decode_string($value) : $value;
}

=head2 get_attributes
    Description : Return the content of the 9th column of the line in a hash: "attribute => value"
    Returntype  : Reference to a hash
=cut

sub get_attributes {
  my $self = shift;
  my %attributes;
  foreach my $attr (split(';',$self->get_raw_attributes)) {
    my ($key,$value) = split('=',$attr);
    $attributes{$key} = $value;
  }
  return \%attributes;
}

=head2 create_object

    Description: Create an object encapsulation for the record, for the
                 column based record if in the first half of the gff3 file
                 or defer to the embedded fasta parser if we're in the
                 fasta section of the file.
    Returntype : Bio::EnsEMBL::IO::Object::ColumnBasedGeneric or
                 Bio::EnsEMBL::IO::Object::Fasta
=cut

sub create_object {
    my $self = shift;

    if( $self->in_fasta_mode() && $self->{FASTA_read} ) {
	return $self->{'FASTA_handle'}->create_object();
    }

    return $self->SUPER::create_object();
}

## Passthru functions for the embedded Fasta within a GFF3, yuck

sub getRawHeader {
    my $self = shift;

    return 0
	unless( $self->in_fasta_mode() );

    return $self->{'FASTA_handle'}->getRawHeader();
}

sub getHeader {
    my $self = shift;

    return 0
	unless( $self->in_fasta_mode() );

    return $self->{'FASTA_handle'}->getHeader();
}

sub getRawSequence {
    my $self = shift;

    return 0
	unless( $self->in_fasta_mode() );

    return $self->{'FASTA_handle'}->getRawSequence();
}

sub getSequence {
    my $self = shift;

    return 0
	unless( $self->in_fasta_mode() );

    return $self->{'FASTA_handle'}->getSequence();
}


# NOT FULLY IMPLEMENTED

=head2 fasta_record

  Arg [1]    : listref taking the form [$meta_line,$sequence]
  Description: Getter/setter for FASTA found within a GFF3 file. The richer
               capabilities of the FASTA parser are ignored because using FASTA
               within a GFF file is horrid and hard to handle automatically.
               It accumulates or dispenses FASTA records until it runs out.
  Example    : $parser->fasta_record([$header,$seq]);
               $parser->fasta_record([$header2,$seq2]);
               while ($parser->fasta_record) {
                   ....
               }
  Returntype : Listref of Strings, consisting of header and sequence

=cut

sub fasta_record {
    my $self = shift;
    my $fasta_array = shift;
    my ($meta,$seq) = ($fasta_array->[0],$fasta_array->[1]);
    if ($seq) {
        push @{ $self->{'fasta'} },[$meta,$seq];
    } else {
        my $fasta = $self->{'fasta'};
        return shift @$fasta;
    }
}

1;
