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

use base qw/Bio::EnsEMBL::IO::Parser/;

sub new {
    my $caller = shift;
    my $class = ref($caller) || $caller;
    
    my $self = $class->SUPER::new(@_);
    
    $self->{'delimiter'} ||= '\t|\s\s+';
    return $self;
}


sub read_record {
    my $self = shift;
    
    while ($self->read_line) {
        my $line = $self->this_line;
        if ($self->spot_metadata($line) || length($line) <= 1) {  
            next;
        } elsif (ref($self->data_function) eq "CODE") {
            return $self->process_record($line);
        } else {
            return split($self->{'delimiter'},$line);
        }
        
    }
    return;
}

sub delimiter {
    my $self = shift;
    my $delimiter = shift;
    
    if ($delimiter) {
        $self->{'delimiter'} = $delimiter;
    }
    return $self->{'delimiter'};
}


1;