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

Bio::EnsEMBL::IO::Object::Fasta - Generic object for holding Fasta records

=head1 SYNOPSIS

  use Bio::EnsEMBL::IO::Object::Fasta;

  my $obj = Bio::EnsEMBL::IO::Object::ColumnBasedGeneric->new();

  $obj->sequence('NNNNNNNNNANNNNNNN');
  $obj->header('ENS000001701.1 Prime sequence');

=head1 Description

Object to hold a fasta sequence in a structured way with accessors for
elements, including the id/description header elements.

=cut

package Bio::EnsEMBL::IO::Object::Fasta;

use strict;
use warnings;
use Carp;

use Bio::EnsEMBL::Utils::Argument qw(rearrange);

=head2

Description: Create the fasta object, allowing setting of the header
             and sequence on instantiation.

=cut

sub new {
    my $class = shift;

    my $self = {};

    my($header, $seq) =
	rearrange([qw(HEADER SEQUENCE)], @_);

    if($header) {
	$self->{header} = $header;
    }

    if($seq) {
	$self->{sequence} = $seq;
    }

    $self->{length} = length $seq || 0;

    return bless $self, $class;
}

=head2 sequence

    Description: Setter/getter for sequence

=cut

sub sequence {
    my $self = shift;

    if(@_) {
	$self->{sequence} = shift;
	$self->{length} = length $self->{sequence};
    }
    return $self->{sequence};
}

=head2 seq

    Description: Alias to sequence() for compatibility with other
                 Ensembl modules
=cut

sub seq {
    my $self = shift;

    return $self->sequence(@_);
}

=head2

    Description: Returns length of the stored sequence

=cut

sub length {
    my $self = shift;

    return $self->{length};
}

=head2 subseq

    Description: Returns the sub-sequence for the given coordinates, for
                 compatibility with other Ensembl libraries.

                 Error checking should be performed by the caller to ensure
                 the requested coordinates make sense.

=cut

sub subseq {
    my $self = shift;
    my $start = shift;
    my $end = shift;

    return substr $self->{sequence}, $start, ($end - $start);
}

=head2 header

    Description: Setter/getter for full header

=cut

sub header {
    my $self = shift;

    if(@_) {
	$self->{header} = shift;
    }
    return $self->{header};
}

=head2 id

    Description: Getter for the sequence id, defined as
                 anything up to the first space.
=cut

sub id {
    my $self = shift;

    if($self->{header}) {
	my $index = index $self->{header}, ' ';
	return substr($self->{header}, 0, $index);
    }
}

=head2 display_id

    Description: Alias to header for compatibility with other
                 Ensembl libraries

=cut

sub display_id {
    my $self = shift;

    return $self->header(@_);
}

=head2 description

    Description: Getter for the sequence description, defined as
                 anything after the first space.
=cut

sub description {
    my $self = shift;

    if($self->{header}) {
	my $index = index $self->{header}, ' ';
	return substr($self->{header}, $index+1);
    }
}

sub fields {
    return [qw(sequence header id description)];
}

1;
