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

Bio::EnsEMBL::IO::Translator::GenePlus - Translator for an Ensembl Gene together with Transcript, Exons and Translation)

=head1 SYNOPSIS

  use Bio::EnsEMBL::IO::Translator::GenePlus;



  my $translator = Bio::EnsEMBL::IO::Translator::GenePlus->new();
  my @values = $translator->batch_fields($object, @fields);
  my $seqname = $translator->display_id($object);

=head1 Description

Translator to interrogate Ensembl genes needed by writers that may also need to capture items from their subfields.

=cut

package Bio::EnsEMBL::IO::Translator::GenePlus ;


use base qw/Bio::EnsEMBL::IO::Translator/;

use strict;
use warnings;
use Carp;
use URI::Escape;
use Bio::EnsEMBL::Utils::SequenceOntologyMapper;
use Bio::EnsEMBL::Utils::Exception qw/throw/;

my %ens_field_callbacks = (gene_start => '$self->can(\'gene_start\')',
                           gene_end  => '$self->can(\'gene_end\')',
                           gene_strand  => '$self->can(\'gene_strand\')',
                           gene_stable_id_version => '$self->can(\'gene_stable_id_version\')',
                           gene_description => '$self->can(\'gene_description\')',
                           gene_display_id => '$self->can(\'gene_display_id\')',
                           biotype =>  '$self->can(\'biotype\')',
                           transcript_stable_id_version =>  '$self->can(\'transcript_stable_id_version\')',
                           protein_stable_id_version =>  '$self->can(\'protein_stable_id_version\')',
                           exon_locations =>  '$self->can(\'exon_locations\')',
                           );

=head2 new

    Returntype   : Bio::EnsEMBL::IO::Translator::GenePlus

=cut

sub new
{
    my ($class) = @_;

    my $self = $class->SUPER::new();

    # Once we have the instance, add our customized callbacks
    # to the translator
    $self->add_callbacks(\%ens_field_callbacks);

    $self->{default_source} = '.';
    my $oa = Bio::EnsEMBL::Registry->get_adaptor('multi', 'ontology', 'OntologyTerm');
    $self->{'mapper'} = Bio::EnsEMBL::Utils::SequenceOntologyMapper->new($oa);

    return $self;
}

sub biotype
{
    my $self = shift;
    my $feature_hash_ref = shift;
    my %feature_hash = %{ $feature_hash_ref } ;
    my $t = $feature_hash{'transcript'} ;
    return $t->biotype ;
}

sub protein_stable_id_version
{
    my $self = shift;
    my $feature_hash_ref = shift;
    my %feature_hash = %{ $feature_hash_ref } ;
    my $t = $feature_hash{'transcript'} ;
    if ( $t->translation() )
    {
      return $t->translation()->stable_id_version() ;
    }
    else
    {
      return undef ;
    }
}

sub translation
{
    my $self = shift;
    my $feature_hash_ref = shift;
    my %feature_hash = %{ $feature_hash_ref } ;
    my $t = $feature_hash{'transcript'} ;
    if ( $t->translation() )
    {
      return $t->translate()->seq() ;
    }
    else
    {
      return undef ;
    }
}

sub exon_locations
{
    my $self = shift;
    my $feature_hash_ref = shift;
    my %feature_hash = %{ $feature_hash_ref } ;
    my $t = $feature_hash{'transcript'} ;
    my @exon_location_array ;
    my @exons = @{ $t->get_all_Exons() } ;
    foreach my $e (@exons)
    {
      push(@exon_location_array,$e->start) ;
      push(@exon_location_array,$e->end) ;
    }
    return \@exon_location_array ;
}

sub gene_start
{
    my $self = shift;
    my $feature_hash_ref = shift;
    my %feature_hash = %{ $feature_hash_ref } ;
    return $self->start( $feature_hash{'gene'} );
}


sub gene_end
{
    my $self = shift;
    my $feature_hash_ref = shift;
    my %feature_hash = %{ $feature_hash_ref } ;
    return $self->end( $feature_hash{'gene'} );
}

sub gene_strand
{
    my $self = shift;
    my $feature_hash_ref = shift;
    my %feature_hash = %{ $feature_hash_ref } ;
    my $g = $feature_hash{'gene'} ;
    return $g->strand() ;
}

sub gene_stable_id_version
{
    my $self = shift;
    my $feature_hash_ref = shift;
    my %feature_hash = %{ $feature_hash_ref } ;
    my $g = $feature_hash{'gene'} ;
    return $g->stable_id_version ;
}

sub gene_description
{
    my $self = shift;
    my $feature_hash_ref = shift;
    my %feature_hash = %{ $feature_hash_ref } ;
    my $g = $feature_hash{'gene'} ;
    return $g->description ;
}

sub gene_display_id
{
    my $self = shift;
    my $feature_hash_ref = shift;
    my %feature_hash = %{ $feature_hash_ref } ;
    my $g = $feature_hash{'gene'} ;
    return $g->display_xref->display_id ;
}


sub transcript_stable_id_version
{
    my $self = shift;
    my $feature_hash_ref = shift;
    my %feature_hash = %{ $feature_hash_ref } ;
    my $t = $feature_hash{'transcript'} ;
    return $t->stable_id_version ;
}



sub start
{
    my $self = shift;
    my $object = shift;
    return $object->start();
}


sub end
{
    my $self = shift;
    my $object = shift;

    my $end = $object->end();

    # the start coordinate of the feature, here shifted to chromosomal coordinates
    # Start and end must be in ascending order for GXF. Circular genomes require the length of
    # the circuit to be added on.
    if( $object->start() > $object->end() )
    {
      if ($object->slice() && $object->slice()->is_circular() )
      {
        $end = $end + $object->seq_region_length;
      }
      # non-circular, but end still before start
      else
      {
	      $end = $object->start();
      }
    }

    return $end;
}
