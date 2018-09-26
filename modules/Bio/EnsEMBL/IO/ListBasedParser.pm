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

Bio::EnsEMBL::IO::ListBasedParser - A line-based parser for simple lists of e.g. feature IDs

=cut

package Bio::EnsEMBL::IO::ListBasedParser;

use strict;
use warnings;

use base qw/Bio::EnsEMBL::IO::TextParser/;

=head2 open

    Constructor
    Argument [1] : Filepath
    Argument [2+]: Hash of parameters for configuration, e.g. buffer sizes or 
                   specific functions for handling headers or data
    Returntype   : Bio::EnsEMBL::IO::TrackBasedParser

=cut

sub open {
    my ($caller, $filename, @other_args) = @_;
    my $class = ref($caller) || $caller;
    my $self;

    $self = $class->SUPER::open($filename, @other_args);

    if ($filename) {
      # pre-load peek buffer
      $self->next_block();
    }

    return $self;
}

## This format has no metadata

sub is_metadata { return undef; }

sub read_metadata { return undef; }

=head2 read_record

    Description: Returns current block. Since this format has only one column, 
                  no further processing is needed  
    Returntype : String 

=cut

sub read_record {
  my $self = shift;
  chomp $self->{'current_block'};
  $self->{'record'} = $self->{'current_block'};
}

=head2 get_raw_value

    Description: Getter for single column value
    Returntype : String

=cut

sub get_raw_value {
  my $self = shift;
  return $self->{'record'};
}

=head2 get_value

    Description: Getter - wrapper around get_raw_value
    Returntype : String

=cut

sub get_value {
  my $self = shift;
  return $self->get_raw_value; 
}

1;
