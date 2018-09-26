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

Bio::EnsEMBL::IO::Parser::GVF - A line-based parser devoted to GVF format version 1.06

=cut

=head1 DESCRIPTION

The Genome Variation Format (GVF) specification is available at the following adress:
http://www.sequenceontology.org/resources/gvf.html

=cut

package Bio::EnsEMBL::IO::Parser::GVF;

use strict;
use warnings;

use base qw/Bio::EnsEMBL::IO::Parser::GXF/;

sub open {
    my ($caller, $filename, @other_args) = @_;
    my $class = ref($caller) || $caller;
    
    my $self = $class->SUPER::open($filename ,@other_args);

    # pre-load peek buffer
    $self->next_block();
    
    return $self;
}

sub is_metadata {
    my $self = shift;
    return $self->{'current_block'} =~ /^#/;
}

sub read_metadata {
  my $self = shift;
  my $line = $self->{'current_block'};
  
  if ($line =~ /^##\s*(\S+)\s+(.+)$/) {
    my $m_type = $1;
    my $m_data = $2;
    # Can have more than 1 sequence region
    if ($m_type eq "sequence-region") {
      if ($self->{'metadata'}->{$m_type}) {
        push(@{$self->{'metadata'}->{$m_type}}, $m_data);
      }
      else {
        $self->{'metadata'}->{$m_type} = [$m_data];
      }
    }
    else {
      $self->{'metadata'}->{$m_type} = $m_data;
    }
  }
  elsif ($line =~ /^#\s*(.+)$/) {
    my $content = $1;
    if ($self->{'metadata'}->{'other'}) {
      push(@{$self->{'metadata'}->{'other'}},$content);
    }
    else {
      $self->{'metadata'}->{'other'} = [$content];
    }
  }
}


=head2 get_metadata_key_list
    Description : Retrieve the list of metadata keys available as a 
                  string with each term separated by a comma.
    Returntype  : String
=cut

sub get_metadata_key_list {
  my $self = shift;
  return join(", ",sort(keys(%{$self->{'metadata'}})));
}


=head2 get_gvf_version
    Description : Retrieve the GVF format version
    Returntype  : String
=cut

sub get_gvf_version {
  my $self = shift;
  return $self->{'metadata'}->{'gvf-version'};
}


=head2 get_genome_build
    Description : Retrieve the assembly
    Returntype  : String
=cut

sub get_genome_build {
  my $self = shift;
  return $self->{'metadata'}->{'genome-build'};
}


=head2 get_sequence_region_list
    Description : Retrieve the list of metadata with the key (pragma) "sequence-region".
    Returntype  : Reference to an array
=cut

sub get_sequence_region_list {
  my $self = shift;
  return (defined($self->{'metadata'}->{'sequence-region'})) ? $self->{'metadata'}->{'sequence-region'} : [];
}


=head2 get_metadata_by_pragma
    Description : Retrieve the metadata associated with the given key (pragma).
    Returntype  : String or reference to an array (depending on the type of metadata)
=cut

sub get_metadata_by_pragma {
  my $self = shift;
  my $pragma = shift;
  return (defined($self->{'metadata'}->{$pragma})) ? $self->{'metadata'}->{$pragma} : undef;
}


=head2 get_ID
    Description : Return the identifier of the feature (extracted from the 9th column)
    Returntype  : String
=cut

sub get_ID {
  my $self = shift;
  my $attr = $self->get_attributes;
  return $attr->{'ID'};
}


=head2 get_variant_seq
    Description : Return the variant sequence of the feature (extracted from the 9th column)
    Returntype  : String
=cut

sub get_variant_seq {
  my $self = shift;
  my $attr = $self->get_attributes;
  return $attr->{'Variant_seq'};
}

=head2 get_reference_seq
    Description : Return the reference sequence of the feature (extracted from the 9th column)
    Returntype  : String
=cut

sub get_reference_seq {
  my $self = shift;
  my $attr = $self->get_attributes;
  return $attr->{'Reference_seq'};
}

1;
