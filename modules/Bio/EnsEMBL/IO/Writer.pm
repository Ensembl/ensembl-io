=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2020] EMBL-European Bioinformatics Institute

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
                 what fetches information from Ensembl objects
                 appropriate for the file format being written
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

=head2 format

    Type: Setter/getter
    Description: Setter/getter for the format, which contains
                 the definition for a file format
    Returntype : Format object

=cut

sub format {
  my $self = shift;

  if (@_) {
	  my $format = shift;
	  $self->{format} = $format;
  }

  return $self->{format};
}

=head2 write

    Description: Dummy writer function for the base class,
                 should be implemented in derived classes

=cut

sub write {
    my $self = shift;

    croak "Not implemented in base writer class";
}

1;
