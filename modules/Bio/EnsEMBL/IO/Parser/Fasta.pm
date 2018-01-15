=pod

=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2018] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 NAME

Bio::EnsEMBL::IO::Parser::Fasta - A record-based parser devoted to FASTA format

=head1 DESCRIPTION

  Slurps entire sequence chunks into memory. Handle with care and avoid hanging
  onto too many segments of the file if you value your memory.

=cut

package Bio::EnsEMBL::IO::Parser::Fasta;

use strict;
use warnings;

use base qw/Bio::EnsEMBL::IO::TokenBasedParser/;
use Bio::EnsEMBL::IO::Object::Fasta;

=head2 open

    Description: Open Fasta file
    Argument [1]: Path to file 
    Returntype : Ensembl::IO::Parser::Fasta object

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

# We have to overload the next() function because
# the SUPER::next() checks  $self->{'current_block'}
# to decide if there's another record, unfortunately
# if we don't read the sequence while cycling, this
# contains a line...the next line of FASTA... nope.

sub next {
    my $self = shift;

    # If the sequence of the previous record was not scanned
    while (defined $self->{'current_block'} && not $self->is_at_end_of_record()) {
        $self->next_block();
    }

    return $self->SUPER::next();
}

=head2 next_sequence

    Description: Alias to next(), to maintain a consistant
                 call to retrieve the next sequence when using
                 Fasta or GFF3 parsers.

=cut

sub next_sequence {
    my $self = shift;

    return $self->next();
}

sub read_record {
    my $self = shift;
    $self->{'sequence'} = undef;
    # If the sequence of the previous record was not scanned
#    while (defined $self->{'current_block'} && not $self->is_at_beginning_of_record()) {
#        $self->next_block();
#    }
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
        push @$arrayRef, $self->{'current_block'};
        $self->next_block();
    }
    push @$arrayRef, $self->{'current_block'};

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

=head2

    Description: Create a generic object for a record with setters and accessors
                 for a fasta record
    Returntype : Bio::EnsEMBL::IO::Object::Fasta

=cut

sub create_object {
    my $self = shift;

    my $obj = Bio::EnsEMBL::IO::Object::Fasta->new(-HEADER => $self->getHeader, -SEQUENCE => $self->getSequence);

    return $obj;

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

=head2 in_fasta_mode
    Description: For interoperability with mixed formats such as GFF3, to determine
                 if the parser allows reading sequences. Default 1
    Returntype : scalar
=cut

sub in_fasta_mode { return 1; }

1;
