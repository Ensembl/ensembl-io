=pod

=head1 LICENSE

  Copyright (c) 1999-2013 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

  http://www.ensembl.org/info/about/code_licence.html

=head1 NAME

Parser - An abstract parser class

=cut

package Bio::EnsEMBL::IO::Parser;

use strict;
use warnings;

use Bio::EnsEMBL::Utils::Exception qw/throw/;
use Bio::EnsEMBL::Utils::Scalar qw/assert_ref/;

=head2 new

    Constructor
    Argument [1] : IO::File object
    Argument [2+]: Hash of parameters for configuration, e.g. buffer sizes or 
                   specific functions for handling headers or data
    Returntype   : Bio::EnsEMBL::IO::Parser

=cut

sub new {
    my $class = shift;
    my $fh = shift;
    my %param_hash = @_;
    
    my $self = {
        filehandle => $fh,
        %param_hash,
    };
    bless $self, $class;
    if (exists $self->{'metadata_function'}) {
        $self->set_metadata_function($self->{'metadata_function'});
    } else {
        $self->set_metadata_function(\&default_meta);
    }
    
    if (exists $self->{'data_function'}) {
        $self->set_data_function($self->{'data_function'});
    }
    
    # pre-load peek buffer
    $self->{'next_line'} = <$fh> || throw "Unable to access file $fh for reading";
    chomp($self->{'next_line'});
    
    return $self;
}

=head2 read_record
    Arg [1]    : One lump of data.
    Description: Read a single record from the file, whatever format it may take
                 Parsers will have a default returnvalue for the data, but are
                 intended to use a provided processor function to handle the
                 specifics. See set_data_function() and process_record()
                 
                 Metadata and headers are detected and handled by spot_metadata()
                 inside a read_record call.
    Returntype : Data structure suited to the type of parser

=cut

sub read_record {
    throw("Method not implemented. This is really important");
        
}

sub seek_record {
    throw("Method not implemented");
}

=head2 spot_metadata
    Arg [1]    : String containing the line contents
    Description: Calling wrapper for user-defined metadata functions. See also
                 set_metadata_function and default_meta
    Returntype : Boolean
=cut

sub spot_metadata {
    my $self = shift;
    my $line = shift;
    my $function = $self->metadata_function;
    return $function->($line);
}

=head2 set_metadata_function
    Arg [1]     : Coderef pointing to the subroutine that processes metadata
    Description : Sets the metadata processing function for the parser.
                  
    Example     : # The subroutine should take the form of:             
                  sub {
                      my $line = shift;
                      # detect the presence of metadata
                      my $meta = $line if ($meta=~/^#/);
                      #Êmake an early exit if no meta
                      unless ($meta) {return}
                      # process the meta from scope of your code
                      $meta =~ /gene_id=(.*);/;
                      $self->gene_id($1);
                      # $self refers to your object, not the parser
                      $variable_in_caller_scope = $meta;
                      return 1;
                      # announce to the parser that you found metadata
                  }
=cut

sub set_metadata_function {
    my $self = shift;
    my $new_function = shift;
    assert_ref($new_function,'CODE','metadata function');
    $self->{'metadata_function'} = $new_function;
    return;
}

sub metadata_function {
    my $self = shift;
    return $self->{'metadata_function'};
}

sub default_meta {
    my $line = shift;
    if ($line =~ /^track/ || $line =~ /^\s*#/) {
        return 1;
    }
    return;
}

sub data_function {
    my $self = shift;
    return $self->{'data_function'};
}

=head2 set_data_function
    Arg [1]     : Coderef for a subroutine that handles the data passing by
    Description : Used to supply a custom handler for the data in the file.
                  Any provided function *must* return a value if all has gone
                  to plan and a record has been read.
=cut

sub set_data_function {
    my $self = shift;
    my $new_function = shift;
    assert_ref($new_function,'CODE','data function');
    $self->{'data_function'} = $new_function;
    return;
}

sub process_record {
    my $self = shift;
    my $record = shift;
    my $function = $self->data_function;
    # ERM... not sure whether this is a good idea or not.
    return $function->($record);
}


sub read_line {
    my $self = shift;
    
    my $fh = $self->{'filehandle'};
    my $new_line;
    if (!eof($fh)) {
        $new_line = <$fh> || throw ("Error reading file handle: $!");   
    }    
    $self->{'current_line'} = $self->{'next_line'};
    unless (defined ($self->{'current_line'})) { return; }
    chomp ($new_line) if defined $new_line;
    $self->{'next_line'} = $new_line;
    return 1;
}

sub this_line {
    my $self = shift;
    return $self->{'current_line'};
}

sub next_line {
    my $self = shift;
    return $self->{'next_line'};
}

1;