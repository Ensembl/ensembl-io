=pod

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

=cut


=head1 NAME

Bio::EnsEMBL::IO::Parser::CADDTabix - A line-based parser for CADD TSV tabix format, using the tabix index tool

=cut

=head1 DESCRIPTION
CADD files are available from https://cadd.gs.washington.edu/download
The tabix tool is available at the following address:
https://github.com/samtools/tabix
=cut

package Bio::EnsEMBL::IO::Parser::CADDTabix;

use strict;
use warnings;
use Bio::EnsEMBL::IO::TabixParser;
use Bio::DB::HTS::Tabix;

use parent qw/Bio::EnsEMBL::IO::TabixParser Bio::EnsEMBL::IO::ColumnBasedParser/;

sub open {
  my ($caller, $filename, @other_args) = @_;
  my $class = ref($caller) || $caller;

  my $delimiter = "\t";
  my $self = $class->SUPER::open($filename, @other_args);

  $self->{delimiter} = "\t";
  return $self;
}

sub next {
  my $self = shift;
  # reset the per-record cache
  $self->{_cache} = {};

  return $self->SUPER::next(@_);
}

=head2 read_record
  Description: Splits the current block along predefined delimiters
  Returntype : Void
=cut

sub read_record {
  my $self = shift;
  $self->Bio::EnsEMBL::IO::ColumnBasedParser::read_record(@_);
}

=head2 get_seqname
  Description : Return the name of the sequence
  Returntype  : String
=cut

sub get_seqname {
  my $self = shift;
  return $self->{'record'}[0];
}

=head2 get_start
  Description : Return the start position
  Returntype  : Integer
=cut

sub get_start {
  my $self = shift;
  return $self->{'record'}[1];
}

=head2 get_reference
  Description : Return the reference allele
  Returntype  : String
=cut

sub get_reference {
  my $self = shift;
  return $self->{'record'}[2];
}

=head2 get_alternative
  Description : Return the alternative allele
  Returntype  : String
=cut

sub get_alternative {
  my $self = shift;
  return $self->{'record'}[3];
}

=head2 get_raw_score
  Description : Return the raw score
  Returntype  : Float
=cut

sub get_raw_score {
  my $self = shift;
  return $self->{'record'}[4];
}

=head2 get_phred_score
  Description : Return the phred score
  Returntype  : Float
=cut

sub get_phred_score {
  my $self = shift;
  return $self->{'record'}[5];
}

1;
