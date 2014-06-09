=pod

=head1 LICENSE

  Copyright (c) 1999-2013 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

  http://www.ensembl.org/info/about/code_licence.html

=head1 NAME

Bio::EnsEMBL::IO::Parser::VEP_output - A line-based parser for Ensembl's 
output format for the Variant Effect Predictor

=cut

package Bio::EnsEMBL::IO::Parser::VEP_output;

use strict;
use warnings;

use base qw/Bio::EnsEMBL::IO::ColumnBasedParser/;
=head2 open

    Constructor
    Argument [1] : Filepath
    Argument [2+]: Hash of parameters for configuration, e.g. buffer sizes or 
                   specific functions for handling headers or data
    Returntype   : Bio::EnsEMBL::IO::TrackBasedParser

=cut

sub open {
    my ($caller, $filename, @other_args) = @_;
    my $class = ref($caller) || $caller;
    my $self;

    $self = $class->SUPER::open($filename, '\t|\s+', @other_args);

    if ($filename) {
      # pre-load peek buffer
      $self->next_block();
    }

    return $self;
}

## This format has no metadata

sub is_metadata { return undef; }

sub read_metadata { return undef; }

=head2 set_fields

    Description: Setter for list of fields used in this format - uses the
                  "public" (i.e. non-raw) names of getter methods
    Returntype : Void

=cut

sub set_fields {
  my $self = shift;
  $self->{'fields'} = [qw(uploaded_variation location allele gene feature feature_type consequence cdna_position cds_position protein_position aa_change codon_change colocated extra)];
}


=head2 get_raw_uploaded_variation

    Description: Getter for uploaded_variation field
    Returntype : String 

=cut

sub get_raw_uploaded_variation {
  my $self = shift;
  return $self->{'record'}[0];
}

=head2 get_uploaded_variation

    Description: Getter - wrapper around raw method 
    Returntype : String 

=cut

sub get_uploaded_variation {
  my $self = shift;
  return $self->get_raw_uploaded_variation();
}


=head2 get_raw_location

    Description: Getter for  field
    Returntype : String 

=cut

sub get_raw_location {
  my $self = shift;
  return $self->{'record'}[1];
}

=head2 get_seqname

    Description: Getter - munges data from raw_location method 
    Returntype : String 

=cut

sub get_seqname {
  my $self = shift;
  my ($seqname) = split(':', $self->get_raw_location());
  return $seqname;
}

=head2 get_start

    Description: Getter - munges data from raw_location method 
    Returntype : Integer 

=cut

sub get_start {
  my $self = shift;
  my ($seqname, $coords) = split(':', $self->get_raw_location());
  my ($start, $end) = split('-', $coords);
  return $start;
}

=head2 get_end

    Description: Getter - munges data from raw_location method
    Returntype : Integer 

=cut

sub get_end {
  my $self = shift;
  my ($seqname, $coords) = split(':', $self->get_raw_location());
  my ($start, $end) = split('-', $coords);
  return $end || $start;
}

=head2 get_raw_allele

    Description: Getter for allele field
    Returntype : String 

=cut

sub get_raw_allele {
  my $self = shift;
  return $self->{'record'}[2];
}

=head2 get_allele

    Description: Getter - wrapper around get_raw_allele
    Returntype : String

=cut

sub get_allele {
  my $self = shift;
  return $self->get_raw_allele();
}

=head2 get_raw_gene

    Description: Getter for  field
    Returntype : String (stable ID) 

=cut

sub get_raw_gene {
  my $self = shift;
  return $self->{'record'}[3];
}

=head2 get_gene

    Description: Getter - wrapper around raw method 
    Returntype : String 

=cut

sub get_gene {
  my $self = shift;
  return $self->get_raw_gene();
}

=head2 get_raw_feature

    Description: Getter for feature field
    Returntype : String (stable id)

=cut

sub get_raw_feature {
  my $self = shift;
  return $self->{'record'}[4];
}

=head2 get_feature

    Description: Getter - wrapper around raw method 
    Returntype : String 

=cut

sub get_feature {
  my $self = shift;
  return $self->get_raw_feature();
}

=head2 get_raw_feature_type

    Description: Getter for feature_type field
    Returntype : String 

=cut

sub get_raw_feature_type {
  my $self = shift;
  return $self->{'record'}[5];
}

=head2 get_feature_type

    Description: Getter - wrapper around raw method 
    Returntype : String 

=cut

sub get_feature_type {
  my $self = shift;
  return $self->get_raw_feature_type();
}

=head2 get_raw_consequence

    Description: Getter for consequence field
    Returntype : String 

=cut

sub get_raw_consequence {
  my $self = shift;
  return $self->{'record'}[6];
}

=head2 get_consequence

    Description: Getter - wrapper around raw method 
    Returntype : String 

=cut

sub get_consequence {
  my $self = shift;
  return $self->get_raw_consequence();
}

=head2 get_raw_cdna_position

    Description: Getter for cdna_position field
    Returntype : Integer

=cut

sub get_raw_cdna_position {
  my $self = shift;
  return $self->{'record'}[7];
}

=head2 get_cdna_position

    Description: Getter - wrapper around raw method 
    Returntype : Integer

=cut

sub get_cdna_position {
  my $self = shift;
  return $self->get_raw_cdna_position();
}

=head2 get_raw_cds_position

    Description: Getter for cds_position field
    Returntype : Integer

=cut

sub get_raw_cds_position {
  my $self = shift;
  return $self->{'record'}[8];
}

=head2 get_cds_position

    Description: Getter - wrapper around raw method 
    Returntype : Integer 

=cut

sub get_cds_position {
  my $self = shift;
  return $self->get_raw_cds_position();
}

=head2 get_raw_protein_position

    Description: Getter for protein_position field
    Returntype : Integer

=cut

sub get_raw_protein_position {
  my $self = shift;
  return $self->{'record'}[9];
}

=head2 get_protein_position

    Description: Getter - wrapper around raw method 
    Returntype : Integer

=cut

sub get_protein_position {
  my $self = shift;
  return $self->get_raw_protein_position();
}

=head2 get_raw_aa_change

    Description: Getter for aa_change field
    Returntype : String 

=cut

sub get_raw_aa_change {
  my $self = shift;
  return $self->{'record'}[10];
}

=head2 get_aa_change

    Description: Getter - wrapper around raw method 
    Returntype : String 

=cut

sub get_aa_change {
  my $self = shift;
  return $self->get_raw_aa_change();
}

=head2 get_raw_codon_change

    Description: Getter for codon_change field
    Returntype : String 

=cut

sub get_raw_codon_change {
  my $self = shift;
  return $self->{'record'}[11];
}

=head2 get_codon_change

    Description: Getter - wrapper around raw method 
    Returntype : String 

=cut

sub get_codon_change {
  my $self = shift;
  return $self->get_raw_codon_change();
}

=head2 get_raw_colocated

    Description: Getter for colocated field
    Returntype : String 

=cut

sub get_raw_colocated {
  my $self = shift;
  return $self->{'record'}[12];
}

=head2 get_colocated

    Description: Getter - wrapper around raw method 
    Returntype : String 

=cut

sub get_colocated {
  my $self = shift;
  return $self->get_raw_colocated();
}

=head2 get_raw_extra

    Description: Getter for  field
    Returntype : String 

=cut

sub get_raw_extra {
  my $self = shift;
  return $self->{'record'}[13];
}

=head2 get_extra

    Description: Getter - wrapper around raw method 
    Returntype : Hashref 

=cut

sub get_extra {
  my $self = shift;
  my $raw_extra = $self->get_raw_extra();
  my $extra = {};
  my @A = split(';', $raw_extra);
  foreach (@A) {
    my ($k, $v) = split('=', $_);
    $extra->{$k} = $v;
  }
  return $extra;
}


1;
