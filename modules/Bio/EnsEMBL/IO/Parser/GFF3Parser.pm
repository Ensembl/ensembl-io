=pod

=head1 LICENSE

  Copyright (c) 1999-2013 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

  http://www.ensembl.org/info/about/code_licence.html

=head1 NAME

Bio::EnsEMBL::IO::Parser::GFF3Parser - A line-based parser devoted to GFF3

=cut

package Bio::EnsEMBL::IO::Parser::GFF3Parser;

use strict;
use warnings;

use base qw/Bio::EnsEMBL::IO::ColumnBasedParser/;

sub open {
    my $caller = shift;
    my $class = ref($caller) || $caller;
    
    my $self = $class->SUPER::new('\t', @_);

    # Metadata defaults
    if ($self->{'params'}->{'mustReadMetadata'}) {
       $self->{'gff-version'}->{'Type'} = '2';
       $self->{'metadata'}->{'Type'} = 'DNA';
    }
    
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
	;
    } elsif ($line =~ /^\s*##gff-version/) {
	chomp $line;
        $self->{'metadata'}->{'gff-version'} = split(/\s+/, $line)[1];
    } elsif ($line =~ /^\s*##date/) {
	chomp $line;
        $self->{'metadata'}->{'date'} = split(/\s+/, $line)[1];
    } elsif ($line =~ /^\s*##source-version/) {
	chomp $line;
	($head, @tail) = split(/\s+/, $line);
        $self->{'metadata'}->{'source-version'} = \@tail;
    } elsif ($line =~ /^\s*##Type/) {
	chomp $line;
	($head, @tail) = split(/\s+/, $line);
        $self->{'metadata'}->{'Type'} = \@tail;
    }
};

sub getRawSeqName {
    my $self = shift;
    return $self->{'record'}[0]
}

sub getSeqName {
    my $self = shift;
    return $self->getRawSeqName();
}

sub getRawSource {
    my $self = shift;
    return $self->{'record'}[1]
}

sub getSource {
    my $self = shift;
    return $self->getRawSource();
}

sub getRawStart {
    my $self = shift;
    return $self->{'record'}[2]
}

sub getStart {
    my $self = shift;
    return $self->getRawStart();
}

sub getRawEnd {
    my $self = shift;
    return $self->{'record'}[3]
}

sub getEnd {
    my $self = shift;
    return $self->getRawEnd();
}

sub getRawScore {
    my $self = shift;
    return $self->{'record'}[4]
}

sub getScore {
    my $self = shift;
    my $val = $self->getRawScore();
    if ($val =~ /\./) {
	    return undef;
    } else {
	    return $val;
    }
}

sub getRawStrand {
    my $self = shift;
    return $self->{'record'}[5]
}

my %strand_conversion = ( '+' => '1', '.' => '0', '-' => '-1');

sub getStrand {
    my $self = shift;
    my $val = $self->getRawStrand();
    if ($val =~ /\./) {
	    return undef;
    } else {
	    return $strand_conversion{$val};
    }
}

sub getRawFrame {
    my $self = shift;
    return $self->{'record'}[6]
}

sub getFrame {
    my $self = shift;
    my $val = $self->getRawFrame();
    if ($val =~ /\./) {
	    return undef;
    } else {
	    return $val;
    }
}

sub getRawAttribute {
    my $self = shift;
    return $self->{'record'}[7]
}

sub getAttribute {
    my $self = shift;
    my $val = $self->getRawAttribute();

}

# NOT FULLY IMPLEMENTED
=head2 fasta_record

  Arg [1]    : listref taking the form [$meta_line,$sequence]
  Description: Getter/setter for FASTA found within a GFF3 file. The richer
               capabilities of the FASTA parser are ignored because using FASTA
               within a GFF file is horrid and hard to handle automatically.
               It accumulates or dispenses FASTA records until it runs out.
  Example    : $parser->fasta_record([$header,$seq]);
               $parser->fasta_record([$header2,$seq2]);
               while ($parser->fasta_record) {
                   ....
               }
  Returntype : Listref of Strings, consisting of header and sequence
=cut

sub fasta_record {
    my $self = shift;
    my $fasta_array = shift;
    my ($meta,$seq) = ($fasta_array->[0],$fasta_array->[1]);
    if ($seq) {
        push @{ $self->{'fasta'} },[$meta,$seq];
    } else {
        my $fasta = $self->{'fasta'};
        return shift @$fasta;
    }
}

1;
