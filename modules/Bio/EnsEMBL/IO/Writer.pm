=pod

=head1 LICENSE

  Copyright (c) 1999-2013 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

  http://www.ensembl.org/info/about/code_licence.html

=head1 NAME

Writer - An abstract writer class for biological file formats

=cut

package Bio::EnsEMBL::IO::Writer;

use strict;
use warnings;

use Bio::EnsEMBL::Utils::Exception qw/throw/;

=head2 new

    Constructor
    Argument [1] : Format of output file
    Argument [2] : Filename of output file 
    Returntype   : Bio::EnsEMBL::IO::Writer

=cut


sub new {
  my ($class, $format, $filename) = @_;
  $format ||= 'Bed';

  my $parser_class = 'Bio::EnsEMBL::IO::Parser::'.$format;
  eval "require $parser_class";

  if ($@) {
    throw ("Cannot use $parser_class - format unknown ($@)");
  }
  else {
    my $parser = $parser_class->open();
    my $self = {
      'filename'    => $filename,
      'parser'      => $parser,
      'translator'  => {},
    };
  
    bless $self, $class;

    return $self;
  }

}

=head2 parser

    Description: Accessor for the format-specific parser needed to output data
    Returntype : Bio::EnsEmBL::IO::Parser::<format>

=cut

sub parser {
  my $self = shift;
  return $self->{'parser'};
}

=head2 get_translator_by_type

    Description: Accessor for translators needed by data objects
                  N.B. will create a translator if one does not exist
    Returntype : Bio::EnsEmBL::IO::Translator::<object_type>

=cut

sub get_translator_by_type {
  my ($self, $type) = @_;
  if ($self->{'translator'}{$type}) {
    return $self->{'translator'}{$type};
  }
  else {
    my $trans_class = 'Bio::EnsEMBL::IO::Translator::'.$type;
    eval "require $trans_class";

    if ($@) {
      throw ("Cannot use $trans_class - data type unknown");
    }
    else {
      $self->{'translator'}{$type} = new $trans_class;
      return $self->{'translator'}{$type};
    }
  }
}

sub output_file {
  my ($self, $datasets) = @_;
  return unless $datasets && scalar(@{$datasets||[]});

  ## open output file
  $self->open;

  ## process input
  foreach my $set (@$datasets) {
    my $metadata = $set->{'metadata'};
    if ($metadata) {
      my $metadata_content = $self->parser->create_metadata($metadata);
      $self->write($metadata_content);
    }
    my @data = @{$set->{'data'}||[]};
    foreach my $feature (@data) {
      my @namespace = split('::', ref($feature));
      my $ftype = $namespace[-1];
      my $translator = $self->get_translator_by_type($ftype);
      my $record = $self->parser->create_record($translator, $feature); 
      $self->write($record);
    }
  }

  ## close output file
  $self->close;
}

=head2 open

    Description  : Opens the filehandler
    Returntype   : Void

=cut

sub open {
  my $self = shift;
  open(OUTPUT, '>', $self->{'filename'}) || throw("Could not open " . $self->{'filename'});
}

=head2 close

    Description  : Closes the filehandler
    Returntype   : True/False on success/failure

=cut

sub close {
  my $self = shift;
  return close OUTPUT;
}


=head2 write 

    Description  : Outputs one or more lines to the file 
    Returntype   : Void

=cut

sub write {
  my ($self, $content) = @_;
  warn ">>> CONTENT $content";
  print OUTPUT $content;
}

1;
