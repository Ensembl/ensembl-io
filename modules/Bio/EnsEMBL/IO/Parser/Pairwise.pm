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

=cut

package Bio::EnsEMBL::IO::Parser::Pairwise;

use strict;
use warnings;

use base qw/Bio::EnsEMBL::IO::ColumnBasedParser/;

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
  $self->{'fields'} = [qw(seqname start end information interacting_region score id direction)];
}


=head2 set_minimum_column_count

    Description: Sets minimum column count for a valid PAIRWISE file 
    Returntype : Void 

=cut

sub set_minimum_column_count {
    my $self = shift;
    $self->{'min_col_count'} = 5;
}

=head2 set_maximum_column_count

    Description: Sets maximum column count for a valid PAIRWISE file 
    Returntype : Void 

=cut

sub set_maximum_column_count {
    my $self = shift;
    $self->{'max_col_count'} = 6;
}


# Sequence name

=head2 get_raw_seqname
    Description : Return the name of the sequence
    Returntype  : String
=cut

sub get_raw_seqname {
    my $self = shift;
    return $self->{'record'}[0];
}


=head2 get_seqname
    Description : Return the name of the sequence
    Returntype  : String
=cut

sub get_seqname {
    my $self = shift;
    (my $seqname = $self->get_raw_seqname()) =~ s/chr//;
    return $seqname;
}


# Sequence start

=head2 get_raw_start
    Description : Return the start position of the feature
    Returntype  : Integer
=cut

sub get_raw_start {
    my $self = shift;
    return $self->{'record'}[1];
}


=head2 get_start
    Description : Return the adjusted start position of the feature 
    Returntype  : Integer
=cut

sub get_start {
    my $self = shift;
    return $self->get_raw_start();
}


# Sequence end

=head2 get_raw_end
    Description : Return the end position of the feature
    Returntype  : Integer
=cut

sub get_raw_end {
    my $self = shift;
    return $self->{'record'}[2];
}


=head2 get_end
    Description : Return the adjusted end position of the feature 
    Returntype  : Integer
=cut

sub get_end {
    my $self = shift;
    return $self->get_raw_end();
}

=head2 get_raw_information
    Description : Return information about the other member of the pair
    Returntype  : String
=cut

sub get_raw_information {
    my $self = shift;
    return $self->{'record'}[3];
}


=head2 get_information
    Description : Return information about the other member of the pair 
    Returntype  : reference to list
=cut

sub get_information {
    my $self = shift;
    my @info = split(/,|:|-/, $self->get_raw_information());
    $info[0] =~ s/chr//;
    return \@info; 
}


=head2 get_interacting_region
    Description : Return the coordinates of the other member of the pair 
    Returntype  : reference to list
=cut

sub get_interacting_region {
    my $self = shift;
    my $info = $self->get_information;
    return [@$info[0..2]];
}

=head2 get_information
    Description : Return score for this interaction 
    Returntype  : String (number)
=cut

sub get_score {
    my $self = shift;
    my @info = @{$self->get_information};
    if ($info[4]) {
      ## Comma-separated RGB
      return join(',', $info[3..5]);
    }
    else {
      return $info[3];
    }
}

=head2 get_raw_id
    Description : Return the identifier of the feature
    Returntype  : String
=cut

sub get_raw_id {
    my $self = shift;
    return $self->{'record'}[4];
}


=head2 get_id
    Description : Return the identifier(s) of the feature
    Returntype  : reference to list
=cut

sub get_id {
    my $self = shift;
    return $self->get_raw_id();
}


=head2 get_raw_direction
    Description : Return the relative direction of the interacting region 
    Returntype  : String
=cut

sub get_raw_direction {
    my $self = shift;
    return $self->{'record'}[5];
}


=head2 get_direction
    Description : Return the relative direction of the interacting region  
    Returntype  : String
=cut

sub get_direction {
    my $self = shift;
    return $self->get_raw_direction();
}


1;
