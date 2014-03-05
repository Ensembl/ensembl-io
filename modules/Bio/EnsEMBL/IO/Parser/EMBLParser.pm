=pod

=head1 LICENSE

  Copyright (c) 1999-2013 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

  http://www.ensembl.org/info/about/code_licence.html

=head1 NAME

Bio::EnsEMBL::IO::Parser::EMBLParser - A record-based parser that reads EMBL format.

=head1 DESCRIPTION

EMBL format reading is done according to the following specification:
ftp://ftp.ebi.ac.uk/pub/databases/embl/doc/usrman.txt

=cut

package Bio::EnsEMBL::IO::Parser::EMBLParser;

use strict;
use warnings;

use base qw/Bio::EnsEMBL::IO::TokenBasedParser/;

=head2 open

    Description: Open Fasta file
    Argument [1]: Path to file 
    Returntype : Ensembl::IO::Parser::EMBLParser object

=cut

sub open {
    my ($caller, $filename, @other_args) = @_;
    my $class = ref($caller) || $caller;
    
    my $self = $class->SUPER::open($filename, undef, '^//', @other_args);

    # pre-load peek buffer
    $self->next_block();
    
    return $self;
}

# store each row in a hash keyed with their symbol.
# 
# $self->{record}->{symbol}->[]
#

sub read_record {
    my $self = shift;
    # purge previous record
    foreach (keys (%{$self->{record}})) {$self->{record}->{$_} = []}
    my $field_type = '';
    until ($field_type eq 'SQ' || $self->is_at_end_of_record) {
        if (!$field_type || $field_type eq 'XX' || $self->is_metadata || $field_type eq 'SQ') {
            $self->next_block;
            $field_type = substr($self->{current_block},0,2);
            next;
        }
        # references are contextual, so just keep the text in a block
        if ($field_type =~ /^R/) {$field_type = 'References'}
        push @{$self->{record}->{$field_type}},$self->{current_block};
        $self->next_block;
        $field_type = substr($self->{current_block},0,2);
    }
    if ($field_type eq 'SQ') {
        push @{$self->{record}->{$field_type}},$self->{current_block};
        $self->next_block;
        until ($self->is_at_end_of_record) {
            my $seq = $self->{current_block};
            chomp $seq;
            $seq =~ s/\d+$//;
            $seq =~ s/\s//g;
            $self->{record}->{sequence} .= $seq;
            $self->next_block;
        }
    }
}

sub is_metadata {
    my $self = shift;
    return $self->{current_block} =~ /^#/;
}

sub read_metadata {
    return;
}

sub getSequence {
    my $self = shift;
    return $self->{record}->{sequence};
}

=head2 getAccessions
    Description: Get an unpunctuated list of the AC fields 
    Returntype : listref
=cut

sub getAccessions {
    my $self = shift;
    return $self->getStuff('AC');
}

=head2 getDescription
    Description: Fetch the DE field, combined into a single string
    Returntype : String
=cut

sub getDescription {
    my $self = shift;
    return $self->smushText('DE');
}

=head2 getKeywords
    Description: Get a list of EMBL keywords. An empty string implies no keywords.
    Returntype : ListRef of strings
=cut

sub getKeywords {
    my $self = shift;
    my $keys = $self->getStuff('KW');
    return [] unless $keys;
    return $keys;
}

sub getSpecies {
    my $self = shift;
    return $self->smushText('OS');
}

sub getClassification {
    my $self = shift;
    return $self->getStuff('OC');
}

sub smushText {
    my $self = shift;
    my $key = shift;
    my $list = $self->{record}->{$key};
    if (!defined $list) {return}
    chomp @$list;
    map { $_ =~ s/^\w\w\s+//} @$list;
    return join '',@$list;
}

=head2 getStuff
    Description: Convenience method for the extraction of arbitrary keys from their
                 multi-line eccentric EMBL format
    Returntype : listref
=cut

sub getStuff {
    my $self = shift;
    my $key = shift;
    my $list = $self->{record}->{$key};
    if (!defined $list) {return}
    chomp @$list;
    $list->[-1] =~ s/\.//; # last entry has a full stop on the end
    map { $_ =~ s/^\w\w\s+//} @$list;
    my @trimmed_things = split(';\s*',join(' ',@$list));
    return \@trimmed_things;
}

=head2 getRawID
    Description: Get the ID field as it was found within the source file 
    Returntype : listref
=cut

sub getRawID {
    my $self = shift;
    return $self->{record}->{ID};
}

sub getRawAccessions {
    my $self = shift;
    return $self->{record}->{AC};
}

sub getRawDescription {
    my $self = shift;
    return $self->{record}->{DE};
}

sub getRawKeywords {
    my $self = shift;
    return $self->{record}->{KW};
}

sub getRawDate {
    my $self = shift;
    return $self->{record}->{DT};
}

sub getRawSpecies {
    my $self = shift;
    return $self->{record}->{OS};
}

sub getRawClassification {
    my $self = shift;
    return $self->{record}->{OC};
}

sub getRawReferences {
    my $self = shift;
    return $self->{record}->{References};
}

sub getRawFeatures {
    my $self = shift;
    return $self->{record}->{FT};
}

sub getRawComments {
    my $self = shift;
    return $self->{record}->{CC};
}

sub getRawAssemblyHeader {
    my $self = shift;
    return $self->{record}->{AH};
}

sub getRawAssembly {
    my $self = shift;
    return $self->{record}->{AS};
}

sub getRawContig {
    my $self = shift;
    return $self->{record}->{CO};
}

1;