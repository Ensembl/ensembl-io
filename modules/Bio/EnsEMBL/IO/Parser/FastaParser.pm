=pod

=head1 LICENSE

  Copyright (c) 1999-2013 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

  http://www.ensembl.org/info/about/code_licence.html

=head1 NAME

Bio::EnsEMBL::IO::Parser::FastaParser - A record-based parser devoted to FASTA format

=head1 DESCRIPTION

  Slurps entire sequence chunks into memory. Handle with care and avoid hanging
  onto too many segments of the file if you value your memory.

=cut

package Bio::EnsEMBL::IO::Parser::FastaParser;

use strict;
use warnings;

use base qw/Bio::EnsEMBL::IO::RecordBasedParser/;

sub new {
    my $caller = shift;
    my $class = ref($caller) || $caller;
    
    my $self = $class->SUPER::new(@_);
    
    $self->{'end_tag'} ||= '>';
    $self->{'start_tag'} ||= '>';
    return $self;
}

1;