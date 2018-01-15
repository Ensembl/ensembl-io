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

=cut


=head1 NAME

Bio::EnsEMBL::IO::Parser::VCF4Tabix - A line-based parser devoted to VCF format version 4.2, using the tabix index tool

=cut

=head1 DESCRIPTION

The Variant Call Format (VCF) specification for the version 4.2 is available at the following address:
http://samtools.github.io/hts-specs/VCFv4.2.pdfs
The tabix tool is available at the following address:
https://github.com/samtools/tabix

=cut

package Bio::EnsEMBL::IO::Parser::VCF4Tabix;

use strict;
use warnings;
use Bio::EnsEMBL::IO::TabixParser;
use Bio::EnsEMBL::IO::Parser::BaseVCF4;
use Bio::DB::HTS::Tabix;

use base qw/Bio::EnsEMBL::IO::TabixParser Bio::EnsEMBL::IO::Parser::BaseVCF4/;

sub open {
  my ($caller, $filename, @other_args) = @_;
  my $class = ref($caller) || $caller;

  my $self = $class->SUPER::open($filename, @other_args);

  my $tabix_data = $self->{tabix_file}->header;
  foreach my $line (split("\n",$tabix_data)) {
    $self->Bio::EnsEMBL::IO::Parser::BaseVCF4::read_metadata($line);
  }

  return $self;
}


=head2 read_record
    Description: Splits the current block along predefined delimiters
    Returntype : Void

=cut

sub read_record {
    my $self = shift;
    $self->Bio::EnsEMBL::IO::Parser::BaseVCF4::read_record(@_);
}

sub next {
  my $self = shift;

  # reset the per-record cache
  $self->{_cache} = {};

  return $self->SUPER::next(@_);
}

1;
