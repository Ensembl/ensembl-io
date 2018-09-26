=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2018] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut


=head1 CONTACT

  Please email comments or questions to the public Ensembl
  developers list at <http://lists.ensembl.org/mailman/listinfo/dev>.

  Questions may also be sent to the Ensembl help desk at
  <http://www.ensembl.org/Help/Contact>.

=cut

=head1 NAME

Bio::EnsEMBL::IO::Parser::BLASTFormatter - Parser for blast formatted output

=head1 SYNOPSIS

  my $blast_formatted_output_format = '...';
  my $blast_output_file = '...';

  my $parser = 
    Bio::EnsEMBL::IO::Parser::BLASTFormatter->open($blast_output_file, 
                                                   $blast_formatted_output_format);

  while($parser->next()) {
    # access current record fields, where the 
    # fields have been specified in output format, e.g.:
    print $parser->get_qseqid, "\n";
    print $parser->get_sseqid, "\n";
    print $parser->get_score, "\n";
    print $parser->get_evalue, "\n";
    etc.
  }
  
=head1 DESCRIPTION

This is a parser of BLAST+ applications (e.g. blast_formatter) formatted outputs.

WARNING: 
Support is only provided for a LIMITED number of ouptut formats, the column based ones.

In other words, this parser will only correctly parse output files which have been
produced by a BLAST+ application by specifying one of the following "alignment view options":

- 6: tabular

- 7: tabular with comment lines

- 10: comma-separated values

The parser's "open" method understand two arguments, the first is the name of the file to
parse, and the second is the same string as the output format given to the BLAST+ application 
with the option '-outfmt'.

Valid output formats are those containing just the alignment view option with no format specifiers, 
e.g. '6', '7' or '10', in which case the parser will parse the columns as if they were in
the order of the blast_formatter default format specifiers:

'seqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore',

or will parse the columns as if they were in the order specified in the open method second
argument, e.g.:

 '7 qacc sacc evalue score nident pident qstart qend sstart send length positive ppos qseq sseq'

will parse qacc, sacc, ... separated by tabs.

IMPORTANT:
The parser automatically generates get_raw_[field_name] and get_[field_name] accessor methods
for [field_name], where [field_name] is the name of a format specifier specified in the output
format string.

Invoking a getter method for a field which is not in the output format raises an exception. 

=head1 SEE ALSO

blast_formatter documentation for a list of supported format specifiers:
http://home.cc.umanitoba.ca/~psgendb/birchhomedir/doc/NCBI/blast_formatter.txt

BLAST command line applicatios user manual:
http://www.ncbi.nlm.nih.gov/books/NBK1763/

=head1 METHODS

=cut

package Bio::EnsEMBL::IO::Parser::BLASTFormatter;

use strict;
use warnings;
use Carp;

use base qw/Bio::EnsEMBL::IO::ColumnBasedParser/;
our ($AUTOLOAD);

=head2 open

  Arg [1]    : String; name of the blast output file to parse.
  Arg [2]    : String; output format
  Description: Open a blast formatted output file for parsing
               and return a parser for it.
  Exceptions : If required arguments are not provided, file does 
               not exist or is not readable, invalid output format
               is given (does not begin with '6', '7' or '10'.
  Returntype : Instance of type Bio::EnsEMBL::IO::Parser::BLASTFormatted 
  Caller     : General
  Status     : Stable

=cut

sub open {
  my ($caller, $filename, $format, @other_args) = @_;
  my $class = ref($caller) || $caller;
 
  defined $filename or 
    confess "Must provide name of the file to parse";
  -e $filename and -f $filename or
    confess "Check file $filename exists and is readable";

  defined $format or 
    confess "Must provide format used to produce blast formatted output";

  $format =~ /^(\d+)/ or confess "Invalid output format, must begin with number";
  my $alignment_view_option = $1;
  $alignment_view_option == 6 || $alignment_view_option == 7 || $alignment_view_option == 10 or 
    confess "Invalid alignment view option: must be either 6, 7 or 10";

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
				 format_specifier => $format,
				 must_parse_metadata => 0);
 
  # metadata defaults
  #  if ($self->{'params'}->{'must_parse_metadata'}) { }

  # pre-load peek buffer
  $self->next_block();
    
  return $self;
}

=head2 set_fields

  Arg []     : None
  Description: Setter for list of fields specified in the provided format.
  Exceptions : If unable to read the format.
  Returntype : None
  Caller     : Base class
  Status     : Stable

=cut

sub set_fields {
  my $self = shift;
  my $format = $self->{params}{format_specifier};
  defined $format or confess "Undefined BLAST output format";
  
  $self->{fields} = [ split /\s+/, $format ];

  for (my $i=0; $i<scalar @{$self->{fields}}; $i++) {
    $self->{fields_index}{$self->{fields}[$i]} = $i;
  }
}

=head2 is_metadata

  Arg []     : None
  Description: Returns true is currently parsed line is metadata
  Exceptions : None
  Returntype : None
  Caller     : Parent class
  Status     : Stable

=cut

sub is_metadata {
  my $self = shift;
  return $self->{'current_block'} =~ /^#/;
}

=head2 get_raw_[field_name], get_[field_name

  Arg []      : None
  Description : Accessor method for [field_name] field in current record.
                The accessor method for a format specifier is automatically generated 
                when the user invokes a get_raw_[field_name] or get_[field_name] method,
                IF AND ONLY IF the format specifier is in the output format specified
                in the open function.
  Exceptions  : If the 
  Returntype  : The value of the corresponding field in the current record.
  Caller      : General
  Status      : Stable

=cut 

sub AUTOLOAD {
  my $self = shift;
  my $method = $AUTOLOAD;
  $method =~ s/.*:://;

  return if $method !~ /^get_/;

  $method =~ /get_raw_(.+?)$/;
  $method =~ /get_(.+?)$/ unless $1;
  my $attr = $1;
  
  confess("Invalid attribute method: ->$method()") 
    unless exists $self->{fields_index}{$attr};
  
  confess "Cannot get attribute $attr, record is empty"
    unless $self->{record};

  return $self->_trim($self->{record}[$self->{fields_index}{$attr}]);
}

=head1 PRIVATE METHODS

=head2 _trim

  Arg [1]    : String; the string to trim whitespaces from.
  Description: Trim whitespaces from a string.
  Exceptions : None
  Returntype : String; the trimmed string.
  Caller     : Used internally
  Status     : Stable

=cut

sub _trim {
  my $self = shift;
  (my $s = $_[0]) =~ s/^\s+|\s+$//g;
  return $s;
}

1;
