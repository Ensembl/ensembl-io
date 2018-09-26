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

TextParser - An abstract line by line parser class

An extension of the Parser class that implements open, close, and read_block for text files.

If you are extending this class you need to implement:
- is_metadata: determines whether $self->{current_block} is metadata
- read_metadata: reads $self->{current_block}, stores relevant data in $self->{metadata} hash ref
- read_record: reads $self->{current_block}, possibly invoking $self->next_block(), stores list in $self->{record}
- a bunch of getters.

Optionally, you may want to implement:
- seek: seeks coordinate in sorted/indexed file

=cut

package Bio::EnsEMBL::IO::TextParser;

use strict;
use warnings;

use Carp;
use Scalar::Util qw/openhandle/;

use base qw/Bio::EnsEMBL::IO::Parser/;

=head2 open

    Constructor
    Argument [1] : Filepath or GLOB or open filehandle
    Argument [2+]: Hash of parameters for configuration, e.g. buffer sizes or 
                   specific functions for handling headers or data
    Returntype   : Bio::EnsEMBL::IO::TextParser

=cut

sub open {
    my ($caller, $filename, @other_args) = @_;
    my $class = ref($caller) || $caller;

    my $self = $class->SUPER::new(@other_args);
    if ($filename) {
      # If it was an open handle just set it
      if(openhandle($filename)) {
        $self->{filehandle} = $filename; 
      }
      # Or open
      else {
        $self->{'filename'} = $filename;
        CORE::open($self->{'filehandle'}, $filename) || confess("Could not open " . $filename);
      }
    }
    return $self->{'filehandle'} ? $self : undef;
}

=head2 open_content

    Constructor
    Argument [1] : Content
    Argument [2+]: Hash of parameters for configuration, e.g. buffer sizes or 
                   specific functions for handling headers or data
    Returntype   : Bio::EnsEMBL::IO::TextParser

=cut

sub open_content {
    my ($caller, $content, @other_args) = @_;
    my $fh = undef;
    if($content) {
      CORE::open($fh, '<', \$content) or confess("Could not open in-memory file: $!");      
    }
    return $caller->open($fh, @other_args);
}

=head2 close

    Description  : Closes the filehandler
    Returntype   : True/False on success/failure

=cut

sub close {
    my $self = shift;
    return close $self->{'filehandle'};
}

=head2 read_block

    Description : Reads a line of text, stores it into next_block, 
                  moving next_block to current_block.
    Returntype   : True/False on existence of a defined current_block after running.

=cut

sub read_block {
    my $self = shift;
    my $fh = $self->{'filehandle'};
    return 0 unless $fh;

    if (eof($fh) || $self->{'_reached_eof'}) {
        $self->{'waiting_block'} = undef;
        delete $self->{'_reached_eof'};
        delete $self->{'_read_fh_ok'};
    } else {
        $self->{'waiting_block'} = <$fh>;

        if($self->{'waiting_block'}) {
            $self->{'_read_fh_ok'} = 1;
        } else {
            if($self->{'_read_fh_ok'}) {
                $self->{'_reached_eof'} = 1;
            } else {
                confess ("Error reading file handle: $!");
            }
        }
    }    

    $self->{'waiting_block'} =~ s/\r\n/\n/ if $self->{'waiting_block'};
    return $self->{'waiting_block'};
}

=head2 reset

    Description : Resets the filehandle to the beginning of the file
    Returntype  : True/False based on success/failure

=cut

sub reset {
    my $self = shift;
    my $fh = $self->{'filehandle'};
    return 0 unless $fh;
    seek($fh, 0, 0);
    return 1;
}

1;
