=pod

=head1 LICENSE

  Copyright (c) 1999-2013 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

  http://www.ensembl.org/info/about/code_licence.html

=cut

package Bio::EnsEMBL::IO::Utils;

use strict;
use warnings;

sub format_to_class {
  return (
          'bed'     => 'Bed',
          'bigbed'  => 'BigBed',
          'bigwig'  => 'BigWig',
          'emf'     => 'EMF',
          'fasta'   => 'Fasta',
          'gff'     => 'GFF3',
          'gff3'    => 'GFF3',
          'gvf'     => 'GVF',
          'psl'     => 'PSL',
          'wig'     => 'Wig',
          );
}

1;
