=pod

=head1 LICENSE

  Copyright (c) 1999-2013 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

  http://www.ensembl.org/info/about/code_licence.html

=head1 NAME

Bio::EnsEMBL::IO::Parser::TokenBasedParser - An abstract parser class 
specialised for files with keyed fields or data that comprise a multi-
lined record.

=cut

package Bio::EnsEMBL::IO::TokenBasedParser;

use strict;
use warnings;

use Bio::EnsEMBL::Utils::Exception qw/throw/;
use Bio::EnsEMBL::Utils::Scalar qw/assert_ref/;

use base qw/Bio::EnsEMBL::IO::TextParser/;

sub open {
    my $caller = shift;
    my $filename = shift;
    my $start_tag = shift;
    my $end_tag = shift;

    if (not defined $start_tag && not defined $end_tag) {
	throw("C'mon, gimme something to work with, you cannot define a TokenBasedParser without tokens!");
    }

    my $class = ref($caller) || $caller;
    
    my $self = $class->SUPER::new($filename, @_);
    $self->{'start_tag'} = $start_tag;
    $self->{'end_tag'} = $end_tag;
    
    return $self;
}

=head2 is_at_end_of_record
    Description : Determines whether the next line belongs in record
    Returntype  : Boolean
=cut

sub is_at_end_of_record {
    my $self = shift;
    return (defined $self->{'end_tag'} && $self->{'current_block'} =~ /$self->{'end_tag'}/) 
	    || (defined $self->{'start_tag'} && $self->{'waiting_block'} =~ /$self->{'start_tag'}/);
}

=head2 is_end_of_record
    Description : Determines whether the current line is the first line of a record
    Returntype  : Boolean
=cut
sub is_at_beginning_of_record {
    my $self = shift;
    return not defined $self->{'start_tag'} || $self->{'current_block'} =~ /$self->{'start_tag'}/;
}

1;
