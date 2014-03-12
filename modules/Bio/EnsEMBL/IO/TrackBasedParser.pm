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

=head2 open

    Constructor
    Argument [1] : Filepath
    Argument [2+]: Hash of parameters for configuration, e.g. buffer sizes or 
                   specific functions for handling headers or data
    Returntype   : Bio::EnsEMBL::IO::TrackBasedParser

=cut

sub open {
    my ($caller, $filename, @other_args) = @_;
    my $class = ref($caller) || $caller;
    
    my $self = $class->SUPER::open($filename, '\t|\s+', @other_args);

    # pre-load peek buffer
    $self->next_block();
    
    return $self;
}

## --------- METADATA & TRACK LINES -----------

=head2 is_metadata

    Description: Identifies track lines and other metadata 
    Returntype : String 

=cut

sub is_metadata {
    my $self = shift;
    if ($self->{'current_block'} =~ /^track/ 
        || $self->{'current_block'} =~ /^browser/
        || $self->{'current_block'} =~ /^#/
      ) {
      return $self->{'current_block'};
    }
}

=head2 read_metadata

    Description: Splits the current block along predefined delimiters
    Returntype : Void 

=cut

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
    elsif ($line =~ /^(fixed|variable)Step/) {
      ## WIG-specific - but saves a lot of redundant code!
      $self->{'metadata'}{'step_type'} = $1.'Step';
      $line =~ s/^[fixed|variable]Step//;
      if ($line) {
        while ($line =~ s/(\w+)\s*=\s*(\S+)//) {
          $self->{'metadata'}->{$1} = $2;
        }
      }
    }
}

=head2 get_browser_switches

    Description: Getter for browser switch metadata
    Returntype : Hashref 

=cut

sub get_browser_switches {
    my $self = shift;
    return $self->{'metadata'}{'browser_switches'} || {};
}

=head2 get_metadata_value

    Argument [1] : Parameter name
    Description: Getter for arbitrary parameter in track line 
    Returntype : String

=cut

sub get_metadata_value {
  my ($self, $key) = @_;
  return $self->{'metadata'}{$key} || '';
}

1;
