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

Bio::EnsEMBL::IO::Format::Bed - an object that defines and validates BED-based formats

Note that BED is a very complex format with several sub-varieties and flexible field options!
This module defines the standard 3+9 BED format - other derived formats require their own
classes.

=cut

package Bio::EnsEMBL::IO::Format::Bed;

use strict;
use warnings;

use parent qw(Bio::EnsEMBL::IO::Format);

sub new {
  my $class = shift;

  my $self = {
          'name'            => 'Bed',
          'extensions'      => ['bed'],
          'delimiter'       => '\t|\s',
          'can_multitrack'  => 1,
          'can_metadata'    => -1,
          'metadata_info'   => {
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
                                'name' => {
                                                'validate_as' => 'string',
                                                'optional'    => 1,  
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
                                },
            'field_order'   => [qw(chrom chromStart chromEnd name score strand thickStart thickEnd itemRgb blockCount blockSizes blockStarts)],
          };
  bless $self, $class;

  return $self;
}

1;
