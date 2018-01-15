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

Bio::EnsEMBL::IO::Object::GTF - Generic object for holding GTF based records

=head1 SYNOPSIS

  use Bio::EnsEMBL::IO::Object::GTF;
  use Bio::EnsEMBL::IO::Parser::GTF;

  my $parser = Bio::EnsEMBL::IO::Parser::GTF->open('myfile.gff3');
  my $obj = Bio::EnsEMBL::IO::Object::GTF->new($parser->get_fields);

  $obj->munrge_seqname('my_seq');

=head1 Description

An object derived from ColumnBasedGeneric with a specialized create_record to properly
format the record as GTF/GTF2 and map the strand to the correct values type (+/-)
rather than GFF3 as the generic object does.

=cut

package Bio::EnsEMBL::IO::Object::GTF;

use base qw/Bio::EnsEMBL::IO::Object::ColumnBasedGeneric/;

use strict;
use warnings;
use Carp;

my %strand_mapping = (1 => '+', -1 => '-');

=head2 create_record

    Description: Serialize the record to it's native format, pieces may
                 need to be overridden by inherited types.

=cut

sub create_record {
    my $self = shift;
    my @values;

    foreach my $field (@{$self->fields}) {
	my $value;
	if(defined($self->$field) && ref $self->$field eq 'HASH') {
	    $value = $self->combine_fields($self->$field, '; ', 1, ' ', '"');
	} else {
	    $value = $self->$field || '.';
	}

	push @values, $value;
    }

    return $self->concatenate_fields(\@values) . "\n";
}

=head2

    Description: Map to a GTF type strand (+/-) when accessing the strand value

=cut

sub strand {
    my $self = shift;

    $self->{strand} = shift if @_;
    return ( $strand_mapping{ $self->{strand} } ? $strand_mapping{ $self->{strand} } : $self->{strand} );
}

1;
