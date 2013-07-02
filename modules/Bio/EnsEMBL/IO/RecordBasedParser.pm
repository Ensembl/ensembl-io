=pod

=head1 LICENSE

  Copyright (c) 1999-2013 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

  http://www.ensembl.org/info/about/code_licence.html

=head1 NAME

Bio::EnsEMBL::IO::Parser::RecordBasedParser - An abstract parser class 
specialised for files with keyed fields or data that comprise a multi-
lined record.

=cut

package Bio::EnsEMBL::IO::RecordBasedParser;

use strict;
use warnings;

use Bio::EnsEMBL::Utils::Exception qw/throw/;
use Bio::EnsEMBL::Utils::Scalar qw/assert_ref/;

use base qw/Bio::EnsEMBL::IO::Parser/;

sub new {
    my $caller = shift;
    my $class = ref($caller) || $caller;
    
    my $self = $class->SUPER::new(@_);
    
#    $self->{'end_tag'} ||= '//'; # Overriding values here is a problem for child parsers who might need other defaults.
#    $self->{'start_tag'} ||= '//';
    return $self;
}

=head2 read_record
    Description : Reads one complete record from the source file, and processes
                  it with either a default behaviour, or user specified function.
                  Default behaviour is to return the entire record with metadata
                  filtered out. Unclosed records, such as where records have only
                  marked starts, are returned including any trailing whitespace.
                  The last attempt to read_record from a file triggers a 0 return
                  to indicate no more records.
    Returntype  : (default) reference to data buffer
=cut

sub read_record {
    my $self = shift;
    my @buffer;
    
    my $start_tag = $self->start_tag;
    my $end_tag = $self->end_tag;
    
    my $in_record = 0;
    # second attempt
    while ($self->read_line) {
        if ($self->this_line =~ /$start_tag/) {
            $in_record = 1;
        }
        if ($self->spot_metadata($self->this_line) ) {next;} # metadata lines are not kept
        if ($in_record) {
            push @buffer,$self->this_line;
        }
        if ($in_record == 1 && ( ! $self->next_line || $self->next_line =~ /$end_tag/ ) ) {
            # end tags can sometimes be the same as start tags. 
            $in_record = 0;
            if (@buffer) {
                if (ref($self->data_function()) eq "CODE") {
                    return $self->process_record(\@buffer);
                } else {
                    return \@buffer;
                }
            }
        }
    }
    return;
}

sub start_tag {
    my $self = shift;
    my $tag = shift;
    if ($tag) {
        $self->{'start_tag'} = $tag;
    }
    return $self->{'start_tag'};
}

sub end_tag {
    my $self = shift;
    my $tag = shift;
    if ($tag) {
        $self->{'end_tag'} = $tag;
    }
    return $self->{'end_tag'};
}

1;