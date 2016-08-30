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

Bio::EnsEMBL::IO::Writer::Genbank - Generic Genbank Writer

=head1 SYNOPSIS

  use Bio::EnsEMBL::IO::Writer::Genbank;

  my $writer = Bio::EnsEMBL::IO::Writer::Genbank->new($translator);

  $writer->write($object);

=head1 Description

  Write records out in Genbank format. The module uses a translator given
  at creation time which knows how to interrogate a specified type
  of feature/object that will be passed in to the write function.

  As in, for the Genbank format the translator must know how to retrieve
  seqname, source, type, start, end, score, strand, phase and attributes
  fromt he objects you plan to feed the writer.

=cut

package Bio::EnsEMBL::IO::Writer::Genbank;

use base qw/Bio::EnsEMBL::IO::Writer/;

use strict;
use warnings;
use Carp;

use Bio::EnsEMBL::IO::Object::Genbank;

my @order = qw(LOCUS DEFINITION ACCESSION VERSION KEYWORDS SOURCE COMMENT REFERENCE FEATURES ORIGIN);

#not including FEATURES in this list, as it's a bit of special case
my %fields_with_subfields =
(
 "REFERENCE"  => ["AUTHORS","TITLE","JOURNAL","PUBMED"],
 "SOURCE"  => ["ORGANISM"],
) ;


=head2 new

    Description: Constructor for a genback writer
    Args[1]    : Translator object for the type of object being written
                 (ie. for Ensembl Features, etc)

=cut

sub new
{
    my $class = shift;
    my $translator = shift;

    my $self = $class->SUPER::new();
    $self->translator($translator);
    return $self;
}



=head2 write

    Description: Write a record to the output, it will use the given
                 translator to interrogate the object for the needed fields
    Args[1]    : Object to write out

=cut
sub write
{
    my $self = shift;
    my $object = shift;

    #write out the header
    print { $self->{writer_handle} } $self->create_record($object);

}


=head2 create_record

    Description: Create the record in native format to write out to the file
    Args[1]    : Object to format
    Returntype : String

=cut

sub create_record
{
    my $self = shift;
    my $object = shift;

    my @values = $self->{translator}->batch_fetch($object, $self->fields());
}



1;
