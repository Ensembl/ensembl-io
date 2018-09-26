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

=cut


=head1 NAME

Bio::EnsEMBL::IO::Parser::VCF4 - A line-based parser devoted to VCF format version 4.2

=cut

=head1 DESCRIPTION

The Variant Call Format (VCF) specification for the version 4.2 is available at the following adress:
http://samtools.github.io/hts-specs/VCFv4.2.pdf

=cut

package Bio::EnsEMBL::IO::Parser::VCF4;

use strict;
use warnings;

use base qw/Bio::EnsEMBL::IO::Parser::BaseVCF4/;


sub open {
    my ($caller, $filename, @other_args) = @_;
    my $class = ref($caller) || $caller;

    my $delimiter = "\\t";
    my $self = $class->SUPER::open($filename, $delimiter, @other_args);
    
    # pre-load peek buffer
    $self->next_block();

    return $self;
}

1;
