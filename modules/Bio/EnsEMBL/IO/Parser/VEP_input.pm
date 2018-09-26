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

Bio::EnsEMBL::IO::Parser::VEP_input - A line-based parser for Ensembl's 
default input format for the Variant Effect Predictor

=cut

package Bio::EnsEMBL::IO::Parser::VEP_input;

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
  $self->{'fields'} = [qw(seqname start end allele strand id)];
}


=head2 get_raw_chromosome

    Description: Getter for chromosome field
    Returntype : String 

=cut

sub get_raw_chromosome {
  my $self = shift;
  return $self->{'record'}[0];
}

=head2 get_seqname

    Description: Getter - wrapper around raw method 
                  (uses standard method name, not format-specific)
    Returntype : String 

=cut

sub get_seqname {
  my $self = shift;
  return $self->get_raw_chromosome();
}

=head2 get_raw_start

    Description: Getter for start field
    Returntype : Integer 

=cut

sub get_raw_start {
  my $self = shift;
  return $self->{'record'}[1];
}

=head2 get_start

    Description: Getter - wrapper around raw_start method
    Returntype : Integer 

=cut

sub get_start {
  my $self = shift;
  return $self->get_raw_start();
}

=head2 get_raw_end

    Description: Getter for end field
    Returntype : Integer

=cut

sub get_raw_end {
  my $self = shift;
  return $self->{'record'}[2];
}

=head2 get_end

    Description: Getter - wrapper around get_raw_end 
    Returntype : String 

=cut

sub get_end {
  my $self = shift;
  return $self->get_raw_end();
}

=head2 get_raw_allele

    Description: Getter for allele field
    Returntype : String 

=cut

sub get_raw_allele {
  my $self = shift;
  return $self->{'record'}[3];
}

=head2 get_allele

    Description: Getter - wrapper around get_raw_allele
    Returntype : String

=cut

sub get_allele {
  my $self = shift;
  return $self->get_raw_allele();
}

=head2 get_raw_strand

    Description: Getter for strand field
    Returntype : String 

=cut

sub get_raw_strand {
  my $self = shift;
  return $self->{'record'}[4];
}

=head2 get_strand

    Description: Getter - wrapper around get_raw_strand
                  Converts text content into integer
    Returntype : Integer (1, 0 or -1)

=cut

sub get_strand {
  my $self = shift;
  my $raw_strand = $self->get_raw_strand;
  $raw_strand = 1 unless defined($raw_strand);
  return defined($self->{'strand_conversion'}{$raw_strand}) ? $self->{'strand_conversion'}{$raw_strand} : $raw_strand;
}

=head2 get_raw_identifier

    Description: Getter for identifier field 
    Returntype : String

=cut

sub get_raw_identifier {
  my $self = shift;
  return $self->{'record'}[5];
}

=head2 get_id

    Description: Getter - wrapper around get_raw_identifier
    Returntype : Integer

=cut

sub get_id {
  my $self = shift;
  return $self->get_raw_identifier();
}

1;
