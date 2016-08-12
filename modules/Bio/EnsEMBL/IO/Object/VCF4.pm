=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

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

Bio::EnsEMBL::IO::Object::VCF4 - Generic object for holding VCF4 based records

=head1 SYNOPSIS

  use Bio::EnsEMBL::IO::Object::VCF4;
  use Bio::EnsEMBL::IO::Parser::VCF4;

  my $parser = Bio::EnsEMBL::IO::Parser::VCF4->open('myfile.gff3');
  my $obj = Bio::EnsEMBL::IO::Object::VCF4->new($parser->get_fields);

=head1 Description

An object derived from ColumnBasedGeneric with a specialized create_record to properly
format the record as VCF4.

=cut

package Bio::EnsEMBL::IO::Object::VCF4;

use base qw/Bio::EnsEMBL::IO::Object::ColumnBasedGeneric/;

use strict;
use warnings;
use Carp;

my @FIELDS = qw(CHROM POS ID REF ALT QUAL FILTER INFO FORMAT);

=head2 fields

  Description: Access the fields for a VCF4 type record
  Returntype : Array of fields

=cut

sub fields {
  my $self = shift;
  
  my @fields = map { lc($_)} @FIELDS;

  return \@fields;
}

1;
