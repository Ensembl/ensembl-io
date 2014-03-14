=pod

=head1 LICENSE

  Copyright (c) 1999-2013 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

  http://www.ensembl.org/info/about/code_licence.html

=head1 NAME

Translator - An abstract class to translate accessor methods between API objects and parsers

=cut

package Bio::EnsEMBL::IO::Translator;

use strict;
use warnings;

use Bio::EnsEMBL::Utils::Exception qw/throw/;

=head2 new

    Constructor
    Returntype   : Bio::EnsEMBL::IO::Translator

=cut

sub new {
  my $class = shift;

  my $self = {};
  bless $self, $class;
  return $self;
}

1;
