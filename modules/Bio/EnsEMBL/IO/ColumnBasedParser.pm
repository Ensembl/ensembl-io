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
=cut

sub open {
    my $caller = shift;
    my $filepath = shift;
    my $delimiter = shift; 
    my $class = ref($caller) || $caller;
    
    my $self = $class->SUPER::open($filepath, @_[2 .. $#_ - 1]);
    
    $self->{'delimiter'} = $delimiter;
    return $self;
}

=head2 read_record
    Description: Splits the current block along predefined delimiters
    Returntype : Void 
=cut


sub read_record {
    my $self = shift;
    $self->{'record'} = split($self->{'delimiter'},$self->{'current_block'});
}

1;
