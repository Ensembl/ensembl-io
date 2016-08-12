=pod

=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

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

Translator::SampleGenotypeFeature - Translates accessor methods between variation feature objects, sample genotype objects and parsers

=cut

package Bio::EnsEMBL::IO::Translator::SampleGenotypeFeature;

use strict;
use warnings;

use Carp;

use base qw/Bio::EnsEMBL::IO::Translator::VariationFeature/;

my %field_callbacks = ('chrom'  => 'chrom',
                       'pos'    => 'pos',
                       'id'     => 'id',
                       'ref'    => 'ref',
                       'alt'    => 'alt',
                       'qual'   => 'qual',
                       'filter' => 'filter',
                       'info'   => 'info',
                       'format' => 'format'
                      );
                      
my %info_methods = ('AA' => 'ancestral_allele',
                    #'AC'  => 'allele_count',
                    #'AF'  => 'allele_frequency',
                    #'AN'  => 'total_allele_number',
                    'MA'  => 'minor_allele',
                    'MAF' => 'minor_allele_frequency',
                    'MAC' => 'minor_allele_count',
                    'NS'  => 'samples_with_data'
                   );

=head2 new

    Returntype   : Bio::EnsEMBL::IO::Translator::SampleGenotypeFeature

=cut

sub new {
    my ($class, $info_list, $formats_list, $samples_list) = @_;
  
    my $self = $class->SUPER::new();
    
    # Once we have the instance, add our customized callbacks
    # to the translator
    $self->add_callbacks(\%field_callbacks);

    if ($samples_list && scalar(@$samples_list) > 0) {
      $self->{'samples_list'} = $samples_list;
    }
    
    $self->{'info_list'}    = $info_list;
    $self->{'formats_list'} = $formats_list;
    

    return $self;
}

sub set_samples_list {
  my $self = shift;
  my $samples_list = shift;
  
  if ($samples_list && scalar(@$samples_list) > 0) {
    $self->{'samples_list'} = $samples_list;
  }
}

sub get_samples_list {
  my $self = shift;
  
  return ($self->{'samples_list'} && scalar(@{$self->{'samples_list'}}) > 0) ? $self->{'samples_list'} : [];
}

sub samples_genotypes {
  my $self = shift;
  my $object = shift;
  
  my $samples_list = $self->get_samples_list();
  
  die "Error! You need to define a list of samples as argument.\n" if (scalar(@$samples_list) < 1);
  
  # Transform the alleles in 0 | 1 | 2..., e.g. 0 if it matches the reference, 1 if it matches the alt 1, ...
  my @alleles = split(/\//,$self->alleles($object));
  my %gen_al;
  for (my $i = 0;$i < @alleles;$i++) {
    $gen_al{$alleles[$i]} = $i;
  }

  my %s_gen = map { $_->sample->name => { 'genotype' => $self->genotype_vcf(\%gen_al,$_->genotype), 
                                          'phased'   => ($_->phased) ? $_->phased : 0
                                        }
                  } @{$object->variation->get_all_SampleGenotypes()};
  
  if ($samples_list and scalar(@$samples_list) > 0) {
    my %new_s_gen = map { $_ => $s_gen{$_}} @$samples_list;
    %s_gen = %new_s_gen;
  }
  
  return \%s_gen;
}

sub chrom {
  my $self = shift;
  my $object = shift;
  
  return $self->seqname($object);
}

sub pos {
  my $self = shift;
  my $object = shift;
  
  return $self->start($object);
}

sub id {
  my $self = shift;
  my $object = shift;
  
  return $self->name($object);
}

sub ref {
  my $self = shift;
  my $object = shift;
  
  my @alleles = split(/\//,$self->alleles($object));
  
  return 'N'.$alleles[0];
}

sub alt {
  my $self = shift;
  my $object = shift;
  
  my @alleles = split(/\//,$self->alleles($object));
  shift @alleles;
  
  return 'N'.join(',N',@alleles);
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

sub format {
  my $self = shift;
  my $object = shift;
  
  if ($self->{'formats_list'} && scalar(@{$self->{'formats_list'}}) > 0) {
    return join(':',@{$self->{'formats_list'}});
  }
  else {
   return '.';
  }
}

sub genotype_vcf {
  my $self     = shift;
  my $gen_al   = shift;
  my $genotype = shift;
  
  my @genotype_vcf = map { $gen_al->{$_} } @$genotype;
  
  return \@genotype_vcf;
}

#### INFO METHODS ####
sub ancestral_allele {
  my $self = shift;
  my $object = shift;
  my $info = shift;
  
  my $data = $object->variation->ancestral_allele;
  return ($data) ? "$info=$data" : undef;
}

sub minor_allele {
  my $self = shift;
  my $object = shift;
  my $info = shift;
  
  my $data = $object->minor_allele;
  return ($data) ? "$info=$data" : undef;
}

sub minor_allele_frequency {
  my $self = shift;
  my $object = shift;
  my $info = shift;
  
  my $data = $object->minor_allele_frequency;
  return ($data) ? "$info=$data" : undef;
}

sub minor_allele_count {
  my $self = shift;
  my $object = shift;
  my $info = shift;
  
  my $data = $object->minor_allele_count;
  return ($data) ? "$info=$data" : undef;
}

sub samples_with_data {
  my $self = shift;
  my $object = shift;
  my $info = shift;
  
  my $s_gen = $self->samples_genotypes($object);
  my @data = grep { $s_gen->{$_} } @{$self->{'samples_list'}};
  return "$info=".scalar(@data);
}

1;