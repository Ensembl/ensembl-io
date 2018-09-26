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

Bio::EnsEMBL::IO::Format::VCF4 - an object that defines and validates VCF4 format

=cut

package Bio::EnsEMBL::IO::Format::VCF4;

use strict;
use warnings;

use parent qw(Bio::EnsEMBL::IO::Format);

sub new {
  my $class = shift;

  my $self = {
          'name'            => 'VCF4',
          'extensions'      => ['vcf'],
          'delimiter'       => '\\t',
          'can_multitrack'  => 1,
          'can_metadata'    => -1,
          'metadata_info'   => {
              'INFO' => {
                  'optional'    => 1, 
                  'validate_as' => 'string'
              },
              'FILTER' => {
                  'optional'    => 1,
                  'validate_as' => 'string'
              },
              'FORMAT' => {
                  'optional'    => 1, 
                  'validate_as' => 'string'
              },
              'ALT' => {
                  'optional'    => 1, 
                  'validate_as' => 'string'
              },
              'SAMPLE' => {
                  'optional'    => 1, 
                  'validate_as' => 'string'
              },
              'PEDIGREE' => {
                  'optional'    => 1, 
                  'validate_as' => 'string'
              }
          },
          'field_info'    => {
              'seqname' => {
                  'validate_as' => 'string',
                  'optional'    => 0  
              },
              'start' => {
                  'validate_as' => 'integer',
                  'optional'    => 0  
              },
              'IDs' => {
                  'validate_as' => 'string',
                  'optional'    => 0  
              },
              'reference' => {
                  'validate_as' => 'string',
                  'optional'    => 0  
              },
              'alternatives' => {
                  'validate_as' => 'string',
                  'optional'    => 0  
              },
              'score' => {
                  'validate_as' => 'string',
                  'optional'    => 0  
              },
              'filter_results' => {
                  'validate_as' => 'string',
                  'optional'    => 0  
              },
              'info' => {
                  'validate_as' => 'string',
                  'optional'    => 0  
              }
          },
          'field_order'   => [qw(seqname start IDs reference alternatives score filter_results info)],
  };

  bless $self, $class;

  return $self;
}

1;
