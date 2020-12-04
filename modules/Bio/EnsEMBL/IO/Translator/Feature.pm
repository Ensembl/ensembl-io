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

Bio::EnsEMBL::IO::Translator::Feature - Translator for Ensembl Features (Gene, Transcript, Exon, Translation)

=head1 SYNOPSIS

  use Bio::EnsEMBL::IO::Translator::Feature;

  my $translator = Bio::EnsEMBL::IO::translator::Feature->new();

  my @values = $translator->batch_fields($object, @fields);

  my $seqname = $translator->seqname($object);

=head1 Description

Translator to interrogate Ensembl base features for attributes needed by writers. For each attribute type

=cut

package Bio::EnsEMBL::IO::Translator::Feature;


use parent qw/Bio::EnsEMBL::IO::Translator/;


use strict;
use warnings;

use Carp;
use URI::Escape;
use Scalar::Util qw/blessed/;

use Bio::EnsEMBL::Utils::Exception qw/throw/;

my %ens_field_callbacks = (seqname        => 'seqname',
                           start          => 'start',
                           end            => 'end',
                           strand         => 'strand',
                           name           => 'name',
                           source         => 'source',
                           feature        => 'feature',
                           type           => 'type',
                           score          => 'score',
                           bedstart       => 'bedstart',
                           itemRgb        => 'itemRgb',
                           phase          => 'phase',
                           attributes     => 'attributes',
                           gtf_attributes => 'gtf_attributes',
                           );

=head2 new

    Returntype   : Bio::EnsEMBL::IO::Translator::Feature

=cut

sub new {
    my ($class, $args) = @_;

    my $self = $class->SUPER::new($args);

    # Once we have the instance, add our customized callbacks
    # to the translator
    $self->add_callbacks(\%ens_field_callbacks);

    $self->{default_source} = '.';

    return $self;

}

=head2 seqname
    Description: Wrapper around API call to seq region name
    Returntype : String
=cut

sub seqname {
    my $self = shift;
    my $object = shift;

    return $object->seq_region_name() ? $object->seq_region_name() : '?';
}

=head2 start
    Description: Wrapper around API call to feature start
    Returntype : Integer
=cut

sub start {
    my $self = shift;
    my $object = shift;

    return $object->seq_region_start();
}

=head2 bedstart
    Description: Subtract 1 from Ensembl start, for BED semi-open coordinates
    Returntype : Integer
=cut

sub bedstart {
    my $self = shift;
    my $object = shift;

    return $object->seq_region_start() - 1;
}

=head2 end
    Description: Wrapper around API call to feature end
    Returntype : Integer
=cut


sub end {
    my $self = shift;
    my $object = shift;

    my $end = $object->seq_region_end();

    # the start coordinate of the feature, here shifted to chromosomal coordinates
    # Start and end must be in ascending order for GXF. Circular genomes require the length of
    # the circuit to be added on.
    if( $object->seq_region_start() > $object->seq_region_end() ) {
	    if ($object->slice() && $object->slice()->is_circular() ) {
	      $end = $end + $object->seq_region_length;
	    }
	    # non-circular, but end still before start
	    else {
	      $end = $object->seq_region_start();
	    }
    }

    return $end;
}

=head2 source
    Description: Get the source of an analysis or other track
    Returntype : Integer
=cut

sub source {
    my $self = shift;
    my $object = shift;

    my $source;
    if (ref($object)->isa('Bio::EnsEMBL::Slice') ) {
	    $source = $object->source || $object->coord_system->version
    }
    elsif (ref($object)->isa('Bio::EnsEMBL::ExonTranscript') ||
	          ref($object)->isa('Bio::EnsEMBL::CDS') ||
	          ref($object)->isa('Bio::EnsEMBL::UTR') ) {
	    $source = $object->transcript()->source();
    }
    elsif (ref($object)->isa('Bio::EnsEMBL::Feature') &&
	          defined($object->analysis) && $object->analysis->gff_source() ) {
	    $source = $object->analysis->gff_source();
    }

    return $source;
}

=head2 feature
    Description: Object type for GFF2/GTF
    Returntype : String
=cut

sub feature {
    my $self = shift;
    my $object = shift;

    my @class = split('::', blessed $object);
    return lc $class[-1];
}

=head2 type
    Description: Object type for GFF3 - must be an ontology term
    Returntype : String
=cut

sub type {
    my $self = shift;
    my $object = shift;

    return $self->so_term($object);
}

=head2 name
    Description: Wrapper around API call to feature name
    Returntype : String
=cut

sub name {
  my ($self, $feature) = @_;
  return $feature->{'id'} ? $feature->{'id'}
                          : $feature->can('stable_id') ? $feature->stable_id : 'Feature';
}

sub score {
    my $self = shift;
    my $object = shift;

    # score, for variations only. We may need some isa() later
    return '.';
}

sub strand {
    my $self = shift;
    my $object = shift;

    if( ref($object)->isa('Bio::EnsEMBL::Slice') ) {
	    return '.';
    } else {
	    return ( $self->{_strand_conversion}->{ $object->{strand} } ? $self->{_strand_conversion}->{ $object->strand() } : $object->strand() );
    }
}

=head2 itemRgb

    Description:
    Returntype : String

=cut

sub itemRgb {
  my ($self, $feature) = @_;
  my $colour = $feature->{'colour'} || $self->default_colour;
  return join(',', $self->colourmap->rgb_by_name($colour));
}

sub phase {
    my $self = shift;
    my $object = shift;

    if (ref($object)->isa('Bio::EnsEMBL::CDS') ) {
	    return $object->phase();
    } else {
	    return '.';
    }
}

=head2 attributes

    Description: The default attributes is for GFF3, it needs to be
                 updated in the field callback table for other formats
    Args[1]    : Object to be serialized as an attributes field
    Returntype : Hash of attributes

=cut

sub attributes {
    my $self = shift;
    my $object = shift;

    # Oh this is a mess... hopefully we can refactor and find a better way
    my %summary = %{$object->summary_as_hash};
    delete $summary{'seq_region_start'};
    delete $summary{'seq_region_name'};
    delete $summary{'start'};
    delete $summary{'end'};
    delete $summary{'strand'};
    delete $summary{'phase'};
    delete $summary{'score'};
    delete $summary{'source'};
    delete $summary{'type'};

#    my @attrs;
    my %attrs;
    my @ordered_keys = grep { exists $summary{$_} } qw(id Name Alias Parent Target Gap Derives_from Note Dbxref Ontology_term Is_circular);
    my @ordered_values = @summary{@ordered_keys};
    while (my $key = shift @ordered_keys) {
	    my $value = shift @ordered_values;
	    delete $summary{$key};
	    if ($value && $value ne '') {
	      if ($key =~ /id/) {
          $key = uc($key);
		      if ($object->isa('Bio::EnsEMBL::Transcript')) {
            $value = 'transcript:' . $value;
		      } elsif ($object->isa('Bio::EnsEMBL::Gene')) {
            $value = 'gene:' . $value;
		      } elsif ($object->isa('Bio::EnsEMBL::Exon')) {
            $key = 'Name';
		      } elsif ($object->isa('Bio::EnsEMBL::CDS')) {
            my $trans_spliced = $object->transcript->get_all_Attributes('trans_spliced');
            if (scalar(@$trans_spliced)) {
			        $value = $self->so_term($object) . ':' . join('_', $value, $object->seq_region_name, $object->seq_region_strand);
            } else {
			        $value = $self->so_term($object) . ':' . $value;
            }
		      } else {
            $value = $self->so_term($object) . ':' . $value;
		      }
	      }

	      if ($key eq 'Parent') {
		      if ($object->isa('Bio::EnsEMBL::Transcript')) {
            $value = 'gene:' . $value;
		      } elsif ($object->isa('Bio::EnsEMBL::Exon') || $object->isa('Bio::EnsEMBL::UTR') || $object->isa('Bio::EnsEMBL::CDS')) {
            $value = 'transcript:' . $value;
		      }
	      }

	      if (ref $value eq "ARRAY" && scalar(@{$value}) > 0) {
		      $attrs{$key} = join (',',map { uri_escape($_,'\t\n\r;=%&,') } grep { defined $_ } @{$value});
	      } else {
		      $attrs{$key} = uri_escape($value,'\t\n\r;=%&,');
	      }
	    }
    }

    #   Catch the remaining keys, containing whatever else the Feature provided
    my @keys = sort keys %summary;
    while(my $attribute = shift @keys) {

      if (ref $summary{$attribute} eq "ARRAY") {
        if (scalar(@{$summary{$attribute}}) > 0) {
          $attrs{$attribute} = join (',',map { uri_escape($_,'\t\n\r;=%&,') } grep { defined $_ } @{$summary{$attribute}});
        }
      } else {
        if (defined $summary{$attribute}) {
          $attrs{$attribute} = uri_escape($summary{$attribute},'\t\n\r;=%&,');
	      }
	    }
    }

    return \%attrs;
}

=head2 gtf_attributes

    Description: Specifically create attributes for a gtf file from an Ensembl feature.
                 Because our GTF files are fairly cumulative in the attributes included
                 (transcript includes everything for a gene, etc), it becomes a little
                 simpler.
    Args[1]    : The feature to extract and build attributes from
    Args[2]    : [Optional] Any attributes to attach and add to
=cut

sub gtf_attributes {
    my $self = shift;
    my $object = shift;
    my $attrs = (defined($object->{extra_attrs}) ? $object->{extra_attrs} : {});

    # Oh this is a mess... hopefully we can refactor and find a better way
    my %summary = %{$object->summary_as_hash};

    my $gene;
    if ( $object->isa('Bio::EnsEMBL::Gene') ) {
	    # For Genes only
	    $gene = $object;
    } else {
	    # For anything but a Gene
	    my $transcript;

	    if ( $object->isa('Bio::EnsEMBL::Transcript') ) {
	      $transcript = $object;

	      foreach my $tag (qw/cds_end_NF cds_start_NF mRNA_end_NF mRNA_start_NF gencode_basic/) {
		      my $attributes = $transcript->get_all_Attributes($tag);
		      if(@{$attributes}) {
		        my $value = $tag;
		        $value = "basic" if $tag eq "gencode_basic";
		        $self->add_attr($attrs, 'tag', $value);
		      }
	      }

	    } else {
	      if ( $object->isa('Bio::EnsEMBL::ExonTranscript') ) {

	      }

	      $transcript = $object->transcript();
	    }

	    # CCDS records
	    my $ccds_entries = $transcript->get_all_DBEntries('CCDS');
	    if(@{$ccds_entries}) {
	      $self->add_attr($attrs, 'tag', 'CCDS');
	      foreach my $ccds (sort { $a->primary_id() cmp $b->primary_id() } @{$ccds_entries}) {
		      my $primary_ccds_id = $ccds->primary_id();
		      $self->add_attr($attrs, 'ccds_id', $primary_ccds_id);
	      }
	    }

	    $attrs->{transcript_id} = $transcript->display_id;
	    $attrs->{transcript_version} = $transcript->version;
	    $attrs->{transcript_name} = $transcript->external_name if $transcript->external_name;
	    $attrs->{transcript_source} = $transcript->source;
	    $attrs->{transcript_biotype} = $transcript->biotype();
	    $attrs->{havana_transcript} = $transcript->havana_transcript()->display_id if $transcript->havana_transcript();
	    $attrs->{havana_version} = $transcript->havana_transcript()->version if $transcript->havana_transcript();
	    $self->add_attr($attrs, 'tag', 'basic') if $transcript->gencode_basic();
	    $attrs->{transcript_support_level} = $transcript->tsl() if $transcript->tsl();

	    $gene = $object->get_Gene();
    }

    $attrs->{gene_id} = $gene->display_id;
    $attrs->{gene_version} = $gene->version;
    $attrs->{gene_name} = $gene->external_name if $gene->external_name;
    $attrs->{gene_source} = $gene->source;
    $attrs->{gene_biotype} = $gene->biotype;
    $attrs->{havana_gene} = $gene->havana_gene()->display_id() if $gene->havana_gene();
    $attrs->{havana_gene_version} = $gene->havana_gene()->version() if $gene->havana_gene();

    return $attrs;
}

=head2 add_attr

    Description: For GTF files, multiple attributes with the same key are allowed.
                 We'll store these as an array associated with the key, and the writer
                 will be intelligent enough that if it sees an array for a hash
                 element to decompose this.

                 Conversely, GFF3 concatonates the values for an identical key as
                 a comma separated list. The GFF writer should be similarly intelligent
                 to comma join the array values when writing the attributes field.

                 If the key doesn't already exist in the attributes hash, add
                 it as a scalar. If it does, if it's a scalar, convert to an
                 array and append. If it's already an array, just append the value.

    Args[1]    : Hashref, the hash the attribute should be appended to, this is a
                 destructive operation.
    Args[2]    : Attribute key being appended to
    Args[3]    : Value to append
    Returntype : Undef

=cut

sub add_attr {
    my $self = shift;
    my $attrs = shift;
    my $attr = shift;
    my $value = shift;

    if (defined($attrs->{$attr})) {
	    if( ref($attrs->{$attr}) eq 'ARRAY' ) {
        my $duplicate = grep {$_ eq $value} @{$attrs->{$attr}};
	      push @{$attrs->{$attr}}, $value unless $duplicate;
	    } else {
	      $attrs->{$attr} = [ $attrs->{$attr}, $value ] unless ($attrs->{$attr} eq $value);
	    }
    } else {
	    $attrs->{$attr} = $value;
    }

}

=head2 so_term

    Description: Accessor to look up the Sequence Ontology term for an object
    Args[1]    : Feature to loop up term for
    Returntype : String (term)
    Exceptions : If the term can't be found

=cut

sub so_term {
    my $self = shift;
    my $object = shift;

    my $so_term;
    # get biotype SO acc if feature can do it
    if ( $object->can('get_Biotype') ) {
        $so_term = $object->get_Biotype->so_term;
    }
    # if no biotype SO acc, get the feature one
    if ( !$so_term ) {
        $so_term = $object->feature_so_term;
    }
    # could not get it, throw exception
    if ( !$so_term ) {
        throw sprintf "Unable to find an SO term for feature %s.\n$@", $object->display_id;
    }

    if ($so_term eq 'protein_coding_gene') {
# Special treatment for protein_coding_gene, as more commonly expected term is 'gene'
      $so_term = 'gene';
    }

    return $so_term;
}

=head2 _default_score

    Description: Return the default source type for a feature
    Returntype : String

=cut

sub _default_source {
    my ($self) = @_;
    return $self->{default_source};
}


##### SHOULD THIS BE IN THE TRANSLATOR? SURELY IT IS A FORMAT THING?

=head2 strand_conversion

    Description: Sets hash giving the strand conversion for this
                 output type
    Args[1]    : Reference to hash

=cut

sub strand_conversion {
    my $self = shift;

    if( @_ ) {
	    $self->{_strand_conversion} = shift;
    }

    return $self->{_strand_conversion};
}

1;
