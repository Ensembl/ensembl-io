=pod

=head1 LICENSE

  Copyright (c) 1999-2013 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

  http://www.ensembl.org/info/about/code_licence.html

=head1 NAME

Bio::EnsEMBL::IO::Parser::BedParser - A line-based parser devoted to BED

=cut

package Bio::EnsEMBL::IO::Parser::BedParser;

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
    if ($self->{'current_block'} =~ /^track/ || $self->{'current_block'} =~ /^browser/) {
      return $self->{'current_block'};
    }
}

sub read_metadata {
    my $self = shift;
    my $line = $self->{'current_block'};
    
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

sub getTrackDescription {
    my $self = shift;
    return $self->{'metadata'}{'description'};
}

sub getTrackPriority {
    my $self = shift;
    return $self->{'metadata'}{'priority'};
}

sub getTrackHeight {
    my $self = shift;
    return $self->{'metadata'}{'height'};
}

sub getUseScore {
    my $self = shift;
    return $self->{'metadata'}{'useScore'};
}

sub getVisibility {
    my $self = shift;
    return $self->{'metadata'}{'visibility'};
}

sub getURL {
    my $self = shift;
    return $self->{'metadata'}{'url'};
}

## -------------- RECORDS -------------------

## ----------- Mandatory fields -------------

sub getRawSeqName {
    my $self = shift;
    return $self->{'record'}[0];
}

sub getSeqName {
    my $self = shift;
    (my $chr = $self->getRawSeqName()) =~ s/^chr//;
    return $chr;
}

sub getRawStart {
    my $self = shift;
    return $self->{'record'}[1];
}

sub getStart {
    my $self = shift;
    ## BED uses semi-open coordinates
    return $self->getRawStart()+1;
}

sub getRawEnd {
    my $self = shift;
    return $self->{'record'}[2];
}

sub getEnd {
    my $self = shift;
    return $self->getRawEnd();
}

## ----------- Optional fields -------------

sub getRawName {
    my $self = shift;
    my $column = $self->getTrackType eq 'bedGraph' ? undef : $self->{'record'}[3];
    return $column;
}

sub getName {
    my $self = shift;
    return $self->getRawName();
}

sub getRawScore {
    my $self = shift;
    my $column = $self->getTrackType eq 'bedGraph' ? 3 : 4;
    return $self->{'record'}[$column];
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

sub getRawStrand {
    my $self = shift;
    return $self->{'record'}[5];
}

my %strand_conversion = ( '+' => '1', '.' => '0', '-' => '-1');

sub getStrand {
    my $self = shift;
    my $val = $self->getRawStrand();
    if ($val =~ /\./) {
        return undef;
    } else {
        return $strand_conversion{$val};
    }
}

sub getRawThickStart {
    my $self = shift;
    return $self->{'record'}[6];
}

sub getThickStart {
    my $self = shift;
    return $self->getRawThickStart();
}

sub getRawThickEnd {
    my $self = shift;
    return $self->{'record'}[7];
}

sub getThickEnd {
    my $self = shift;
    return $self->getRawThickEnd();
}

sub getRawItemRGB {
    my $self = shift;
    return $self->{'record'}[8];
}

sub getItemRGB {
    my $self = shift;
    return $self->getItemRGB();
}

sub getRawBlockCount {
    my $self = shift;
    return $self->{'record'}[9];
}

sub getBlockCount {
    my $self = shift;
    return $self->getRawBlockCount();
}

sub getRawBlockSizes {
    my $self = shift;
    return $self->{'record'}[10];
}

sub getBlockSizes {
    my $self = shift;
    return $self->getRawBlockSizes();
}

sub getRawBlockStarts {
    my $self = shift;
    return $self->{'record'}[11];
}

sub getBlockStarts {
    my $self = shift;
    return $self->getRawBlockStarts();
}


1;
