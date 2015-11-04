=pod

=head1 LICENSE

  Copyright (c) 1999-2013 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

  http://www.ensembl.org/info/about/code_licence.html

=head1 NAME

Bio::EnsEMBL::IO::Parser::GTFParser - A line-based parser devoted to GTF

=cut

package Bio::EnsEMBL::IO::Parser::GTFParser;

use strict;
use warnings;

use base qw/Bio::EnsEMBL::IO::GXFParser/;

sub open {
    my ($caller, $filename, @other_args) = @_;
    my $class = ref($caller) || $caller;
    
    my $self = $class->SUPER::open($filename, '\t', @_);

    # Metadata defaults
    if ($self->{'params'}->{'mustReadMetadata'}) {
       $self->{'gff-version'}->{'Type'} = '2';
       $self->{'metadata'}->{'Type'} = 'DNA';
    }

    # pre-load peek buffer
    $self->next_block();
    
    return $self;
}

sub is_metadata {
    my $self = shift;
    return $self->{'current_block'} =~ /^#/;
}

sub read_metadata {
    my $self = shift;
    my $line = $self->{'current_block'};
    
    # DZ: Question: are track lines valid in a GFF file? I don;'t see this anywhere...?
    if ($line =~ /^track/) {
	    # TODO
    } elsif ($line =~ /^\s*##gtf-version/) {
        chomp $line;
	my @words = split(/\s+/, $line);
        $self->{'metadata'}->{'gtf-version'} = $words[1];
    } elsif ($line =~ /^\s*##date/) {
        chomp $line;
	my @words = split(/\s+/, $line);
        $self->{'metadata'}->{'date'} = $words[1];
    } elsif ($line =~ /^\s*##source-version/) {
        chomp $line;
        (my $head, my @tail) = split(/\s+/, $line);
        $self->{'metadata'}->{'source-version'} = \@tail;
    } elsif ($line =~ /^\s*##Type/) {
        chomp $line;
        (my $head, my @tail) = split(/\s+/, $line);
        # DZ: I do not have the foggiest idea what Type means
        $self->{'metadata'}->{'Type'} = \@tail;
    }
};

sub getAttribute {
    my $self = shift;
    my $val = $self->getRawAttribute();

}

1;
