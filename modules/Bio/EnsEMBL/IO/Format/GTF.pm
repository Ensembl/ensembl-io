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

Bio::EnsEMBL::IO::Format::GTF - an object that defines and validates GTF-based formats

=cut

package Bio::EnsEMBL::IO::Format::GTF;

use strict;
use warnings;

use parent qw(Bio::EnsEMBL::IO::Format);

my %strand_mapping = (1 => '+', -1 => '-');

sub new {
  my $class = shift;

  my $self = {
              'name'            => 'GTF',
              'extensions'      => ['gtf'],
              'delimiter'       => "\t",
              'delimiter_regex' => '\t',
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
                                  'seqname' => {
                                                'validate_as' => 'string',
                                                'optional'    => 0,
                                                },
                                  'source' => {
                                                'validate_as' => 'string',
                                                'optional'    => 0,
                                                },
                                  'feature' => {
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
                                              'optional'    => 1,
                                              },

                                  'strand' => {
                                              'validate_as' => 'strand_plusminus',
                                              'optional'    => 1,
                                              },
                                  'frame' => {
                                              'validate_as' => 'phase',
                                              'optional'    => 1,
                                              },
                                  'attribute' => {
                                                  'validate_as' => 'string',
                                                  'optional'    => 1,
                                                  'accessor'    => 'gtf_attributes',
                                                },
                                    },
            'field_order'   => [qw(seqname source feature start end score strand frame attribute)],
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
