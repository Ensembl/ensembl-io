=pod

=head1 LICENSE

  Copyright (c) 1999-2013 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

  http://www.ensembl.org/info/about/code_licence.html

=head1 NAME

Bio::EnsEMBL::IO::Parser::FastaParser - A record-based parser devoted to FASTA format

=head1 DESCRIPTION

  Slurps entire sequence chunks into memory. Handle with care and avoid hanging
  onto too many segments of the file if you value your memory.

=cut

package Bio::EnsEMBL::IO::Parser::FastaParser;

use strict;
use warnings;

use base qw/Bio::EnsEMBL::IO::TokenBasedParser/;

=head2 open
    Description: Open Fasta file
    Argument [1]: Path to file 
    Returntype : Ensembl::IO::Parser::FastaParser object
=cut
sub open {
    my ($caller, $filename, @other_args) = @_;
    my $class = ref($caller) || $caller;
    
    my $self = $class->SUPER::open($filename, '^>', undef, @other_args);
    $self->{'sequence'} = undef;

    # pre-load peek buffer
    $self->next_block();
    
    return $self;
}

sub read_record {
    my $self = shift;
    $self->{'sequence'} = undef;
    # If the sequence of the previous record was not scanned
    while (defined $self->{'current_block'} && not $self->is_at_beginning_of_record()) {
        $self->next_block();
    }
    if (defined $self->{'current_block'} ) {
        $self->{'record'} = [ $self->{'current_block'} ];
        $self->next_block();
    } else {
        $self->{'record'} = undef;
    }
}

=head2 getRawHeader 
    Description: Return header line
    Returntype : scalar
=cut
sub getRawHeader {
    my $self = shift;
    return $self->{'record'}[0];
}

=head2 getHeader 
    Description: Return header of the sequence
    Returntype : scalar
=cut
sub getHeader {
    my $self = shift;
    my $line = $self->getRawHeader();
    chomp $line;
    # Remove initial '>' character
    return substr($line, 1);
}

=head2 read_sequence 
    Description: Read sequence lines of Fasta record
    Returntype : Array ref
=cut
sub read_sequence {
    my $self = shift;
    my $arrayRef = [];

    while (not $self->is_at_end_of_record()) {
        push $arrayRef, $self->{'current_block'};
        $self->next_block();
    }
    push $arrayRef, $self->{'current_block'};

    return $arrayRef;
}

=head2 getRawSequence
    Description: return raw sequence data
    Returntype : Array ref of text lines
=cut
sub getRawSequence {
    my $self = shift;
    if (not defined $self->{'sequence'}) {
        $self->{'sequence'} = $self->read_sequence();
    }
    return $self->{'sequence'}; 
}

=head2 getSequence
    Description: return sequence attached to record 
    Returntype : scalar
=cut
sub getSequence {
    my $self = shift;
    my $lines = $self->getRawSequence();
    chomp @$lines;
    return join("", @$lines);
}

=head2 is_metadata
    Description: default 0;
    Returntype : scalar
=cut

sub is_metadata { return 0; }

=head2 is_metadata
    Description: empty shell
    Returntype : Void
=cut

sub read_metadata {}

1;
