=pod

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

=head1 NAME

Parser - An abstract parser class

If you are extending this class you need to implement:
- open: opens stream
- close: closes stream
- read_block: reads a line/record/atomic piece of data, return scalar
- is_metadata: determines whether $self->{current_block} is metadata
- read_metadata: reads $self->{current_block}, stores relevant data in $self->{metadata} hash ref
- read_record: reads $self->{current_block}, possibly invoking $self->next_block(), stores list in $self->{record}
- a bunch of getters.

Optionally, you may want to implement:
- seek: seeks coordinate in sorted/indexed file

=cut

package Bio::EnsEMBL::IO::Parser;

use strict;
use warnings;

use Carp;
use Bio::EnsEMBL::IO::Utils;

=head2 new

    Constructor
    Argument [1+]: Hash of parameters for configuration, e.g. buffer sizes or 
                   specific functions for handling headers or data
    Returntype   : Bio::EnsEMBL::IO::Parser

=cut

sub new {
    my $class = shift;
    my %param_hash = @_;
    
    my $self = {
	    current_block     => undef,
	    waiting_block     => undef,
	    record            => undef,
	    metadata          => {},
      errors            => {},
	    params            => \%param_hash,
    	metadata_changed  => 0,
      strand_conversion => {'+' => '1', '.' => '0', '-' => '-1'},
    };

    # By default metadata is read and parsed
    if (not exists $self->{'params'}->{'must_parse_metadata'}) {
	    $self->{'params'}->{'must_parse_metadata'} = 1;
    }

    bless $self, $class;
   
    return $self;
}

=head2 errors

    Description : Accessor for any errors recorded during parsing
    Returntype  : Hashref

=cut

sub errors {
  my $self = shift;
  return $self->{'errors'} || {};
}

=head2 shift_block

    Description: Wrapper for user defined functions 
                 Loads the buffered data as current, then stores a new block of data
                 into the waiting buffer.
    Returntype : Void

=cut

sub shift_block {
    my $self = shift;
    $self->{'current_block'} = $self->{'waiting_block'};
    $self->{'waiting_block'} = $self->read_block();
}

=head2 next_block

    Description: Wrapper for user defined functions 
                 Goes through the file blocks, either skipping or parsing metadata blocks
    Returntype : Void

=cut

sub next_block {
    my $self = shift;
    $self->shift_block();
    $self->{'metadata_changed'} = 0;
    while( defined $self->{'current_block'} && $self->is_metadata() ) {
      if ($self->{'params'}->{'must_parse_metadata'}) {
        $self->read_metadata();
	      $self->{'metadata_changed'} = 1;
      }
      $self->shift_block();
    }
}

=head2 next

    Description: Business logic of the iterator
                 Reads blocks of data from the file, determines whether they contain 
                 metadata or an actual record, optionally processes the metadata, and
                 terminates when a record has been loaded.
    Returntype : True/False depending on whether a record was found.

=cut

sub next {
    my $self = shift;

    $self->{'record'} = undef;
    $self->next_block();

    if (defined $self->{'current_block'}) {
        $self->read_record();
        return 1;
    } else {
        return 0;
    }
}

=head2 metadataChanged 

    Description: whether metadata was changed since the previous record
    Returntype : Boolean 

=cut

sub metadataChanged {
    my $self = shift;
    return $self->{'metadata_changed'};
}

=head2 seek

    Description: Placeholder for user-defined seek function.
                 Function must allow the user to request that all the subsequent 
                 records be part of a given genomic region.
    Returntype : Void

=cut

sub seek {
    confess("Method not implemented. Might not be applicable to your file format.");
}

=head2 read_block

    Description: Placeholder for user-defined IO function.
                 Function must obtain and store the next block (e.g. line) of data from
                 the file.
    Returntype : Void 

=cut

sub read_block {
    confess("Method not implemented. This is really important");
}

=head2 is_metadata

    Description: Placeholder for user-defined metadata function.
                 Function must determine whether $self->{'current_block'}
                 contains metadata or not.
    Returntype : Boolean

=cut

sub is_metadata {
    confess("Method not implemented. This is really important");
}

=head2 read_metadata

    Description: Placeholder for user-defined metadata function.
                 Function must go through $self-{'current_block'},
                 extract relevant metadata, and store it in 
                 $self->{'metadata'}
    Returntype : Boolean

=cut

sub read_metadata {
    confess("Method not implemented. This is really important");
}

=head2 read_record

    Description: Placeholder for user-defined record lexing function.
                 Function must pre-process the data in $self->current block so that it is
                 readily available to accessor methods.
    Returntype : Void 

=cut

sub read_record {
    confess("Method not implemented. This is really important");
}

=head2 open

    Description: Placeholder for user-defined filehandling function.
                 Function must prepare input streams.
    Returntype : True/False on success/failure

=cut

sub open {
    confess("Method not implemented. This is really important");
}


=head2 close

    Description: Placeholder for user-defined filehandling function.
                 Function must close all open input streams.
    Returntype : True/False on success/failure

=cut

sub close {
    confess("Method not implemented. This is really important");
}

=head2 open_as

    Description: Wrapper function to demand format as a parameter
    Returntype : Parser object

=cut

sub open_as {
    my ($format, @other_args) = @_;
    return _open_as($format, 'open', @other_args);
}

=head2 open_content_as

    Description: Wrapper function to demand format as a parameter
    Returntype : Parser object

=cut

sub open_content_as {
    my ($format, @other_args) = @_;
    return _open_as($format, 'open_content', @other_args);
}

=head2 _open

    Description: Wrapper function to demand format as a parameter
    Returntype : Parser object

=cut

sub _open_as {
    my ($format, $method, @other_args) = @_;

    ## Map user-input file format to correct case for parser

    my %format_to_class = Bio::EnsEMBL::IO::Utils::format_to_class;

    my $subclass = $format_to_class{lc($format)};

    if ($subclass) {
      my $class = 'Bio::EnsEMBL::IO::Parser::'.$subclass;
      eval "require $class";
      if ($@) {
      }
      else {
        my $object = eval { $class->$method(@other_args); }; 
        return $object;
      }
    }
}

=head format

    Description : Setter/getter for format object
    Returntype  : Bio::EnsEMBL::IO::Format object

=cut

sub format {
  my ($self, $format) = @_;
  if ($format && ref($format) =~ /Bio::EnsEMBL::IO::Format/) {
    $self->{'format'} = $format;
  }
  return $self->{'format'};
}

1;
