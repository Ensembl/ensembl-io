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

Bio::EnsEMBL::IO::Parser::Pairwise - A line-based parser for WashU's paired feature format 

=cut

=head1 DESCRIPTION

The Pairwise file format specification is available at the following address:
http://wiki.wubrowse.org/Long-range

Example:

chr1,713605,715737,-     chr1,720589,722848,-      2
chr1,717172,720090,+     chr1:761197-762811,+      2
chr1,755977,758438,-     chr1:758539-760203,-      2

=cut

package Bio::EnsEMBL::IO::Parser::PairwiseSimple;

use strict;
use warnings;

use base qw/Bio::EnsEMBL::IO::TrackBasedParser/;

sub is_metadata {
    my $self = shift;
    return $self->{'current_block'} =~ /^#/;
}

sub read_metadata {
  ## Stub - format doesn't currently include metadata 
}

=head2 set_fields
    Description: Setter for list of fields used in this format - uses the
                 "public" (i.e. non-raw) names of getter methods
    Returntype : Void
=cut

sub set_fields {
  my $self = shift;
  $self->{'fields'} = [qw(seqname start end information interacting_region score direction)];
}


=head2 set_minimum_column_count

    Description: Sets minimum column count for a valid PAIRWISE file 
    Returntype : Void 

=cut

sub set_minimum_column_count {
    my $self = shift;
    $self->{'min_col_count'} = 3;
}

=head2 set_maximum_column_count

    Description: Sets maximum column count for a valid PAIRWISE file 
    Returntype : Void 

=cut

sub set_maximum_column_count {
    my $self = shift;
    $self->{'max_col_count'} = 3;
}


## PRIVATE METHODS

=head2 get_raw_feature_1
    Description : Return the first feature 
    Returntype  : String
=cut

sub get_raw_feature_1 {
    my $self = shift;
    return $self->{'record'}[0];
}

=head2 get_raw_feature_2
    Description : Return the second feature 
    Returntype  : String
=cut

sub get_raw_feature_2 {
    my $self = shift;
    return $self->{'record'}[1];
}

=head2 get_raw_score
    Description : Return score for this interaction 
    Returntype  : String (number)
=cut

sub get_raw_score {
    my $self = shift;
    return $self->{'record'}[2];
}

=head2 _split_feature
    Description : Splits feature fields on valid separators 
    Returntype  : Array
=cut

sub _split_feature {
  my ($self, $feature) = @_;
  ## Capture a final minus sign (direction) before splitting
  $feature =~ /(-)$/;
  my $direction = $1;
  my @coords = split(/,|-|:/, $feature);
  push @coords, $direction if $direction;
  return @coords;
}

## PUBLIC ACCESSORS

# Sequence name

=head2 get_seqname
    Description : Return the name of the sequence
    Returntype  : String
=cut

sub get_seqname {
    my $self = shift;
    my @feature_info  = $self->_split_feature($self->get_raw_feature_1);
    (my $seqname      = $feature_info[0]) =~ s/chr//;
    return $seqname;
}

# Sequence start

=head2 get_start
    Description : Return the adjusted start position of the feature 
    Returntype  : Integer
=cut

sub get_start {
    my $self = shift;
    my @feature_info  = $self->_split_feature($self->get_raw_feature_1);
    return $feature_info[1]; 
}

# Sequence end

=head2 get_end
    Description : Return the adjusted end position of the feature 
    Returntype  : Integer
=cut

sub get_end {
    my $self = shift;
    my @feature_info  = $self->_split_feature($self->get_raw_feature_1);
    return $feature_info[2]; 
}

=head2 get_information
    Description : Return information about the other member of the pair 
    Returntype  : reference to list
=cut

sub get_information {
    my $self = shift;
    my @info = $self->_split_feature($self->get_raw_feature_2); 
    $info[0] =~ s/chr//;
    return \@info; 
}


=head2 get_interacting_region
    Description : Return the coordinates of the other member of the pair 
    Returntype  : reference to list
=cut

sub get_interacting_region {
    my $self = shift;
    my @info = @{$self->get_information||[]};
    return @info[0..2];
}

=head2 get_direction
    Description : Return the relative direction of the interacting region  
    Returntype  : String
=cut

sub get_direction {
    my $self = shift;
    my @info = $self->_split_feature($self->get_raw_feature_1); 
    return $info[3]; 
}

=head2 get_score
    Description : Return score for this interaction 
    Returntype  : String (number)
=cut

sub get_score {
    my $self = shift;
    return $self->get_raw_score;
}


1;
