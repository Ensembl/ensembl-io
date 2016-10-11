=pod

=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

Translator::Hash - generic class for accessing the simple data structures used by the new drawing code 

=cut

package Bio::EnsEMBL::IO::Translator::Hash;

use strict;
use warnings;

use Carp;

use base qw/Bio::EnsEMBL::IO::Translator/;

=head2 get_start

    Description: Wrapper around internal call to feature start
    Returntype : Integer

=cut

sub get_start {
  my ($self, $feature) = @_;
  return $feature->{'start'};
}

=head2 get_end

    Description: Wrapper around internal call to feature end
    Returntype : Integer

=cut

sub get_end {
  my ($self, $feature) = @_;
  return $feature->{'end'};
}

=head2 get_name

    Description: Wrapper around internal call to feature name
    Returntype : String

=cut

sub get_name {
  my ($self, $feature) = @_;
  return $feature->{'label'};
}

=head2 get_score

    Description: Wrapper around internal call to feature name
    Returntype : String

=cut

sub get_score {
  my ($self, $feature) = @_;
  return $feature->{'score'};
}

=head2 get_strand

    Description: Wrapper around internal call to feature strand
    Returntype : String

=cut

sub get_strand {
  my ($self, $feature) = @_;
  return $feature->{'strand'};
}

=head2 get_thickStart

    Description: Returns feature start or start of transcribed region
    Returntype : Integer

=cut

sub get_thickStart {
  my ($self, $feature) = @_;
  return $feature->{'start'} unless $feature->{'structure'};
  return $feature->{'structure'}[0]{'start'};
}

=head2 get_thickEnd

    Description: Returns feature end or end of transcribed region 
    Returntype : Integer

=cut

sub get_thickEnd {
  my ($self, $feature) = @_;
  return $feature->{'end'} unless $feature->{'structure'};
  return $feature->{'structure'}[-1]{'end'};
}

=head2 get_itemRgb

    Description: Returns feature colour 
    Returntype : String

=cut

sub get_itemRgb {
  my ($self, $feature) = @_;
  return $feature->{'colour'} || '.'; 
}

=head2 get_blockCount

    Description: Returns details of internal structure of feature, if it has one 
    Returntype : Integer

=cut

sub get_blockCount {
  my ($self, $feature) = @_;
  return scalar @{$feature->{'structure'}||[]};
}

=head2 get_blockStarts

    Description: Returns details of internal structure of feature, if it has one 
    Returntype : String

=cut

sub get_blockStarts {
  my ($self, $feature) = @_;
  return '.' unless $feature->{'structure'};

  my @starts;
  foreach (@{$feature->{'structure'}}) {
    push @starts, $_->{'start'};
  }
  return join(',', @starts);
}

=head2 get_blockSizes

    Description: Returns details of internal structure of feature, if it has one 
    Returntype : String

=cut

sub get_blockStarts {
  my ($self, $feature) = @_;
  return '.' unless $feature->{'structure'};

  my @starts;
  foreach (@{$feature->{'structure'}}) {
    push @starts, ($_->{'end'} - $_->{'start'});
  }
  return join(',', @starts);
}

1;
