=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::IO::Writer;

use strict;
use warnings;
use Carp;
use Scalar::Util qw/openhandle/;

=head2 new

    Constructor
    Returntype   : Bio::EnsEMBL::IO::Writer

=cut

sub new {
  my ($class) = @_;

  my $self = {};
  
  bless $self, $class;

  return $self;

}

=head2 open

    Description: Set the file to write records to, either a filename
                 or an existing file handle
    Args[1]    : A file name or open file handle
    Exceptions : If the file name can't be openned for writing

=cut

sub open {
    my ($self, $file) = @_;

    if(openhandle($file)) {
	$self->{writer_handle} = $file;
    } else {
	CORE::open($self->{writer_handle}, ">$file") ||
	    throw("Error opening output file $file: $@");
    }
}

=head2 close

    Description: Close an existing writer file handle
    Exceptions : If the file handle isn't currently open

=cut

sub close {
    my $self = shift;

    if(openhandle($self->{writer_handle})) {
	CORE::close($self->{writer_handle});
	$self->{writer_handle} = undef;
    } else {
	throw("Error, writing file handle isn't open");
    }

}

=head2 translator

    Type: Setter/getter
    Description: Setter/getter for the translator, the translator is
                 what converts objects in to the requested format
                 based on the subclassing of Writer
    Returntype : Translator object

=cut

sub translator {
  my $self = shift;

  if (@_) {
	  my $translator = shift;
	  $self->{translator} = $translator;
  }

  return $self->{translator};
}

=head2 write

    Description: Dummy writer function for the base class,
                 should be implemented in derived classes

=cut

sub write {
    my $self = shift;

    croak "Not implemented in base writer class";
}

#############################
# OLD CRAP
#############################

=head2 parser

    Description: Accessor for the format-specific parser needed to output data
    Returntype : Bio::EnsEmBL::IO::Parser::<format>

=cut

sub parser {
  my $self = shift;
  return $self->{'parser'};
}

=head2 species_defs

    Description: Accessor for the SpeciesDefs object (for e.g. adding colours to tracks/records)
    Returntype : EnsEmBL::Web::SpeciesDefs

=cut

sub species_defs {
  my $self = shift;
  return $self->{'species_defs'};
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
      confess ("Cannot use $trans_class - data type unknown");
    }
    else {
      $self->{'translator'}{$type} = $trans_class->new($self->species_defs);
      return $self->{'translator'}{$type};
    }
  }
}

=head2 output_dataset

    Description: Outputs a dataset to file
    Args[1]    : Hashref of metadata and array of features
    Returntype : None 

=cut

sub output_dataset {
  my ($self, $datasets) = @_;
  return unless $datasets && scalar(@{$datasets||[]});

  my $sd = $self->species_defs;

  ## open output file
  #$self->open;

  ## process input
  foreach my $set (@$datasets) {
    my $metadata = $set->{'metadata'};
    if ($metadata) {
      $self->output_metadata($metadata);
    }
    my @data = @{$set->{'data'}||[]};
    foreach my $feature (@data) {
      $self->output_feature($feature);
    }
  }

  ## close output file
  #$self->close;
}

=head2 output_metadata

    Description: Converts metadata into the required format and writes it to file 
    Args[1]    : Hashref
    Returntype : None 

=cut

sub output_metadata {
  my ($self, $metadata) = @_;
  my $metadata_content = $self->parser->create_metadata($metadata);
  $self->write($metadata_content);
}

=head2 output_feature

    Description: Converts a single feature into a record and writes it to file
    Args[1]    : Feature object
    Returntype : None 

=cut

sub output_feature {
  my ($self, $feature) = @_;

  my @namespace   = split('::', ref($feature));
  my $ftype       = $namespace[-1];
  my $translator  = $self->get_translator_by_type($ftype);
  my $record      = $self->parser->create_record($translator, $feature); 
  $self->write($record);
}

=head2 write 

    Description  : Outputs one or more lines to the file 
    Returntype   : Void

=cut

#sub write {
#  my ($self, $content) = @_;
#  my $file = $self->{filename};
#  CORE::open my $fh, '>>', $file or confess "Cannot open '${file}' for appending: $!";
#  print $fh $content or confess "Cannot write content to '${file}: $!";
#  CORE::close $fh or confess "Cannot close '${file}: $!";
#  return;
#}

1;
