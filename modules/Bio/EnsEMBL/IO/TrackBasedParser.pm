=pod

=head1 LICENSE

  Copyright (c) 1999-2013 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

  http://www.ensembl.org/info/about/code_licence.html

=head1 NAME

Bio::EnsEMBL::IO::TrackBasedParser - a parent module for formats that use track/browser lines 

=cut

package Bio::EnsEMBL::IO::TrackBasedParser;

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

1;
