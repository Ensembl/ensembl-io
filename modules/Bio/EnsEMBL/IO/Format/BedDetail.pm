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

Bio::EnsEMBL::IO::Format::BedDetail - an object that defines and validates bedDetail files 

=cut

package Bio::EnsEMBL::IO::Format::BedDetail;

use strict;
use warnings;

use parent qw(Bio::EnsEMBL::IO::Format);

sub new {
  my $class = shift;

  my $self = {
                'name'            => 'BedDetail',
                'extensions'      => ['bed'],
                'delimiter'       => '\t',
                'can_multitrack'  => 1,
                'can_metadata'    => -1,
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
                                    'description' => {
                                                'optional'    => 1, 
                                                'validate_as' => 'string',
                                              },
                                    'url' => {
                                                'optional'    => 1, 
                                                'validate_as' => 'url',
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
                                    'name' => {
                                                'validate_as' => 'string',
                                                'optional'    => 0,  
                                                },
                                    'score' => {
                                                'validate_as' => 'range',
                                                'match'       => [0, 1000],
                                                'optional'    => 1,  
                                                },
                                    'strand' => {
                                                'validate_as' => 'strand_plusminus',
                                                'optional'    => 1,  
                                                },
                                    'thickStart' => {
                                                'validate_as' => 'integer',
                                                'optional'    => 1,  
                                                },
                                    'thickEnd' => {
                                                'validate_as' => 'integer',
                                                'optional'    => 1,  
                                                },
                                    'itemRgb' => {
                                                'validate_as' => 'rgb_string',
                                                'optional'    => 1,  
                                                },
                                    'blockCount' => {
                                                'validate_as' => 'integer',
                                                'optional'    => 1,  
                                                },
                                    'blockSizes' => {
                                                'validate_as' => 'comma_separated',
                                                'optional'    => 1,  
                                                },
                                    'blockStarts' => {
                                                'validate_as' => 'comma_separated',
                                                'optional'    => 1,  
                                                },
                                    'id' => {
                                                'validate_as' => 'string',
                                                'optional'    => 0,  
                                                },
                                    'description' => {
                                                'validate_as' => 'html',
                                                'optional'    => 0,  
                                                },
                                    },
                'field_order'   => [qw(chrom chromStart chromEnd name score strand thickStart thickEnd itemRgb blockCount blockSizes blockStarts id description)],
              };
  bless $self, $class;

  return $self;
}

1;
