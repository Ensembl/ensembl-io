=pod

=head1 LICENSE

  Copyright (c) 1999-2013 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

  http://www.ensembl.org/info/about/code_licence.html

=head1 NAME

Bio::EnsEMBL::IO::Parser::Wig - A line-based parser devoted to WIG format

=cut

package Bio::EnsEMBL::IO::Parser::Wig;

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
  $self->{'metadata'}{'feature_count'}++;
}


## --------- FORMAT-SPECIFIC METADATA -----------

=head2 is_metadata

    Description: Identifies track lines and other metadata 
                  Extends parent, to (re)set feature_count parameter
                  to zero upon encountering a new track
    Returntype : String 

=cut

sub is_metadata {
  my $self = shift;
  if ($self->{'current_block'} =~ /^track/ 
      || $self->{'current_block'} =~ /^browser/
      || $self->{'current_block'} =~ /^#/ 
      || $self->{'current_block'} =~ /^(fixed|variable)Step/) {
    $self->{'metadata'}{'feature_count'} = 0;
    return $self->{'current_block'};
  }
}

=head2 get_feature_count

    Description: Getter for internally-generated feature count 
    Returntype : Integer

=cut

sub get_feature_count {
  ## Not strictly part of metadata, but we need to keep track of this
  ## in fixed-step tracks to get the start coordinates right
  my $self = shift;
  return $self->{'metadata'}{'feature_count'} || 0;
}

=head2 get_wiggle_type

    Description: Getter - works out track type based on metadata 
    Returntype : String

=cut

sub get_wiggle_type {
  my $self = shift;
  return $self->{'metadata'}{'step_type'} || $self->{'metadata'}{'type'};
}

## -------------- RECORDS -------------------

## ----------- Mandatory fields -------------

=head2 get_raw_chrom

    Description: Getter for chrom field
    Returntype : String 

=cut

sub get_raw_chrom {
  my $self = shift;
  if ($self->get_wiggle_type =~ /Step/) {
    return $self->{'metadata'}{'chrom'};
  }
  else {
    return $self->{'record'}[0];
  }
}

=head2 get_seqname

    Description: Getter - wrapper around raw method 
                  (uses standard method name, not format-specific)
    Returntype : String 

=cut

sub get_seqname {
  my $self = shift;
  (my $chr = $self->get_raw_chrom()) =~ s/^chr//;
  return $chr;
}

=head2 get_raw_start

    Description: Getter for start field
    Returntype : Integer 

=cut
sub get_raw_start {
  my $self = shift;
  if ($self->get_wiggle_type eq 'fixedStep') {
    return $self->{'metadata'}{'start'};
  }
  elsif ($self->get_wiggle_type eq 'variableStep') {
    return $self->{'record'}[0];
  }
  else {
    return $self->{'record'}[1];
  }
}

=head2 get_start

    Description: Getter - wrapper around raw_start method, converting
                  semi-open coordinates to standard Ensembl ones where necessary
    Returntype : Integer 

=cut

sub get_start {
  my $self = shift;
  if ($self->get_wiggle_type eq 'variableStep') {
    return $self->get_raw_start();
  }
  elsif ($self->get_wiggle_type eq 'fixedStep') {
    return $self->get_raw_start() + $self->get_metadata_value('step') * ($self->get_feature_count() - 1);
  }
  else {
  ## BED-type format with half-open coordinates
    return $self->get_raw_start() + 1;
  }
}

=head2 get_raw_end

    Description: Getter for end field
    Returntype : Integer

=cut

sub get_raw_end {
  my $self = shift;
  return $self->{'record'}[2];
}

=head2 get_end

    Description: Getter - wrapper around get_raw_chromEnd 
    Returntype : String 

=cut

sub get_end {
  my $self = shift;
  if ($self->get_wiggle_type =~ /Step/) {
    my $end = $self->get_start + $self->get_metadata_value('span') - 1;
    return $end;
  }
  else {
    return $self->get_raw_end();
  }
}

=head2 get_raw_score

    Description: Getter for score field
    Returntype : Number (usually floating point) or String (period = no data)

=cut

sub get_raw_score {
  my $self = shift;
  if ($self->get_wiggle_type eq 'fixedStep') {
    return $self->{'record'}[0];
  }
  elsif ($self->get_wiggle_type eq 'variableStep') {
    return $self->{'record'}[1];
  } 
  else {
    return $self->{'record'}[3];
  } 
}

=head2 get_score

    Description: Getter - wrapper around get_raw_score
    Returntype : Number (usually floating point) or undef

=cut

sub get_score {
  my $self = shift;
  my $val = $self->get_raw_score();
  if ($val =~ /^\.$/) {
    return undef;
  } else {
    return $val;
  }
}

1;
