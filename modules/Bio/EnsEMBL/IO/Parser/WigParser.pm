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

use base qw/Bio::EnsEMBL::IO::ColumnBasedParser/;

sub open {
    my ($caller, $filename, @other_args) = @_;
    my $class = ref($caller) || $caller;
    
    my $self = $class->SUPER::open($filename, '\t|\s+', @_);

    # pre-load peek buffer
    $self->next_block();
    
    return $self;
}

## --------- METADATA & TRACK LINES -----------

sub is_metadata {
    my $self = shift;
    return ($self->{'current_block'} =~ /^track/ || $self->{'current_block'} =~ /^browser/
        || $self->{'current_block'} =~ /^#/ || $self->{'current_block'} =~ /^[fixed|variable]Step/);
}

sub read_metadata {
    my $self = shift;
    my $line = $self->{'current_block'};
    return unless $line;
    
    if ($line =~ /^browser\s+(\w+)\s+(.*)/i ) {
	    $self->{'metadata'}->{'browser_switches'}{$1} = $2;
    } 
    elsif ($line =~ /^track/) {
      ## Grab any params wrapped in double quotes (to enclose whitespace)
      while ($line =~ s/(\w+)\s*=\s*"(([\\"]|[^"])+?)"//) {
        my $key = $1;
        (my $value = $2) =~ s/\\//g;
        $self->{'metadata'}->{$key} = $value;
      }
      ## Deal with any remaining whitespace-free content
      if ($line) {
        while ($line =~ s/(\w+)\s*=\s*(\S+)//) {
          $self->{'metadata'}->{$1} = $2;
        }
      }
    }  
    elsif ($line =~ /^[fixed|variable]Step/) {
      $line =~ s/^([fixed|variable]Step) //;
      $self->{'metadata'}{'format'} = $1;
      while ($line =~ s/(\w+)\s*=\s*(\S+)//) {
        $self->{'metadata'}->{$1} = $2;
      }
    }
}

sub getBrowserSwitches {
    my $self = shift;
    return $self->{'metadata'}{'browser_switches'} || {};
}

sub getTrackName {
    my $self = shift;
    return $self->{'metadata'}{'name'};
}

sub getTrackType {
    my $self = shift;
    return $self->{'metadata'}{'type'};
}

sub getGraphType {
    my $self = shift;
    return $self->{'metadata'}{'graphType'};
}

sub getTrackDescription {
    my $self = shift;
    return $self->{'metadata'}{'description'};
}

sub getTrackPriority {
    my $self = shift;
    return $self->{'metadata'}{'priority'};
}

sub getAutoScale {
    my $self = shift;
    return $self->{'metadata'}{'autoScale'};
}

sub getViewLimits {
    my $self = shift;
    return $self->{'metadata'}{'viewLimits'};
}

sub getVisibility {
    my $self = shift;
    return $self->{'metadata'}{'visibility'};
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
    if ($self->{'metadata'}{'format'} =~ /Step/) {
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
    if ($self->{'metadata'}{'format'} eq 'fixedStep') {
      return $self->{'metadata'}{'start'};
    }
    elsif ($self->{'metadata'}{'format'} eq 'variableStep') {
      return $self->{'record'}[0];
    }
    else {
      return $self->{'record'}[1];
    }
}

sub getStart {
    my $self = shift;
    if ($self->{'metadata'}{'type'} =~ /Step/) {
      return $self->getRawStart();
    }
    else {
    ## BED-type format with half-open coordinates
      return $self->getRawStart()+1;
    }
}

sub getRawEnd {
    my $self = shift;
    if ($self->{'metadata'}{'format'} =~ /Step/) {
      my $end = $self->getStart + $self->getSpan;
      return $end;
    }
    else {
      return $self->{'record'}[2];
    }
}

sub getEnd {
    my $self = shift;
    return $self->getRawEnd();
}

sub getRawScore {
    my $self = shift;
    if ($self->{'metadata'}{'format'} eq 'fixedStep') {
      return $self->{'record'}[0];
    }
    elsif ($self->{'metadata'}{'format'} eq 'variableStep') {
      return $self->{'record'}[1];
    }
    else {
      return $self->{'record'}[3];
    }
}

sub getScore {
    my $self = shift;
    my $val = $self->getRawScore();
    if ($val =~ /\./) {
            return undef;
    } else {
            return $val;
    }
}


1;
