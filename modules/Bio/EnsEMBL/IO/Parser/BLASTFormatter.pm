=pod

=head1 LICENSE

  Copyright (c) 1999-2013 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

  http://www.ensembl.org/info/about/code_licence.html

=head1 NAME

Bio::EnsEMBL::IO::Parser::BLASTFormatter - A column-based parser of blast formatted output

=cut

package Bio::EnsEMBL::IO::Parser::BLASTFormatter;

use strict;
use warnings;
use Data::Dumper;
use Bio::EnsEMBL::Utils::Exception qw/throw/;

use base qw/Bio::EnsEMBL::IO::ColumnBasedParser/;
our ($AUTOLOAD);

#
# From: http://home.cc.umanitoba.ca/~psgendb/birchhomedir/doc/NCBI/blast_formatter.txt
#
# Supported format specifiers:
# qseqid : Query Seq-id
# qgi : Query GI
# qacc : Query accesion
# qaccver : Query accesion.version
# qlen : Query sequence length
# sseqid : Subject Seq-id
# sallseqid : All subject Seq-id(s), separated by a ';'
# sgi : Subject GI
# sallgi : All subject GIs
# sacc : Subject accession
# saccver : Subject accession.version
# sallacc : All subject accessions
# slen : Subject sequence length
# qstart : Start of alignment in query
# qend : End of alignment in query
# sstart : Start of alignment in subject
# send : End of alignment in subject
# qseq : Aligned part of query sequence
# sseq : Aligned part of subject sequence
# evalue : Expect value
# bitscore : Bit score
# score : Raw score
# length : Alignment length
# pident : Percentage of identical matches
# nident : Number of identical matches
# mismatch : Number of mismatches
# positive : Number of positive-scoring matches
# gapopen : Number of gap openings
# gaps : Total number of gaps
# ppos : Percentage of positive-scoring matches
# frames : Query and subject frames separated by a '/'
# qframe : Query frame
# sframe : Subject frame
# btop : Blast traceback operations (BTOP)
#

#
# AUTOLOAD
#
sub AUTOLOAD {
  my $self = shift;
  my $method = $AUTOLOAD;
  $method =~ s/.*:://;

  return if $method !~ /^get_/;

  $method =~ /get_raw_(.+?)$|get_(.+?)$/;
  my $attr = $1;

  throw("Invalid attribute method: ->$method()") 
    unless exists $self->{fields_index}{$attr};
  
  return $self->{record}[$self->{fields_index}{$attr}];
}

sub open {
  my ($caller, $filename, $format, @other_args) = @_;
  my $class = ref($caller) || $caller;
 
  defined $filename or 
    throw "Must provide name of the file to parse";
  -e $filename and -f $filename or
    throw "Check file $filename exists and is readable";

  defined $format or 
    throw "Must provide format used to produce blast formatted output";

  $format =~ /^(\d+)/ or throw "Invalid output format, must begin with number";
  my $alignment_view_option = $1;
  $alignment_view_option == 6 || $alignment_view_option == 7 || $alignment_view_option == 10 or 
    throw "Invalid alignment view option: must be either 6, 7 or 10";

  $format =~ s/^\d+?//;
  $format =~ s/^\s+?//;
  # no format specifier detected, set to default: 
  # "qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore"
  # see http://home.cc.umanitoba.ca/~psgendb/birchhomedir/doc/NCBI/blast_formatter.txt
  $format = "qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore"
    unless $format;

  my $delimiter = ($alignment_view_option == 6 or $alignment_view_option == 7)?'\t':',';

  my $self = $class->SUPER::open($filename, 
				 $delimiter, 
				 alignment_view => $alignment_view_option, 
				 format_specifier => $format);
 
  # metadata defaults
  #  if ($self->{'params'}->{'mustReadMetadata'}) { }

  # pre-load peek buffer
  $self->next_block();
    
  return $self;
}

=head2 set_fields

    Description: Setter for list of fields used in this format - uses the
                  "public" (i.e. non-raw) names of getter methods
    Returntype : Void

=cut

sub set_fields {
  my $self = shift;
  my $format = $self->{params}{format_specifier};
  defined $format or throw "Undefined BLAST output format";
  
  $self->{fields} = [ split /\s+/, $format ];

  for (my $i=0; $i<scalar @{$self->{fields}}; $i++) {
    $self->{fields_index}{$self->{fields}[$i]} = $i;
  }
}

1;
