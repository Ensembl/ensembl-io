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

Bio::EnsEMBL::IO::Writer::VCF4 - Generic VCF4 Writer

=head1 SYNOPSIS

  use Bio::EnsEMBL::IO::Writer::VCF4;

  my $writer = Bio::EnsEMBL::IO::Writer::VCF4->new($translator);

  $writer->write($object);

=head1 Description

  Write records out in VCF4 format. The module uses a translator given
  at creation time which knows how to interrogate a specified type
  of feature/object that will be passed in to the write function.

  As in, for the VCF4 format the translator must know how to retrieve
  CHROM, POS, ID, REF, ALT, QUAL, FILTER, INFO, FORMAT and individual
  genotypes from he objects you plan to feed the writer.

=cut

package Bio::EnsEMBL::IO::Writer::VCF4;

use parent qw/Bio::EnsEMBL::IO::Writer::ColumnBasedGeneric/;

use strict;
use warnings;
use Carp;

use Bio::EnsEMBL::IO::Object::VCF4;
use Bio::EnsEMBL::IO::Object::VCF4Metadata;

=head2 new

  Description: Constructor for a column based generic writer
  Args[1]  : Translator object for the type of object being written 
         (ie. for Ensembl Features, etc)

=cut

sub new {
  my $class = shift;
  my $translator = shift;

  my $self = $class->SUPER::new($translator);

  $self->fields(Bio::EnsEMBL::IO::Object::VCF4->fields());
  
  # Cheat and make a VCF4Metadata object in a really quick and lighttweight manner.
  # We need one hanging around for the fwd-ref writer call
  #$self->{directive} = bless { type => 'directive' }, 'Bio::EnsEMBL::IO::Object::VCF4Metadata';
  #$self->{header} = bless { type => 'header' }, 'Bio::EnsEMBL::IO::Object::VCF4Metadata';

  return $self;
}


=head2 create_record

  Description: Create the record in VCF4 to write out to the file
  Args[1]  : Object to format
  Returntype : String

=cut

sub create_record {
  my $self = shift;
  my $object = shift;
  my $translator = shift;

  # Special use case for VCF files without sample/individual data:
  # no need to have the 'FORMAT' column
  my @fields = @{$self->fields()};
  if (scalar(@{$self->{'translator'}{'samples_list'}}) == 0) {
    @fields = grep { $_ ne 'format' } @fields;
  }

  my @values = $translator->batch_fields($object, \@fields);

  #### Create check for Ref and Alt ####
  my $id_col_id;
  my $ref_col_id;
  my $alt_col_id;
  for (my $i=0; $i < @fields; $i++) {
    if ($fields[$i] =~ /^ID$/i) {
      $id_col_id = $i;
    }
    elsif ($fields[$i] =~ /^REF$/i) {
      $ref_col_id = $i;
    }
    elsif ($fields[$i] =~ /^ALT$/i) {
      $alt_col_id = $i;
    }
  }

  # Reference
  unless ($values[$ref_col_id] && $values[$ref_col_id] =~ /^[ATGCN]+$/i) {
    if (!$values[$ref_col_id]) {
      warn("Can't find reference allele for $values[$id_col_id].\n");
    }
    elsif ($values[$ref_col_id] !~ /^[ATGCN]+$/i) {
      warn("Reference allele '$values[$ref_col_id]' for $values[$id_col_id] is not compatible with VCF specifications.\n");
    }
    return;
  }
  
  # Alternative
  unless ($values[$alt_col_id] && ($values[$alt_col_id] =~ /^([ATGCN\*]+\,?)+$/i || $values[$alt_col_id] =~ /^(<(\w+\:?)+>\,?)+$/i)) {
    if (!$values[$alt_col_id]) {
      warn("Can't find alternative allele for $values[$id_col_id].\n");
    }
    elsif ($values[$alt_col_id] !~ /^([ATGCN\*]+\,?)+$/i && $values[$alt_col_id] !~ /^(<(\w+\:?)+>\,?)+$/i) {
      warn("Alternative allele '$values[$alt_col_id]' for $values[$id_col_id] is not compatible with VCF specifications.\n");
    }
    return;
  }

  # Sample genotypes
  if (scalar(@{$self->{'translator'}{'samples_list'}}) > 0) {
    my $s_gen = $translator->samples_genotypes($object);
    foreach my $sample (@{$self->{'translator'}{'samples_list'}}) {
      my $genotype;
      if ($s_gen->{$sample}) {
        my $phase_sep = ($s_gen->{$sample}{'phased'} == 1) ? '|' : '/';
        $genotype = join($phase_sep, @{$s_gen->{$sample}{'genotype'}});
      }
      else {
        $genotype = './.';
      }
      push(@values, $genotype);
    }
  }

  # Special case to handle attributes field and it's ordering
  #  my $attr = pop @values;
  # We get the attribute values back as an arrayref, combine the ordered list
  # using the VCF4 style '; ' delimiter and push back on to the values
  #  $attr = $self->concatenate_fields($attr, '; ');
  #  push @values, $attr;
  return $self->concatenate_fields(\@values), "\n";
}

=head2 combine_fields

  Description: For fields that are composite fields (ie. attributes in
               VCF4), combine the pieces of the field using the correct
               delimiters for VCF4
  Returntype : String of concatenated fields

=cut

sub combine_fields {
  my $self = shift;
  my $values = shift;

  my $order = $self->attributes_order();
  if($order) {
    my %seen;
    @seen{@{$order}} = ();
    my @attrs = (@{$order}, grep{!exists $seen{$_}} sort keys %{$values});
    $order = \@attrs;
  }

  return $self->SUPER::combine_fields($values, $order);
}


1;
