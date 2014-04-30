=pod

=head1 LICENSE

  Copyright (c) 1999-2013 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

  http://www.ensembl.org/info/about/code_licence.html

=head1 NAME

Bio::EnsEMBL::IO::Parser::ColumnBasedParser - An abstract parser class 
specialised for files where a single line constitutes an entire record

=cut

package Bio::EnsEMBL::IO::ColumnBasedParser;

use strict;
use warnings;

use base qw/Bio::EnsEMBL::IO::TextParser/;

=head2 open

    Constructor
    Argument [1] : Filepath
    Argument [2] : delimiters
    Argument [2+]: Hash of parameters for configuration, e.g. buffer sizes or 
                   specific functions for handling headers or data
    Returntype   : Bio::EnsEMBL::IO::ColumnBasedParser

    Extension of the TextBasedParser that implements read_record.

    If you are extending this class you need to implement:
    - is_metadata: determines whether $self->{current_block} is metadata
    - read_metadata: reads $self->{current_block}, stores relevant data in $self->{metadata} hash ref
    - a bunch of getters.
    
    Optionally, you may want to implement:
    - seek: seeks coordinate in sorted/indexed file

=cut

sub open {
    my ($caller, $filepath, $delimiter, @other_args) = @_;
    my $class = ref($caller) || $caller;
    
    my $self = $class->SUPER::open($filepath, @other_args);
    
    $self->{'delimiter'} = $delimiter;
    return $self;
}

=head2 read_record

    Description: Splits the current block along predefined delimiters
    Returntype : Void 

=cut


sub read_record {
    my $self = shift;
    chomp $self->{'current_block'};
    $self->{'record'} = [ split($self->{'delimiter'},$self->{'current_block'}) ] ;
}

1;
