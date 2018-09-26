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

Bio::EnsEMBL::IO::Format::BedGraph - an object that defines and validates bedGraph files 

=cut

package Bio::EnsEMBL::IO::Format::BedGraph;

use strict;
use warnings;

use parent qw(Bio::EnsEMBL::IO::Format);

sub new {
  my $class = shift;

  my $self = {
                'name'            => 'BedGraph',
                'extensions'      => ['bed'],
                'delimiter'       => '\t|\s',
                'can_multitrack'  => 1,
                'can_metadata'    => 1,
                'metadata_info'   => {
                                    'type' => {
                                                'optional'    => 0,
                                                'validate_as' => 'string',
                                                'match'       => 'bedDetail',
                                              },
                                    'name' => {
                                                'optional'    => 1, 
                                                'validate_as' => 'string',
                                                'unique'      => 1,
                                              },
                                    'url' => {
                                                'optional'    => 1,
                                                'validate_as' => 'url',
                                              },
                                    'description' => {
                                                'optional'    => 1, 
                                                'validate_as' => 'string',
                                              },
                                    'priority' => {
                                                'optional'    => 1, 
                                                'validate_as' => 'integer',
                                              },
                                    'colour' => {
                                                'optional'    => 1, 
                                                'validate_as' => 'colour',
                                              },
                                    'itemRgb' => {
                                                'optional'    => 1, 
                                                'validate_as' => 'case_insensitive',
                                                'match'       => 'on',
                                              },
                                    'useScore' => {
                                                'optional'    => 1, 
                                                'validate_as' => 'boolean',
                                              },
                                  
                                    },
                'field_info'    => {
                                    'chrom' => {
                                                'validate_as' => 'string',
                                                'optional'    => 0,  
                                                },
                                    'chromStart' => {
                                                'validate_as' => 'integer',
                                                'optional'    => 0,  
                                                },
                                    'chromEnd' => {
                                                'validate_as' => 'integer',
                                                'optional'    => 0,  
                                                },
                                    'score' => {
                                                'validate_as' => 'floating_point',
                                                'optional'    => 0,  
                                                },
                                    },
                'field_order'   => [qw(chrom chromStart chromEnd score)],
  };

  bless $self, $class;

  return $self;
}


1;
