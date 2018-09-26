=pod

=head1 LICENSE

  Copyright (c) 1999-2013 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

  http://www.ensembl.org/info/about/code_licence.html

=head1 NAME

Bio::EnsEMBL::IO::Parser::EMBL - A record-based parser that reads EMBL format.

=head1 DESCRIPTION

EMBL format reading is done according to the following specification:
ftp://ftp.ebi.ac.uk/pub/databases/embl/doc/usrman.txt

=cut

package Bio::EnsEMBL::IO::Parser::EMBL;

use strict;
use warnings;

use base qw/Bio::EnsEMBL::IO::TokenBasedParser/;

=head2 open

    Description: Open Fasta file
    Argument [1]: Path to file 
    Returntype : Ensembl::IO::Parser::EMBL object

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

    # this is necessary if we want to intercept the record ID
    my $field_type = substr($self->{current_block}, 0, 2);
    push @{$self->{record}->{$field_type}}, $self->{current_block};
    
    $field_type = '';
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

sub get_sequence {
    my $self = shift;
    return $self->{record}->{sequence};
}

=head2 get_id
    Description: Get the ID without extra qualifiers in the record
    Returntype : String
=cut

sub get_id {
    my $self = shift;
    return (split /\s/, $self->get_stuff('ID')->[0])[0];
}

=head2 get_accessions
    Description: Get an unpunctuated list of the AC fields 
    Returntype : listref
=cut

sub get_accessions {
    my $self = shift;
    return $self->get_stuff('AC');
}

=head2 get_description
    Description: Fetch the DE field, combined into a single string
    Returntype : String
=cut

sub get_description {
    my $self = shift;
    return $self->smush_text('DE');
}

=head2 get_keywords
    Description: Get a list of EMBL keywords. An empty string implies no keywords.
    Returntype : ListRef of strings
=cut

sub get_keywords {
    my $self = shift;
    my $keys = $self->get_stuff('KW');
    return [] unless $keys;
    return $keys;
}

sub get_species {
    my $self = shift;
    return $self->smush_text('OS');
}

sub get_classification {
    my $self = shift;
    return $self->get_stuff('OC');
}

sub get_date {
    my $self = shift;
    return $self->get_stuff('DT');
}

=head2 get_database_cross_references
    Description:
    Returntype: ListRef of strings in the format DB:ID
=cut

sub get_database_cross_references {
  my $self = shift;
  my $list = $self->get_raw_database_cross_references;
  return unless defined $list;

  chomp @$list;
  my @xrefs = map { $_ =~ s/^\w\w\s+// and join(':', (split /; /)[0..1]) } @$list;
  
  return \@xrefs;
}

sub smush_text {
    my $self = shift;
    my $key = shift;
    my $list = $self->{record}->{$key};
    if (!defined $list) {return}
    chomp @$list;
    map { $_ =~ s/^\w\w\s+//} @$list;
    return join '',@$list;
}

=head2 get_stuff
    Description: Convenience method for the extraction of arbitrary keys from their
                 multi-line eccentric EMBL format
    Returntype : listref
=cut

sub get_stuff {
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

=head2 get_raw_id
    Description: Get the ID field as it was found within the source file 
    Returntype : listref
=cut

sub get_raw_id {
    my $self = shift;
    return $self->{record}->{ID};
}

sub get_raw_accessions {
    my $self = shift;
    return $self->{record}->{AC};
}

sub get_raw_description {
    my $self = shift;
    return $self->{record}->{DE};
}

sub get_raw_keywords {
    my $self = shift;
    return $self->{record}->{KW};
}

sub get_raw_date {
    my $self = shift;
    return $self->{record}->{DT};
}

sub get_raw_species {
    my $self = shift;
    return $self->{record}->{OS};
}

sub get_raw_classification {
    my $self = shift;
    return $self->{record}->{OC};
}

sub get_raw_references {
    my $self = shift;
    return $self->{record}->{References};
}

sub get_raw_features {
    my $self = shift;
    return $self->{record}->{FT};
}

sub get_raw_comments {
    my $self = shift;
    return $self->{record}->{CC};
}

sub get_raw_assembly_header {
    my $self = shift;
    return $self->{record}->{AH};
}

sub get_raw_assembly {
    my $self = shift;
    return $self->{record}->{AS};
}

sub get_raw_contig {
    my $self = shift;
    return $self->{record}->{CO};
}

sub get_raw_pelevel {
    my $self = shift;
    return $self->{record}->{PE};
}

sub get_raw_database_cross_references {
  my $self = shift;
  return $self->{record}->{DR};
}

sub get_pelevel {
    my $self = shift;
    return substr($self->get_raw_pelevel->[0], 5, 1);
}

1;
