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

use base qw/Bio::EnsEMBL::IO::ColumnBasedParser/;

use Bio::EnsEMBL::Utils::Exception qw/throw/;

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
  
  $self->{'fields'} = [ split /\s/, $format ];
}

1;
