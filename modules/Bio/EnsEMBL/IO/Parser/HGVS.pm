=pod

=head1 LICENSE

  Copyright (c) 1999-2013 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

  http://www.ensembl.org/info/about/code_licence.html

=head1 NAME

Bio::EnsEMBL::IO::Parser::HGVS

=cut

package Bio::EnsEMBL::IO::ListBasedParser::HGVS;

use strict;
use warnings;

use base qw/Bio::EnsEMBL::IO::ListBasedParser/;

=head2 get_raw_feature_id

    Description: Getter for first element of HGVS - seqname or stable id
    Returntype : String

=cut

sub get_raw_feature_id {
  my $self = shift;
  my ($id) = split(':', $self->{'record'});
  return $id;
}

=head2 get_feature_id

    Description: Getter - wrapper around get_raw_feature_id
    Returntype : String

=cut

sub get_feature_id {
  my $self = shift;
  return $self->get_raw_feature_id; 
}

=head2 get_raw_ref_seq_type

    Description: Getter for second element of HGVS - type of reference sequence
    Returntype : String (single lower-case character)

=cut

sub get_raw_ref_seq_type {
  my $self = shift;
  my ($id, $remainder) = split(':', $self->{'record'});
  my ($type) = split('\.', $remainder);
  return $type;
}

=head2 get_ref_seq_type

    Description: Getter - wrapper around get_raw_feature_id
    Returntype : String

=cut

sub get_ref_seq_type {
  my $self = shift;
  return $self->get_raw_ref_seq_type; 
}

=head2 get_raw_variant

    Description: Getter for third element of HGVS - variant notation
    Returntype : String

=cut

sub get_raw_variant {
  my $self = shift;
  my ($id, $remainder) = split(':', $self->{'record'});
  my ($type, $var) = split('\.', $remainder);
  return $var;
}

=head2 get_variant

    Description: Getter - wrapper around get_raw_variant
    Returntype : String

=cut

sub get_variant {
  my $self = shift;
  return $self->get_raw_variant; 
}

1;
