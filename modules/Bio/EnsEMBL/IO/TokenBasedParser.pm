=pod

=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2020] EMBL-European Bioinformatics Institute

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

Bio::EnsEMBL::IO::Parser::TokenBasedParser - An abstract parser class 
specialised for files with keyed fields or data that comprise a multi-
lined record.

=cut

package Bio::EnsEMBL::IO::TokenBasedParser;

use strict;
use warnings;

use Carp;

use parent qw/Bio::EnsEMBL::IO::TextParser/;

sub open {
    my ($caller, $filename, $start_tag, $end_tag, @other_args) = @_;

    if (! defined $start_tag && ! defined $end_tag) {
        confess("C'mon, gimme something to work with, you cannot define a TokenBasedParser without tokens!");
    }

    my $class = ref($caller) || $caller;
    
    my $self = $class->SUPER::open($filename, @other_args);
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
           || !defined $self->{'waiting_block'}
           || (defined $self->{'start_tag'} && $self->{'waiting_block'} =~ /$self->{'start_tag'}/);
}

=head2 is_end_of_record

    Description : Determines whether the current line is the first line of a record
    Returntype  : Boolean

=cut

sub is_at_beginning_of_record {
    my $self = shift;
    return !defined $self->{'start_tag'} || $self->{'current_block'} =~ /$self->{'start_tag'}/
           || !defined $self->{'waiting_block'};
}

1;
