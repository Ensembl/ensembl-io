=pod

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

Translator::StructuralVarationFeature - Translates accessor methods between variation feature objects and parsers

=cut

package Bio::EnsEMBL::IO::Translator::StructuralVariationFeature;

use strict;
use warnings;

use Carp;

use parent qw/Bio::EnsEMBL::IO::Translator::Feature/;

my %field_callbacks = ('chrom'  => 'chrom',
                       'pos'    => 'pos',
                       'id'     => 'id',
                       'ref'    => 'ref',
                       'alt'    => 'alt',
                       'qual'   => 'qual',
                       'filter' => 'filter',
                       'info'   => 'info'
                      );

my %info_methods = ('SVTYPE'    => 'sv_type',
                    'END'       => 'sv_end',
                    'Parent'    => 'sv_parent',
                    'SVLEN'     => 'sv_length',
                    'CIPOS'     => 'sv_cipos',
                    'CIEND'     => 'sv_ciend',
                    'IMPRECISE' => 'sv_imprecise'
                   );

my %svtypes = ('copy_number_variation' => 'CNV',
               'copy_number_loss' => 'CNV:LOSS',
               'copy_number_gain' => 'CNV:GAIN',
               'deletion' => 'DEL',
               'inversion' => 'INV',
               'insertion' => 'INS',
               'novel_sequence_insertion' => 'INS',
               'mobile_element_insertion' => 'INS:ME',
               'Alu_insertion' => 'INS:ME:ALU',
               'duplication' => 'DUP',
               'tandem_duplication' => 'DUP:Tandem',
        
               'sequence_alteration' => 'SA',
               'complex_structural_alteration' => 'CSA',
               'complex_substitution' => 'CS',
               'indel' => 'INDEL',
               'loss_of_heterozygosity' => 'LOH',
               'translocation' => 'TL',
               'interchromosomal_translocation' => 'TL:Inter',
               'intrachromosomal_translocation' => 'TL:Intra',
               'interchromosomal_breakpoint' => 'BP:InterC',
               'intrachromosomal_breakpoint' => 'BP:IntraC',
              );                            
#my %info_methods = ('AA' => 'ancestral_allele',
#                    #'AC'  => 'allele_count',
#                    #'AF'  => 'allele_frequency',
#                    #'AN'  => 'total_allele_number',
#                    'MA'  => 'minor_allele',
#                    'MAF' => 'minor_allele_frequency',
#                    'MAC' => 'minor_allele_count',
#                    'NS'  => 'samples_with_data'
#                   );

=head2 new

    Returntype   : Bio::EnsEMBL::IO::Translator::SampleGenotypeFeature

=cut

sub new {
    my ($class, $info_list, $formats_list, $samples_list) = @_;
  
    my $self = $class->SUPER::new();

    $samples_list = [] if (!$samples_list);
    $self->{'samples_list'} = $samples_list;

    if (scalar(@$samples_list) > 0) {
      $field_callbacks{'format'} = 'format';
    }
    else {
      warn "No individuals/samples list provided!\n";
    }
    
    # Once we have the instance, add our customized callbacks
    # to the translator
    $self->add_callbacks(\%field_callbacks);
    
    $self->{'info_list'}    = $info_list;
    $self->{'formats_list'} = $formats_list;

    return $self;
}


sub slice_adaptor {
  my $self = shift;
  my $object = shift;

  if (!$self->{'slice_adaptor'}) {
    $self->{'slice_adaptor'} = $object->slice->adaptor
  }
  return $self->{'slice_adaptor'};
}

sub start {
  my $self = shift;
  my $object = shift;

  return ( $object->seq_region_start() > $object->seq_region_end() ) ? $object->seq_region_end() : $object->seq_region_start();
}

sub end {
  my $self = shift;
  my $object = shift;
  
  return ( $object->seq_region_start() > $object->seq_region_end() ) ? $object->seq_region_start() : $object->seq_region_end();
}


#### Fields methods ####

sub chrom {
  my $self = shift;
  my $object = shift;
  
  return $object->seq_region_name;
}

sub pos {
  my $self = shift;
  my $object = shift;

  my $pos = $self->start($object);

  # Get the alleles to check if we need to change the position
  # For indel/insertion/deletion/unbalanced variants, we need to
  # Get the ref base (and position) before the structural variant start
  $pos--;

  return $pos;
}


sub id {
  my $self = shift;
  my $object = shift;
  
  return $object->variation_name();
}

sub ref {
  my $self = shift;
  my $object = shift;
  
  my $ref = 'N';
  
  my $chrom = $self->chrom($object);
  my $pos = $self->pos($object);

  my $slice_adaptor = $self->slice_adaptor($object);
  if ($slice_adaptor) {
    my $slice = $slice_adaptor->fetch_by_toplevel_location("$chrom:$pos-$pos");
    $ref = $slice->seq if defined($slice);
  }
  return $ref;
}

sub alt {
  my $self = shift;
  my $object = shift;

  my $type = $object->class_SO_term;

  return ($svtypes{$type}) ? '<'.$svtypes{$type}.'>' : '<SA>';
}

sub qual {
  my $self = shift;
  my $object = shift;
  
  return '.';
}

sub filter {
  my $self = shift;
  my $object = shift;
  
  return '.';
}

sub info {
  my $self = shift;
  my $object = shift;
  
  my $info_string;
  if ($self->{'info_list'} && scalar(@{$self->{'info_list'}}) > 0) {
    foreach my $info (@{$self->{'info_list'}}) {
      next if (!$info_methods{$info});
      my $method = $info_methods{$info};
      my $new_info = $self->$method($object,$info);
      $info_string .= ';' if $info_string && $new_info;
      $info_string .= $new_info if ($new_info);
    }
    return $info_string;
  }
  else {
    return '.';
  }
}

#### INFO METHODS ####

sub sv_type {
  my $self = shift;
  my $object = shift;
  my $info = shift;
  
  my $sv_type = $self->alt($object);
     $sv_type =~ s/(<|>)//g;
  
  my @type = split(':',$sv_type);

  return "$info=$type[0]";
}

sub sv_end {
  my $self = shift;
  my $object = shift;
  my $info = shift;
  
  my $end = $self->end($object);
  
  return "$info=$end";
}

sub sv_length {
  my $self = shift;
  my $object = shift;
  my $info = shift;
  
  my $sv_length = $object->length;
  
  if ($sv_length) {
    $sv_length = "-$sv_length" if ($object->class_SO_term =~ /deletion/i);
    return "$info=$sv_length";
  }
}

sub sv_cipos {
  my $self = shift;
  my $object = shift;
  my $info = shift;
 
  my $cipos;
  if ($object->outer_start && $object->inner_start) {
    $cipos  = $object->outer_start - $self->start($object);
    $cipos .= ',';
    $cipos .= $object->inner_start - $self->start($object);

    return "$info=$cipos";
  } else {
    return;
  }
}

sub sv_ciend {
  my $self = shift;
  my $object = shift;
  my $info = shift;
 
  my $ciend;
  if ($object->outer_end && $object->inner_end) {
    $ciend  = $object->inner_end - $self->end($object);
    $ciend .= ',';
    $ciend .= $object->outer_end - $self->end($object);

    return "$info=$ciend";
  } else {
    return;
  }
}

sub sv_imprecise {
  my $self = shift;
  my $object = shift;
  my $info = shift;

  if (($object->outer_start && $object->inner_start) || ($object->inner_end && $object->outer_end)) {
    return $info;
  } else {
    return;
  }
}

sub sv_parent {
  my $self = shift;
  my $object = shift;
  my $info = shift;
  
  my $sv_object = $object->structural_variation;
  
  if ($sv_object->is_evidence) {
    my $adaptor = $object->adaptor;
    my $ssva = $adaptor->db->get_SupportingStructuralVariationAdaptor();
    my $ssv = $ssva->fetch_by_dbID($sv_object->dbID);
    
    my $svs = $ssv->get_all_StructuralVariations();
    
    if ($svs && scalar(@$svs)) {
      return "$info=".join(',',map { $_->variation_name } @$svs);
    }
  }
}

1;
