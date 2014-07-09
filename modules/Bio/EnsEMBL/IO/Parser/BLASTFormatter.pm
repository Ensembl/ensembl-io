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

  $format =~ /^(\d+?)/ or throw "Invalid format specifier, must begin with number";
  my $format_specifier = $1;
  $format_specifier == 6 || $format_specifier == 7 || $format_specifier == 10 or 
    throw "Invalid format specifier: must be either 6, 7 or 10";

  my $delimiter;
  ($format_specifier == 6 or $format_specifier == 7 and $delimiter = '\t') or # 6|7: tab-separated
    $delimiter = ','; # 10: comma-separated
  
  my $self = $class->SUPER::open($filename, $delimiter, @other_args);

  # metadata defaults
  if ($self->{'params'}->{'mustReadMetadata'}) {
  }

  # pre-load peek buffer
  $self->next_block();
    
  return $self;
}


1;
