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

Bio::EnsEMBL::IO::Writer::GTF - Generic GTF Writer

=head1 SYNOPSIS

  use Bio::EnsEMBL::IO::Writer::GTF;

  my $writer = Bio::EnsEMBL::IO::Writer::GTF->new($translator);

  $writer->write($object);

=head1 Description

  Write records out in GTF format. The module uses a translator given
  at creation time which knows how to interrogate a specified type
  of feature/object that will be passed in to the write function.

  As in, for the GTF format the translator must know how to retrieve
  seqname, source, type, start, end, score, strand, phase and attributes
  fromt he objects you plan to feed the writer.

=cut

package Bio::EnsEMBL::IO::Writer::GTF;

use parent qw/Bio::EnsEMBL::IO::Writer::ColumnBasedGeneric/;

use strict;
use warnings;
use Carp;

use Bio::EnsEMBL::IO::Format::GTF;

=head2 new

    Description: Constructor for a column based generic writer
    Args[1]    : Translator object for the type of object being written 
                 (ie. for Ensembl Features, etc)

=cut

sub new {
    my $class = shift;
    my $translator = shift;
    
    my $self = $class->SUPER::new($translator);
    my $format = Bio::EnsEMBL::IO::Format::GTF->new();
    $self->format($format);
    ## Backwards compatibility
    $self->fields($format->get_accessors);

    if( $translator->can('strand_conversion') ) {
      $translator->strand_conversion(Bio::EnsEMBL::IO::Format::GTF->strand_conversion());
    }
    
    return $self;
}

=head2 combine_fields

    Description: For fields that are composite fields (ie. attributes in
                 GTF), combine the pieces of the field using the correct
                 delimiters for GTF
    Returntype : String of concatenated fields

=cut

sub combine_fields {
    my $self = shift;
    my $values = shift;

    return $self->SUPER::combine_fields($values, undef, '; ', 1, ' ', '"');
}

1;
