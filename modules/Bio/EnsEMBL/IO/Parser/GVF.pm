=pod

=head1 LICENSE

  Copyright (c) 1999-2013 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

  http://www.ensembl.org/info/about/code_licence.html

=head1 NAME

Bio::EnsEMBL::IO::Parser::GFF3 - A line-based parser devoted to GFF3

=cut

package Bio::EnsEMBL::IO::Parser::GVF;

use strict;
use warnings;

use base qw/Bio::EnsEMBL::IO::ColumnBasedParser/;

my %strand_conversion = ( '+' => '1', '.' => undef, '?' => undef, '-' => '-1');
my %attributes;

sub open {
    my ($caller, $filename, @other_args) = @_;
    my $class = ref($caller) || $caller;
    
    my $self = $class->SUPER::open($filename, "\t", @other_args);

    # Metadata defaults
    #if ($self->{'params'}->{'mustReadMetadata'}) {
    #  $self->{'gvf-version'}->{'Type'} = '2';
    #  $self->{'metadata'}->{'Type'} = 'DNA';
    #}

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
        $self->{'metadata'}->{$m_type} = [$m_data]
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

sub getGVFversion {
  my $self = shift;
  return $self->{'metadata'}->{'gvf-version'};
}

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
sub getRawSeqName {
    my $self = shift;
    return $self->{'record'}[0];
}

sub getSeqName {
    my $self = shift;
    return $self->getRawSeqName();
}

# Source name
sub getRawSource {
    my $self = shift;
    return $self->{'record'}[1];
}

sub getSource {
    my $self = shift;
    return $self->getRawSource();
}

# Sequence type
sub getRawType {
  my $self = shift;
  return $self->{'record'}[2];
}

sub getType {
    my $self = shift;
    return $self->getRawType();
}

# Sequence start
sub getRawStart {
    my $self = shift;
    return $self->{'record'}[3];
}

sub getStart {
    my $self = shift;
    return $self->getRawStart();
}

# Sequence end
sub getRawEnd {
    my $self = shift;
    return $self->{'record'}[4];
}

sub getEnd {
    my $self = shift;
    return $self->getRawEnd();
}

# Phred scaled probability that the sequence_alteration call is incorrect (real number)
sub getRawScore {
    my $self = shift;
    return $self->{'record'}[5];
}

sub getScore {
    my $self = shift;
    my $val = $self->getRawScore();
    return ($val =~ /\./) ? undef : $val;
}

# Sequence strand
sub getRawStrand {
    my $self = shift;
    return $self->{'record'}[6];
}

sub getStrand {
    my $self = shift;
    my $val = $self->getRawStrand();
    return $strand_conversion{$val};
}

# Phase/Frame
sub getRawPhase {
  my $self = shift;
  return $self->{'record'}[7];
}

sub getPhase {
    my $self = shift;
    my $val = $self->getRawPhase();
    return ($val =~ /\./) ? undef : $val;
}

# Attributes
# The methods listed below concern the 9th column data
sub getRawAttributes {
  my $self = shift;
  return $self->{'record'}[8];
}

sub getAttributes {
  my $self = shift;
  return \%attributes if (%attributes);
  foreach my $attr (split(';',$self->getRawAttributes)) {
    my ($key,$value) = split('=',$attr);
    $attributes{$key} = $value;
  }
  return \%attributes;
}

sub getID {
  my $self = shift;
  my $attr = $self->getAttributes;
  return $attr->{'ID'};
}

sub getVariantSeq {
  my $self = shift;
  my $attr = $self->getAttributes;
  return $attr->{'Variant_seq'};
}

sub getReferenceSeq {
  my $self = shift;
  my $attr = $self->getAttributes;
  return $attr->{'Reference_seq'};
}

1;
