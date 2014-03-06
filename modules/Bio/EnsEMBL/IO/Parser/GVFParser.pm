=pod

=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

Bio::EnsEMBL::IO::Parser::GVFParser - A line-based parser devoted to GVF format version 1.06

=cut

=head1 DESCRIPTION

The Genome Variation Format (GVF) specification is available at the following adress:
http://www.sequenceontology.org/resources/gvf.html

=cut

package Bio::EnsEMBL::IO::Parser::GVFParser;

use strict;
use warnings;

use base qw/Bio::EnsEMBL::IO::ColumnBasedParser/;

my %strand_conversion = ( '+' => '1', '.' => undef, '?' => undef, '-' => '-1');
my %attributes;

sub open {
    my ($caller, $filename, $other_args) = @_;
    my $class = ref($caller) || $caller;
    
    my $self = $class->SUPER::open($filename, "\t", $other_args);

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

sub getMetadataKeyList {
  my $self = shift;
  return join(", ",sort(keys(%{$self->{'metadata'}})));
}


=head2 getGVFversion
    Description : Retrieve the GVF format version
    Returntype  : String
=cut

sub getGVFversion {
  my $self = shift;
  return $self->{'metadata'}->{'gvf-version'};
}


=head2 getGenomeBuild
    Description : Retrieve the assembly
    Returntype  : String
=cut

sub getGenomeBuild {
  my $self = shift;
  return $self->{'metadata'}->{'genome-build'};
}

sub getSequenceRegionList {
  my $self = shift;
  return (defined($self->{'metadata'}->{'sequence-region'})) ? $self->{'metadata'}->{'sequence-region'} : [];
}

sub getMetadataByPragma {
  my $self = shift;
  my $pragma = shift;
  return (defined($self->{'metadata'}->{$pragma})) ? $self->{'metadata'}->{$pragma} : undef;
}


# Sequence name

=head2 getRawSeqName
    Description : Return the name of the sequence
    Returntype  : String
=cut

sub getRawSeqName {
    my $self = shift;
    return $self->{'record'}[0];
}


=head2 getSeqName
    Description : Return the name of the sequence
    Returntype  : String
=cut

sub getSeqName {
    my $self = shift;
    return $self->getRawSeqName();
}


# Source name

=head2 getRawSource
    Description : Return the name of the source of the data
    Returntype  : String
=cut

sub getRawSource {
    my $self = shift;
    return $self->{'record'}[1];
}


=head2 getSource
    Description : Return the name of the source of the data
    Returntype  : String
=cut

sub getSource {
    my $self = shift;
    return $self->getRawSource();
}


# Sequence type

=head2 getRawType
    Description : Return the class/type of the feature
    Returntype  : String
=cut

sub getRawType {
  my $self = shift;
  return $self->{'record'}[2];
}


=head2 getType
    Description : Return the class/type of the feature
    Returntype  : String
=cut

sub getType {
    my $self = shift;
    return $self->getRawType();
}


# Sequence start

=head2 getRawStart
    Description : Return the start position of the feature
    Returntype  : Integer
=cut

sub getRawStart {
    my $self = shift;
    return $self->{'record'}[3];
}


=head2 getStart
    Description : Return the start position of the feature
    Returntype  : Integer
=cut

sub getStart {
    my $self = shift;
    return $self->getRawStart();
}


# Sequence end

=head2 getRawEnd
    Description : Return the end position of the feature
    Returntype  : Integer
=cut

sub getRawEnd {
    my $self = shift;
    return $self->{'record'}[4];
}


=head2 getEnd
    Description : Return the end position of the feature
    Returntype  : Integer
=cut

sub getEnd {
    my $self = shift;
    return $self->getRawEnd();
}


# Phred scaled probability that the sequence_alteration call is incorrect (real number)

=head2 getRawScore
    Description : Return the Phred scaled probability that the sequence_alteration call is incorrect (real number)
    Returntype  : Integer
=cut

sub getRawScore {
    my $self = shift;
    return $self->{'record'}[5];
}


=head2 getScore
    Description : Return the Phred scaled probability that the sequence_alteration call is incorrect (real number)
    Returntype  : Integer
=cut

sub getScore {
    my $self = shift;
    my $val = $self->getRawScore();
    return ($val =~ /\./) ? undef : $val;
}


# Sequence strand

=head2 getRawStrand
    Description : Return the strand of the feature
    Returntype  : String
=cut

sub getRawStrand {
    my $self = shift;
    return $self->{'record'}[6];
}


=head2 getStrand
    Description : Return the strand of the feature (1 for the forward strand and -1 for the reverse strand)
    Returntype  : Integer
=cut

sub getStrand {
    my $self = shift;
    my $val = $self->getRawStrand();
    return $strand_conversion{$val};
}


# Phase/Frame

=head2 getRawPhase
    Description : Return the phase/frame of the feature
    Returntype  : String
=cut

sub getRawPhase {
  my $self = shift;
  return $self->{'record'}[7];
}


=head2 getPhase
    Description : Return the phase/frame of the feature
    Returntype  : String
=cut

sub getPhase {
    my $self = shift;
    my $val = $self->getRawPhase();
    return ($val =~ /\./) ? undef : $val;
}


# Attributes
# The methods listed below concern the 9th column data

=head2 getRawAttributes
    Description : Return the content of the 9th column of the line
    Returntype  : String
=cut

sub getRawAttributes {
  my $self = shift;
  return $self->{'record'}[8];
}


=head2 getAttributes
    Description : Return the content of the 9th column of the line in a hash: "attribute => value"
    Returntype  : Reference to a hash
=cut

sub getAttributes {
  my $self = shift;
  return \%attributes if (%attributes);
  foreach my $attr (split(';',$self->getRawAttributes)) {
    my ($key,$value) = split('=',$attr);
    $attributes{$key} = $value;
  }
  return \%attributes;
}


=head2 getID
    Description : Return the identifier of the feature (extracted from the 9th column)
    Returntype  : String
=cut

sub getID {
  my $self = shift;
  my $attr = $self->getAttributes;
  return $attr->{'ID'};
}


=head2 getVariantSeq
    Description : Return the variant sequence of the feature (extracted from the 9th column)
    Returntype  : String
=cut

sub getVariantSeq {
  my $self = shift;
  my $attr = $self->getAttributes;
  return $attr->{'Variant_seq'};
}

=head2 getReferenceSeq
    Description : Return the reference sequence of the feature (extracted from the 9th column)
    Returntype  : String
=cut

sub getReferenceSeq {
  my $self = shift;
  my $attr = $self->getAttributes;
  return $attr->{'Reference_seq'};
}

1;
