=pod

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

=head1 NAME

Bio::EnsEMBL::IO::Format::GFF3 - an object that defines and validates GFF3-based formats

=cut

package Bio::EnsEMBL::IO::Format::GFF3;

use strict;
use warnings;

use parent qw(Bio::EnsEMBL::IO::Format);

my %strand_mapping = (1 => '+', -1 => '-');

sub new {
  my $class = shift;

  my $self = {
              'name'            => 'GFF3',
              'extensions'      => ['gff', 'gff3'],
              'delimiter'       => "\t",
              'delimiter_regex' => '\t',
              'empty_column'    => '.',
              'can_multitrack'  => 0,
              'can_metadata'    => 1,
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
                                            'validate_as' => 'string',
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
                                'attributes' => {
                                                'validate_as' => 'string',
                                                'optional'    => 0,
                                                },
                                  },
            'field_order'   => [qw(seqname source type start end score strand phase attributes)],
          };

  bless $self, $class;
};

=head2 strand_conversion

    Description: Access the strand conversion mappings

=cut

sub strand_conversion {
  my $self = shift;
  
  return \%strand_mapping;
}

1;
