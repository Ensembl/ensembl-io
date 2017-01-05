=pod

=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

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

Bio::EnsEMBL::IO::Format::GFF3 - an object that defines and validates GFF3-based formats

=cut

package Bio::EnsEMBL::IO::Format::GFF3;

use strict;
use warnings;

use parent qw(Bio::EnsEMBL::IO::Format);

sub new {
  my $class = shift;

  my $self = {
              'name'            => 'GFF3',
              'extensions'      => ['gff', 'gff3'],
              'delimiters'      => ["\t"],
              'empty_column'    => '.',
              'can_multitrack'  => 1,
              'can_metadata'    => -1,
              'metadata_info'   => {
                                    'name' => {
                                                'optional'    => 1,
                                                'validate_as' => 'string',
                                                'unique'      => 1,
                                              },
                                    'description' => {
                                                      'optional'    => 1,
                                                      'validate_as' => 'string',
                                                    },
                                    'priority' => {
                                                    'optional'    => 1,
                                                    'validate_as' => 'integer',
                                                  },
                                    },
            'field_info'    => {
                                'seqid' => {
                                            'validate_as' => 'string',
                                            'optional'    => 0,
                                            'accessor'    => 'seqname',
                                            },
                                'source' => {
                                                'validate_as' => 'string',
                                                'optional'    => 0,
                                                },
                                'type' => {
                                            'validate_as' => 'gtf_feature',
                                            'optional'    => 0,
                                            },
                                'start' => {
                                            'validate_as' => 'integer',
                                            'optional'    => 0,
                                           },
                                'end' => {
                                            'validate_as' => 'integer',
                                            'optional'    => 0,
                                          },
                                'score' => {
                                            'validate_as' => 'floating_point',
                                            'optional'    => 0,
                                            },

                                'strand' => {
                                              'validate_as' => 'strand_plusminus',
                                              'optional'    => 0,
                                              },
                                'phase' => {
                                              'validate_as' => 'phase',
                                              'optional'    => 0,
                                              },
                                'attribute' => {
                                                'validate_as' => 'gtf_attribute',
                                                'optional'    => 1,
                                                },
                                  },
            'field_order'   => [qw(seqname source feature start end score strand frame attribute)],
          };

  bless $self, $class;
};

=head2 validate_as_gtf_feature 

    Description : Validator for GFF3 'feature' column 
    Args        : Value - value to be checked
    Returntype  : Boolean

=cut

sub validate_as_gtf_feature {
  my ($self, $value) = @_;
  
  return $value =~ /CDS|start_codon|stop_codon|5UTR|3UTR|inter|inter_CNS|intron_CNS|exon/ ? 1 : 0;
}

=head2 validate_as_gtf_attribute 

    Description : Validator for GFF3 'attribute' column 
    Args        : Value - value to be checked
    Returntype  : Boolean

=cut

sub validate_as_gtf_feature {
  my ($self, $value) = @_;
  
  return ($value =~ /gene_id/ && $value =~ /transcript_id) ? 1 : 0;
}


1;
