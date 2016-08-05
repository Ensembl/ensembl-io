=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

  Bio::EnsEMBL::IO::Writer::Fasta - Generic Fasta Writer

=head1 SYNOPSIS

  my $slice_adaptor = Bio::EnsEMBL::Registry->get_adaptor( "human", "core", "slice" );

  use Bio::EnsEMBL::IO::Writer::Fasta;
  my $writer     = Bio::EnsEMBL::IO::Writer::Fasta->new();

  use Bio::EnsEMBL::IO::Translator::Slice;
  my $translator = Bio::EnsEMBL::IO::Translator::Slice->new();

  $writer->translator($translator);

  $writer->open(*STDOUT);

  my $slice = $slice_adaptor->fetch_by_region( 'chromosome', '20', 1e6, 1e6 + 1000 );

  $writer->write($slice);

=head1 Description

  Write records out in Fasta format. The module uses a translator given
  at creation time which knows how to interrogate a specified type
  of feature/object that will be passed in to the write function.

  As in, for the Fasta format the translator must know how to retrieve
  seqname, source, type, start, end, score, strand, phase and attributes
  fromt he objects you plan to feed the writer.

=cut

package Bio::EnsEMBL::IO::Writer::Fasta;

use base Bio::EnsEMBL::IO::Writer;

use strict;
use warnings;
use Carp;

use Bio::EnsEMBL::IO::Object::Fasta;

sub new {
    my $class = shift;
    my $translator = shift;

    my $self = $class->SUPER::new($translator);
    return $self;
}

sub write {
    my $self = shift;
    my $object = shift;

    print { $self->{writer_handle} } $self->create_record($object);
}

=head2 create_record

    Description: Create the record in Fasta to write out to the file
    Args[1]    : Object to format
    Returntype : String

=cut

sub create_record {

    my $self   = shift;
    my $object = shift;

    my $translator = $self->translator;
    
    my $name   = $translator->name($object);
    my $length = $translator->length($object);

    my $formatted_sequence = '';
    my $start  = 1;
    my $characters_per_line = 60;

    while($start < $length) {
      
      my $end = $start + $characters_per_line;
      
      if ($end>$length)  {
	$end = $length;
      }
      
      $formatted_sequence .= $translator->subseq($object, $start, $end) . "\n";
      $start += $characters_per_line;
    }

    return 
      '>' . $name . "\n"
      . $formatted_sequence
    ;
}

1;
