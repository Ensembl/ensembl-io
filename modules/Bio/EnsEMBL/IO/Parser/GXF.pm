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

Bio::EnsEMBL::IO::Parser::GXF - parent of various related parsers such as GFF and GVF

=cut

package Bio::EnsEMBL::IO::Parser::GXF;

use strict;
use warnings;

use URI::Escape;
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
    
    if ($line =~ /^\s*##(\S+)\s+(.+)/) {
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
  $self->{'fields'} = [qw(seqname source type start end score strand phase attributes)];
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
    my $chr = $self->get_raw_seqname();
    return unless $chr;
    $chr =~ s/^chr//;
    return $chr;
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
    return $val ? $strand_conversion{$val} : undef;
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


=head2 decode_sting
    Argument[1] : $string, string containing encoding like %3B
    Description : Return the decoded string: %2C will be ,
    Returntype  : String
=cut

sub decode_string {
    my ($self, $string) = @_;

    return uri_unescape($string);
}


=head2 encode_string
    Argument[1] : $string, string without encoding like %3B
    Description : Return the uri encoded $string: , will be %2C
    Returntype  : String
=cut

sub encode_string {
    my ($self, $string) = @_;

    return uri_escape($string);
}

1;
