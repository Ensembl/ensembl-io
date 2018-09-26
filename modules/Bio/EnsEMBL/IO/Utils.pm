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

=cut

package Bio::EnsEMBL::IO::Utils;

use strict;
use warnings;

sub format_to_class {
  return (
          'bam'             => 'Bam',
          'bed'             => 'Bed',
          'bedgraph'        => 'Bed',
          'bigbed'          => 'BigBed',
          'bigwig'          => 'BigWig',
          'emf'             => 'EMF',
          'fasta'           => 'Fasta',
          'gff'             => 'GTF',
          'gff3'            => 'GFF3',
          'gtf'             => 'GTF',
          'gvf'             => 'GVF',
          'pairwise'        => 'PairwiseSimple',
          'pairwisetabix'   => 'PairwiseTabix',
          'psl'             => 'Psl',
          'vcf'             => 'VCF4',
          'vcf4tabix'       => 'VCF4Tabix',
          'vep_input'       => 'VEP_input',
          'vep_output'      => 'VEP_output',
          'wig'             => 'Wig',
          );
}

1;
