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

Bio::EnsEMBL::IO::Parser::Coords - A line-based parser devoted to a
simple list of coordinates in format seq_region_name:start-end, used
by some web tools such as the Assembly Converter

=cut

package Bio::EnsEMBL::IO::Parser::Coords;

use strict;
use warnings;
no warnings 'uninitialized';

use base qw/Bio::EnsEMBL::IO::ListBasedParser/;


=head2 get_coords

    Description : Getter - splits coordinates field into seqname, start, end
    
    Returntype  : Arrayref
=cut 

sub get_coords {
  my $self = shift;
  my @coords = split(/-|:/, $self->get_raw_value);
  return [] unless scalar @coords;
  $coords[0] =~ s/^chr//;
  return \@coords;
}

=head2 get_seqname

    Description: Getter - wrapper around get_coords 
    Returntype : String 

=cut

sub get_seqname {
  my $self = shift;
  my $coords = $self->get_coords;
  return $coords->[0];
}

=head2 get_start

    Description: Getter - wrapper around get_coords 
    Returntype : Integer 

=cut

sub get_start {
  my $self = shift;
  my $coords = $self->get_coords;
  return $coords->[1];
}

=head2 get_end

    Description: Getter - wrapper around get_coords 
    Returntype : Integer

=cut

sub get_end {
  my $self = shift;
  my $coords = $self->get_coords;
  return $coords->[2];
}


1;
