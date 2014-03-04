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

package Bio::EnsEMBL::IO::Parser::PslParser;

use strict;
use warnings;

use base qw/Bio::EnsEMBL::IO::TrackBasedParser/;

## ----------- Mandatory fields (21) -------------

sub getRawMatches {
    my $self = shift;
    return $self->{'record'}[0];
}

sub getMatches {
    my $self = shift;
    return $self->getRawMatches; 
}

sub getRawMisMatches {
    my $self = shift;
    return $self->{'record'}[1];
}

sub getMisMatches {
    my $self = shift;
    return $self->getRawMisMatches; 
}

sub getRawRepMatches {
    my $self = shift;
    return $self->{'record'}[2];
}

sub getRepMatches {
    my $self = shift;
    return $self->getRawRepMatches; 
}

sub getRawNCount {
    my $self = shift;
    return $self->{'record'}[3];
}

sub getNCount {
    my $self = shift;
    return $self->getRawNCount; 
}

sub getRawQNumInsert {
    my $self = shift;
    return $self->{'record'}[4];
}

sub getQNumInsert {
    my $self = shift;
    return $self->getRawQNumInsert; 
}

sub getRawQBaseInsert {
    my $self = shift;
    return $self->{'record'}[5];
}

sub getQBaseInsert {
    my $self = shift;
    return $self->getRawQBaseInsert; 
}

sub getRawTNumInsert {
    my $self = shift;
    return $self->{'record'}[6];
}

sub getTNumInsert {
    my $self = shift;
    return $self->getRawTNumInsert; 
}

sub getRawTBaseInsert {
    my $self = shift;
    return $self->{'record'}[7];
}

sub getTBaseInsert {
    my $self = shift;
    return $self->getRawTBaseInsert; 
}

sub getRawStrand {
    my $self = shift;
    return $self->{'record'}[8];
}

sub getStrand {
    my $self = shift;
    ## Translated alignments list both query strand and genomic strand - we want the latter
    return substr($self->getRawStrand, -1);
}

sub getRawQName {
    my $self = shift;
    return $self->{'record'}[9];
}

sub getQName {
    my $self = shift;
    return $self->getRawQName; 
}

sub getRawQSize {
    my $self = shift;
    return $self->{'record'}[10];
}

sub getQSize {
    my $self = shift;
    return $self->getRawQSize; 
}

sub getRawQStart {
    my $self = shift;
    return $self->{'record'}[11];
}

sub getQStart {
    my $self = shift;
    return $self->getRawQStart; 
}

sub getRawQEnd {
    my $self = shift;
    return $self->{'record'}[12];
}

sub getQEnd {
    my $self = shift;
    return $self->getRawQEnd; 
}

sub getRawTName {
    my $self = shift;
    return $self->{'record'}[13];
}

sub getTName {
    my $self = shift;
    (my $chr = $self->getRawTName()) =~ s/^chr//;
    return $chr;
}

sub getRawTSize {
    my $self = shift;
    return $self->{'record'}[14];
}

sub getTSize {
    my $self = shift;
    return $self->getRawTSize; 
}

sub getRawTStart {
    my $self = shift;
    return $self->{'record'}[15];
}

sub getTStart {
    my $self = shift;
    return $self->getRawTStart+1; 
}

sub getRawTEnd {
    my $self = shift;
    return $self->{'record'}[16];
}

sub getTEnd {
    my $self = shift;
    return $self->getRawTEnd; 
}

sub getRawBlockCount {
    my $self = shift;
    return $self->{'record'}[17];
}

sub getBlockCount {
    my $self = shift;
    return $self->getRawBlockCount; 
}

sub getRawBlockSizes {
    my $self = shift;
    return $self->{'record'}[18];
}

sub getBlockSizes {
    my $self = shift;
    return split(',', $self->getRawBlockSizes); 
}

sub getRawQStarts {
    my $self = shift;
    return $self->{'record'}[19];
}

sub getQStarts {
    my $self = shift;
    return split(',', $self->getRawQStarts); 
}

sub getRawTStarts {
    my $self = shift;
    return $self->{'record'}[20];
}

sub getTStarts {
    my $self = shift;
    return split(',', $self->getRawTStarts); 
}


1;
