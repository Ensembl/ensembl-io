=pod

=head1 LICENSE

  Copyright (c) 1999-2013 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

  http://www.ensembl.org/info/about/code_licence.html

=head1 NAME

Bio::EnsEMBL::IO::Parser::WigParser - A line-based parser devoted to WIG

=cut

package Bio::EnsEMBL::IO::Parser::WigParser;

use strict;
use warnings;

use base qw/Bio::EnsEMBL::IO::TrackBasedParser/;

=head2 read_record

    Description: Extends parent method, by keeping a count of records read 
    Returntype : Void 

=cut


sub read_record {
    my $self = shift;
    chomp $self->{'current_block'};
    $self->{'record'} = [ split($self->{'delimiter'},$self->{'current_block'}) ] ;
    $self->{'metadata'}{'featureCount'}++;
}


## --------- FORMAT-SPECIFIC METADATA -----------

sub is_metadata {
    my $self = shift;
    if ($self->{'current_block'} =~ /^track/ 
        || $self->{'current_block'} =~ /^browser/
        || $self->{'current_block'} =~ /^#/ 
        || $self->{'current_block'} =~ /^(fixed|variable)Step/) {
      $self->{'metadata'}{'featureCount'} = 0;
      return $self->{'current_block'};
    }
}

sub getFeatureCount {
    ## Not strictly part of metadata, but we need to keep track of this
    ## in fixed-step tracks to get the start coordinates right
    my $self = shift;
    return $self->{'metadata'}{'featureCount'} || 0;
}

sub getWiggleType {
    my $self = shift;
    return $self->{'metadata'}{'steptype'} || $self->getTrackType;
}

sub getGraphType {
    my $self = shift;
    return $self->{'metadata'}{'graphType'};
}

sub getAutoScale {
    my $self = shift;
    return $self->{'metadata'}{'autoScale'};
}

sub getViewLimits {
    my $self = shift;
    return $self->{'metadata'}{'viewLimits'};
}

sub getStep {
    my $self = shift;
    return $self->{'metadata'}{'step'};
}

sub getSpan {
    my $self = shift;
    return $self->{'metadata'}{'span'};
}

sub getColor {
    my $self = shift;
    return $self->{'metadata'}{'color'};
}

sub getMaxHeightPixels {
    my $self = shift;
    return $self->{'metadata'}{'maxHeightPixels'};
}

## -------------- RECORDS -------------------

## ----------- Mandatory fields -------------

sub getRawSeqName {
    my $self = shift;
    if ($self->getWiggleType =~ /Step/) {
      return $self->{'metadata'}{'chrom'};
    }
    else {
      return $self->{'record'}[0];
    }
}

sub getSeqName {
    my $self = shift;
    (my $chr = $self->getRawSeqName()) =~ s/^chr//;
    return $chr;
}

sub getRawStart {
    my $self = shift;
    if ($self->getWiggleType eq 'fixedStep') {
      return $self->{'metadata'}{'start'};
    }
    elsif ($self->getWiggleType eq 'variableStep') {
      return $self->{'record'}[0];
    }
    else {
      return $self->{'record'}[1];
    }
}

sub getStart {
    my $self = shift;
    if ($self->getWiggleType eq 'variableStep') {
      return $self->getRawStart();
    }
    elsif ($self->getWiggleType eq 'fixedStep') {
      return $self->getRawStart() + $self->getStep() * ($self->getFeatureCount() - 1);
    }
    else {
    ## BED-type format with half-open coordinates
      return $self->getRawStart()+1;
    }
}

sub getRawEnd {
    my $self = shift;
    return $self->{'record'}[2];
}

sub getEnd {
    my $self = shift;
    if ($self->getWiggleType =~ /Step/) {
      my $end = $self->getStart + $self->getSpan - 1;
      return $end;
    }
    else {
      return $self->getRawEnd();
    }
}

sub getRawScore {
    my $self = shift;
    if ($self->getWiggleType eq 'fixedStep') {
      return $self->{'record'}[0];
    }
    elsif ($self->getWiggleType eq 'variableStep') {
      return $self->{'record'}[1];
    } 
    elsif ($self->getWiggleType eq 'bedGraph') {
      return $self->{'record'}[3];
    } 
    else {
      die "Unkown data format\n";
    }
}

sub getScore {
    my $self = shift;
    my $val = $self->getRawScore();
    if ($val =~ /^\.$/) {
            return undef;
    } else {
            return $val;
    }
}

1;
