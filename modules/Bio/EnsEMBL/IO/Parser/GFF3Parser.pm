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

my %strand_conversion = ( '+' => '1', '?' => '0', '-' => '-1');


sub default_meta {
    my $self = shift;
    my $line = shift;
    
    if ($line =~ /^track/ || $line =~ /^\s*##/) {
        if ($line =~ /^\s*##FASTA/) {
            return 2;
        }
        return 1;
    }
};

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