=pod

=head1 LICENSE

  Copyright (c) 1999-2013 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

  http://www.ensembl.org/info/about/code_licence.html

=head1 NAME

Bio::EnsEMBL::IO::Parser::GFF3 - A line-based parser devoted to GFF3

=cut

package Bio::EnsEMBL::IO::Parser::GFF3;

use strict;
use warnings;

use base qw/Bio::EnsEMBL::IO::ColumnBasedParser/;

sub open {
    my ($caller, $filename, @other_args) = @_;
    my $class = ref($caller) || $caller;
    
    my $self = $class->SUPER::open($filename, '\t', @other_args);

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
    } elsif ($line =~ /^\s*##gff-version/) {
        chomp $line;
	my @words = split(/\s+/, $line);
        $self->{'metadata'}->{'gff-version'} = $words[1];
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


=head2 set_fields

    Description: Setter for list of fields used in this format - uses the
                  "public" (i.e. non-raw) names of getter methods
    Returntype : Void

=cut

sub set_fields {
  my $self = shift;
  $self->{'fields'} = [qw(seqname source feature start end score strand phase attribute)];
}


=head2 set_minimum_column_count

    Description: Sets minimum column count for a valid GFF file 
    Returntype : Void 

=cut

sub set_minimum_column_count {
    my $self = shift;
    $self->{'min_col_count'} = 5;
}

######### FIELD ACCESSORS ################

# Seq region name

=head2 get_raw_seqname
    Description : Return the name of the sequence
    Returntype  : String
=cut

sub get_raw_seqname {
    my $self = shift;
    return $self->{'record'}[0];
}


=head2 get_seqname
    Description : Return the name of the sequence
    Returntype  : String
=cut

sub get_seqname {
    my $self = shift;
    return $self->get_raw_seqname();
}

# Source name

=head2 get_raw_source
    Description : Return the name of the source of the data
    Returntype  : String
=cut

sub get_raw_source {
    my $self = shift;
    return $self->{'record'}[1];
}


=head2 get_source
    Description : Return the name of the source of the data
    Returntype  : String
=cut

sub get_source {
    my $self = shift;
    return $self->get_raw_source();
}

# Sequence type

=head2 get_raw_type
    Description : Return the class/type of the feature
    Returntype  : String
=cut

sub get_raw_type {
  my $self = shift;
  return $self->{'record'}[2];
}


=head2 get_type
    Description : Return the class/type of the feature
    Returntype  : String
=cut

sub get_type {
    my $self = shift;
    return $self->get_raw_type();
}


equence start

=head2 get_raw_start
    Description : Return the start position of the feature
    Returntype  : Integer
=cut

sub get_raw_start {
    my $self = shift;
    return $self->{'record'}[3];
}


=head2 get_start
    Description : Return the start position of the feature
    Returntype  : Integer
=cut

sub get_start {
    my $self = shift;
    return $self->get_raw_start();
}


# Sequence end

=head2 get_raw_end
    Description : Return the end position of the feature
    Returntype  : Integer
=cut

sub get_raw_end {
    my $self = shift;
    return $self->{'record'}[4];
}

# Phred scaled probability that the sequence_alteration call is incorrect (real number)

=head2 get_raw_score
    Description : Return the Phred scaled probability that the sequence_alteration call is incorrect (real number)
    Returntype  : Integer
=cut

sub get_raw_score {
    my $self = shift;
    return $self->{'record'}[5];
}


=head2 get_score
    Description : Return the Phred scaled probability that the sequence_alteration call is incorrect (real number)
    Returntype  : Integer
=cut

sub get_score {
    my $self = shift;
    my $val = $self->get_raw_score();
    return ($val =~ /\./) ? undef : $val;
}

# Sequence strand

=head2 get_raw_strand
    Description : Return the strand of the feature
    Returntype  : String
=cut

sub get_raw_strand {
    my $self = shift;
    return $self->{'record'}[6];
}


=head2 get_strand
    Description : Return the strand of the feature (1 for the forward strand and -1 for the reverse strand)
    Returntype  : Integer
=cut

sub get_strand {
    my $self = shift;
    my $val = $self->get_raw_strand();
    return $self->{'strand_conversion'}{$val} || $val;
}


# Phase/Frame

=head2 get_raw_phase
    Description : Return the phase/frame of the feature
    Returntype  : String
=cut

sub get_raw_phase {
  my $self = shift;
  return $self->{'record'}[7];
}


=head2 get_phase
    Description : Return the phase/frame of the feature
    Returntype  : String
=cut

sub get_phase {
    my $self = shift;
    my $val = $self->get_raw_phase();
    return ($val =~ /\./) ? undef : $val;
}


# Attributes
# The methods listed below concern the 9th column data

=head2 get_raw_attributes
    Description : Return the content of the 9th column of the line
    Returntype  : String
=cut

sub get_raw_attributes {
  my $self = shift;
  return $self->{'record'}[8];
}

=head2 get_attributes
    Description : Return the content of the 9th column of the line in a hash: "attribute => value"
    Returntype  : Reference to a hash
=cut

sub get_attributes {
  my $self = shift;
  my %attributes;
  foreach my $attr (split(';',$self->get_raw_attributes)) {
    my ($key,$value) = split('=',$attr);
    $attributes{$key} = $value;
  }
  return \%attributes;
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
