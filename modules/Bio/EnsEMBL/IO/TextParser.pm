=pod

=head1 LICENSE

  Copyright (c) 1999-2013 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

  http://www.ensembl.org/info/about/code_licence.html

=head1 NAME

TextParser - An abstract line by line parser class

An extension of the Parser class that implements open, close, and read_block for text files.

If you are extending this class you need to implement:
- is_metadata: determines whether $self->{current_block} is metadata
- read_metadata: reads $self->{current_block}, stores relevant data in $self->{metadata} hash ref
- read_record: reads $self->{current_block}, possibly invoking $self->next_block(), stores list in $self->{record}
- a bunch of getters.

Optionally, you may want to implement:
- seek: seeks coordinate in sorted/indexed file

=cut

package Bio::EnsEMBL::IO::TextParser;

use strict;
use warnings;

use Bio::EnsEMBL::Utils::Exception qw/throw/;
use Bio::EnsEMBL::Utils::Scalar qw/assert_ref/;

use base qw/Bio::EnsEMBL::IO::Parser/;

=head2 open

    Constructor
    Argument [1] : Filepath
    Argument [2+]: Hash of parameters for configuration, e.g. buffer sizes or 
                   specific functions for handling headers or data
    Returntype   : Bio::EnsEMBL::IO::TextParser

=cut

sub open {
    my ($caller, $filename, @other_args) = @_;
    my $class = ref($caller) || $caller;

    my $self = $class->SUPER::new(@other_args);
    $self->{'filename'} = $filename;
    open($self->{'filehandle'}, $filename) || throw("Could not open " . $filename);

    return $self;
}

=head2 close

    Description  : Closes the filehandler
    Returntype   : True/False on success/failure

=cut

sub close {
    my $self = shift;
    return close $self->{'filehandle'};
}

=head2 read_block

    Description : Reads a line of text, stores it into next_block, 
                  moving next_block to current_block.
    Returntype   : True/False on existence of a defined current_block after running.

=cut

sub read_block {
    my $self = shift;
    my $fh = $self->{'filehandle'};

    if (eof($fh)) {
        $self->{'waiting_block'} = undef;
    } else {
        $self->{'waiting_block'} = <$fh> || throw ("Error reading file handle: $!");   
    }    
}

1;
