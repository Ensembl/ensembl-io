=pod

=head1 LICENSE

  Copyright (c) 1999-2013 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

  http://www.ensembl.org/info/about/code_licence.html

=head1 NAME

Bio::EnsEMBL::IO::Parser::GFF3 - A line-based parser devoted to GFF3

=cut

package Bio::EnsEMBL::IO::Parser::GXF;

use strict;
use warnings;

use HTML::Entities;
use base qw/Bio::EnsEMBL::IO::ColumnBasedParser/;

my %strand_conversion = ('+' => '1', '-' => '-1', '.' => undef, '?' => undef);

sub open {
    my ($caller, $filename, @other_args) = @_;
    my $class = ref($caller) || $caller;
    
    my $self = $class->SUPER::open($filename, '\t', @other_args);

    return $self;
}

sub is_metadata {
    my $self = shift;
    return $self->{'current_block'} =~ /^#/;
}

sub read_metadata {
    my $self = shift;
    my $line = $self->{'current_block'};
    
    if ($line =~ /^\s*##(\S+)\s+(\S+)/) {
        $self->{'metadata'}->{$1} = $2;
    }
}


=head2 set_fields
    Description: Setter for list of fields used in this format - uses the
                 "public" (i.e. non-raw) names of getter methods
    Returntype : Void
=cut

sub set_fields {
  my $self = shift;
  $self->{'fields'} = [qw(seqname source type start end score strand attributes)];
}


=head2 get_raw_seqname
    Description : Return the name of the sequence
    Returntype  : String
=cut

sub get_raw_seqname {
    my $self = shift;
    return $self->{'record'}[0];
}


=head2 get_seqname
    Description : Return the name of the sequence
    Returntype  : String
=cut

sub get_seqname {
    my $self = shift;
    return $self->get_raw_seqname();
}


# Source name

=head2 get_raw_source
    Description : Return the name of the source of the data
    Returntype  : String
=cut

sub get_raw_source {
    my $self = shift;
    return $self->{'record'}[1];
}


=head2 get_source
    Description : Return the name of the source of the data
    Returntype  : String
=cut

sub get_source {
    my $self = shift;
    return $self->get_raw_source();
}


# Sequence type

=head2 get_raw_type
    Description : Return the class/type of the feature
    Returntype  : String
=cut

sub get_raw_type {
  my $self = shift;
  return $self->{'record'}[2];
}


=head2 get_type
    Description : Return the class/type of the feature
    Returntype  : String
=cut

sub get_type {
    my $self = shift;
    return $self->get_raw_type();
}


# Sequence start

=head2 get_raw_start
    Description : Return the start position of the feature
    Returntype  : Integer
=cut

sub get_raw_start {
    my $self = shift;
    return $self->{'record'}[3];
}


=head2 get_start
    Description : Return the start position of the feature
    Returntype  : Integer
=cut

sub get_start {
    my $self = shift;
    return $self->get_raw_start();
}


# Sequence end

=head2 get_raw_end
    Description : Return the end position of the feature
    Returntype  : Integer
=cut

sub get_raw_end {
    my $self = shift;
    return $self->{'record'}[4];
}


=head2 get_end
    Description : Return the end position of the feature
    Returntype  : Integer
=cut

sub get_end {
    my $self = shift;
    return $self->get_raw_end();
}


# Phred scaled probability that the sequence_alteration call is incorrect (real number)

=head2 get_raw_score
    Description : Return the Phred scaled probability that the sequence_alteration call is incorrect (real number)
    Returntype  : Integer
=cut

sub get_raw_score {
    my $self = shift;
    return $self->{'record'}[5];
}


=head2 get_score
    Description : Return the Phred scaled probability that the sequence_alteration call is incorrect (real number)
    Returntype  : Integer
=cut

sub get_score {
    my $self = shift;
    my $val = $self->get_raw_score();
    return ($val =~ /\./) ? undef : $val;
}


# Sequence strand

=head2 get_raw_strand
    Description : Return the strand of the feature
    Returntype  : String
=cut

sub get_raw_strand {
    my $self = shift;
    return $self->{'record'}[6];
}


=head2 get_strand
    Description : Return the strand of the feature (1 for the forward strand and -1 for the reverse strand)
    Returntype  : Integer
=cut

sub get_strand {
    my $self = shift;
    my $val = $self->get_raw_strand();
    return $strand_conversion{$val};
}


# Phase/Frame

=head2 get_raw_phase
    Description : Return the phase/frame of the feature
    Returntype  : String
=cut

sub get_raw_phase {
  my $self = shift;
  return $self->{'record'}[7];
}


=head2 get_phase
    Description : Return the phase/frame of the feature
    Returntype  : String
=cut

sub get_phase {
    my $self = shift;
    my $val = $self->get_raw_phase();
    return ($val =~ /\./) ? undef : $val;
}


# Attributes
# The methods listed below concern the 9th column data

=head2 get_raw_attributes
    Description : Return the content of the 9th column of the line
    Returntype  : String
=cut

sub get_raw_attributes {
  my $self = shift;
  return $self->{'record'}[8];
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


=head2 decode_html
    Argument[1] : $string, string containing html encoding like %3B
    Description : Return the html decoded $string
    Returntype  : String
=cut

sub decode_html {
    my ($self, $string) = @_;

    return decode_entities($string);
}

1;
