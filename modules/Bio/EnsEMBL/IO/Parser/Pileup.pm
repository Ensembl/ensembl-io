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

Bio::EnsEMBL::IO::Parser::Pileup - A line-based parser for pileup (variant) format 

=cut

### IMPORTANT - this is a work-in-progress and needs extending to fully parse
### the content (possibly using VEP code)

package Bio::EnsEMBL::IO::Parser::Pileup;

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
  $self->{'fields'} = [qw(seqname start ref_base read_number read_bases base_qualities)];
}


=head2 get_raw_seqname

    Description: Getter for seqname field
    Returntype : String 

=cut

sub get_raw_seqname {
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

=head2 get_end

    Description: Getter - pileup is single coordinate so we just use start 
    Returntype : Integer

=cut

sub get_end {
  my $self = shift;
  return $self->get_raw_start();
}

=head2 get_raw_ref_base

    Description: Getter for ref_base (reference base) field
    Returntype : String 

=cut

sub get_raw_ref_base {
  my $self = shift;
  return $self->{'record'}[2];
}

=head2 get_ref_base

    Description: Getter - wrapper around get_raw_ref_base
    Returntype : String

=cut

sub get_ref_base {
  my $self = shift;
  return $self->get_raw_ref_base();
}

=head2 get_raw_read_number

    Description: Getter for read number field
    Returntype : Integer

=cut

sub get_raw_read_number {
  my $self = shift;
  return $self->{'record'}[3];
}

=head2 get_read_number

    Description: Getter - wrapper around get_raw_read_number
    Returntype : Integer

=cut

sub get_read_number {
  my $self = shift;
  return $self->get_raw_read_number;
}

=head2 get_raw_read_bases

    Description: Getter for read_bases field 
    Returntype : String

=cut

sub get_raw_read_bases {
  my $self = shift;
  return $self->{'record'}[4];
}

=head2 get_read_bases

    Description: Getter - wrapper around get_raw_read_bases
    Returntype : String

=cut

sub get_read_bases {
  my $self = shift;
  return $self->get_raw_read_bases();
}

=head2 get_raw_base_qualities

    Description: Getter for base_qualities field 
    Returntype : String

=cut

sub get_raw_base_qualities {
  my $self = shift;
  return $self->{'record'}[5];
}

=head2 get_base_qualities

    Description: Getter - wrapper around get_raw_base_qualities
    Returntype : String

=cut

sub get_base_qualities {
  my $self = shift;
  return $self->get_raw_base_qualities();
}

1;
