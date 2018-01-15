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

=head1 NAME

Bio::EnsEMBL::IO::Parser::Bed - A line-based parser devoted to BED-derived formats

Bed files come with a very flexible field order, so we have to allow for that

=cut

package Bio::EnsEMBL::IO::Parser::Bed;

use strict;
use warnings;
no warnings 'uninitialized';

use Bio::EnsEMBL::IO::Format::Bed;
use Bio::EnsEMBL::IO::Format::BedDetail;
use Bio::EnsEMBL::IO::Format::BedGraph;

use base qw/Bio::EnsEMBL::IO::TrackBasedParser/;

=head2 add_format

    Description : Add a format object and configure the parser
    Returntype  : none

=cut

sub add_format {
  my $self = shift;

  ## Which subformat are we dealing with?
  my $subformat = 'Bed';
  my $column_count;
  $self->shift_block; ## Move first block into "memory"
  while ($self->next) {
    my $type = $self->get_metadata_value('type');
    $subformat = ucfirst($type) if $type;

    if ($subformat eq 'bedDetail') {
      $column_count = scalar @{$self->{'record'}};
    }
    last;
  }
  $self->reset; ## Reset pointer

  my $class = "Bio::EnsEMBL::IO::Format::$subformat";
  my $format = $class->new();
  $self->format($format);
  ## Configure delimiter
  my $delimiter = $format->delimiter;
  if ($delimiter) {
    $self->{'delimiter'} = $delimiter;
    my @delimiters       = split('\|', $delimiter);
    $self->{'default_delimiter'} = $delimiters[0];
  }
  ## Configure columns
  if ($column_count) {
    $self->{'column_map'}{'id'}           = $column_count - 2;
    $self->{'column_map'}{'description'}  = $column_count - 1;

    ## Map remaining columns to valid fields
    my @fields = @{$format->get_field_order||[]};
    for (my $index = 0; $index < $column_count - 2; $index++) {
      $self->{'column_map'}{$fields[$index]} = $index;
    }
  }
  else {
    my $index = 0;
    foreach (@{$format->get_field_order||[]}) {
      $self->{'column_map'}{$_} = $index;
      $index++;
    }
  }
}
 
## ----------- Mandatory fields -------------

=head2 get_raw_chrom

    Description: Getter for chrom field
    Returntype : String 

=cut

sub get_raw_chrom {
  my $self = shift;
  my $index = $self->{'column_map'}{'chrom'};
  return defined($index) ? $self->{'record'}[$index] : undef;
}

=head2 get_seqname

    Description: Getter - wrapper around raw method 
                  (uses standard method name, not format-specific)
    Returntype : String 

=cut

sub get_seqname {
  my $self = shift;
  (my $chr = $self->get_raw_chrom()) =~ s/^chr//i;
  return $chr;
}

=head2 munge_seqname

    Description: Converts Ensembl seq region name to standard BED format  
    Returntype : String 

=cut

sub munge_seqname {
  my ($self, $value) = @_;
  $value = "chr$value" unless $value =~ /^chr/i;
  return $value;
}

=head2 get_raw_chromStart

    Description: Getter for chromStart field
    Returntype : Integer 

=cut

sub get_raw_chromStart {
  my $self = shift;
  my $index = $self->{'column_map'}{'chromStart'};
  return defined($index) ? $self->{'record'}[$index] : undef;
}

=head2 get_start

    Description: Getter - wrapper around raw_chromStart method, converting
                  semi-open coordinates to standard Ensembl ones
                  (uses standard method name, not format-specific)
    Returntype : Integer 

=cut

sub get_start {
  my $self = shift;
  return $self->get_raw_chromStart()+1;
}

=head2 munge_start

    Description: Converts Ensembl start coordinate to semi-open  
    Returntype : Integer 

=cut

sub munge_start {
  my ($self, $value) = @_;
  return $value - 1;
}

=head2 get_raw_chromEnd

    Description: Getter for chromEnd field
    Returntype : Integer

=cut

sub get_raw_chromEnd {
  my $self = shift;
  my $index = $self->{'column_map'}{'chromEnd'};
  return defined($index) ? $self->{'record'}[$index] : undef;
}

=head2 get_end

    Description: Getter - wrapper around get_raw_chromEnd 
                  (uses standard method name, not format-specific)
    Returntype : String 

=cut

sub get_end {
  my $self = shift;
  return $self->get_raw_chromEnd();
}

## ----------- Optional (in some subformats) fields -------------

=head2 get_raw_name

    Description: Getter for name field
    Returntype : String 

=cut

sub get_raw_name {
  my $self = shift;
  my $index = $self->{'column_map'}{'name'};
  return defined($index) ? $self->{'record'}[$index] : undef;
}

=head2 get_name

    Description: Getter - wrapper around get_raw_name 
    Returntype : String 

=cut

sub get_name {
  my $self = shift;
  return $self->get_raw_name();
}

=head2 get_raw_score

    Description: Getter for score field
    Returntype : Number (usually floating point) or String (period = no data)

=cut

sub get_raw_score {
  my $self = shift;
  my $index = $self->{'column_map'}{'score'};
  return defined($index) ? $self->{'record'}[$index] : undef;
}

=head2 get_score

    Description: Getter - wrapper around get_raw_score
    Returntype : Number (usually floating point) or undef

=cut

sub get_score {
  my $self = shift;
  my $val = $self->get_raw_score();
  if ($val =~ /^\.$/) {
    return undef;
  } else {
    return $val;
  }
}

=head2 get_raw_strand

    Description: Getter for strand field
    Returntype : String 

=cut

sub get_raw_strand {
  my $self = shift;
  my $index = $self->{'column_map'}{'strand'};
  return defined($index) ? $self->{'record'}[$index] : undef;
}

=head2 get_strand

    Description: Getter - wrapper around get_raw_strand
                  Converts text content into integer
    Returntype : Integer (1, 0 or -1)

=cut

sub get_strand {
  my $self = shift;
  return $self->{'strand_conversion'}{$self->get_raw_strand};
}

=head2 munge_strand

    Description: Converts Ensembl-style strand into BED version  
    Returntype : String

=cut

sub munge_strand {
  my ($self, $value) = @_;
  my %lookup = reverse %{$self->{'strand_conversion'}};
  return $lookup{$value};
}


=head2 get_raw_thickStart

    Description: Getter for thickStart field (UCSC drawing code)
    Returntype : Integer 

=cut

sub get_raw_thickStart {
  my $self = shift;
  my $index = $self->{'column_map'}{'thickStart'};
  return defined($index) ? $self->{'record'}[$index] : undef;
}

=head2 get_thickStart

    Description: Getter - wrapper around get_raw_thickStart,
                  converting semi-open coordinates to standard Ensembl ones
    Returntype : Integer

=cut

sub get_thickStart {
  my $self = shift;
  return $self->get_raw_thickStart() + 1;
}

=head2 get_raw_thickEnd

    Description: Getter for thickEnd field (UCSC drawing code)
    Returntype : Integer

=cut

sub get_raw_thickEnd {
  my $self = shift;
  my $index = $self->{'column_map'}{'thickEnd'};
  return defined($index) ? $self->{'record'}[$index] : undef;
}

=head2 get_thickEnd

    Description: Getter - wrapper around get_raw_thickEnd
    Returntype : Integer

=cut

sub get_thickEnd {
  my $self = shift;
  return $self->get_raw_thickEnd();
}

=head2 get_raw_itemRgb

    Description: Getter for itemRgb field
    Returntype : String (3 comma-separated values)

=cut

sub get_raw_itemRgb {
  my $self = shift;
  my $index = $self->{'column_map'}{'itemRgb'};
  return defined($index) ? $self->{'record'}[$index] : undef;
}

=head2 get_itemRgb

    Description: Getter - wrapper around get_raw_itemRgb
    Returntype : String (3 comma-separated values)

=cut

sub get_itemRgb {
  my $self = shift;
  return $self->get_raw_itemRgb();
}

=head2 get_raw_blockCount

    Description: Getter for blockCount field (UCSC drawing code)
    Returntype : Integer

=cut

sub get_raw_blockCount {
  my $self = shift;
  my $index = $self->{'column_map'}{'blockCount'};
  return defined($index) ? $self->{'record'}[$index] : undef;
}

=head2 get_blockCount

    Description: Getter - wrapper around blockCount
    Returntype : Integer

=cut

sub get_blockCount {
  my $self = shift;
  return $self->get_raw_blockCount();
}

=head2 get_raw_blockSizes

    Description: Getter for blockSizes field (UCSC drawing code)
    Returntype : String (comma-separated values)

=cut

sub get_raw_blockSizes {
  my $self = shift;
  my $index = $self->{'column_map'}{'blockSizes'};
  return defined($index) ? $self->{'record'}[$index] : undef;
}

=head2 get_blockSizes

    Description: Getter - wrapper around get_raw_blockSizes
    Returntype : Arrayref

=cut

sub get_blockSizes {
  my $self = shift;
  my @res = split ",", $self->get_raw_blockSizes();
  return \@res;
}

=head2 get_raw_blockStarts

    Description: Getter for blockStarts field  (UCSC drawing code)
    Returntype : String (comma-separated values)

=cut

sub get_raw_blockStarts {
  my $self = shift;
  my $index = $self->{'column_map'}{'blockStarts'};
  return defined($index) ? $self->{'record'}[$index] : undef;
}

=head2 get_blockStarts

    Description: Getter - wrapper around get_raw_blockStarts
    Returntype : Arrayref

=cut

sub get_blockStarts {
  my $self = shift;
  my @res = split ",", $self->get_raw_blockStarts();
  return \@res;
}

## ----------- BedDetails accessors ------------------------

=head2 get_raw_id

    Description: Getter for id field
    Returntype : String 

=cut

sub get_raw_id {
  my $self = shift;
  my $index = $self->{'column_map'}{'id'};
  return defined($index) ? $self->{'record'}[$index] : undef;
}

=head2 get_id

    Description: Getter - wrapper around get_raw_id
    Returntype : String 

=cut

sub get_id {
  my $self = shift;
  return $self->get_raw_id();
}

=head2 get_raw_description

    Description: Getter for description field
    Returntype : String 

=cut

sub get_raw_description {
  my $self = shift;
  my $index = $self->{'column_map'}{'id'};
  return defined($index) ? $self->{'record'}[$index] : undef;
}

=head2 get_description

    Description: Getter - wrapper around get_raw_description
    Returntype : String 

=cut

sub get_description {
  my $self = shift;
  return $self->get_raw_description();
}




###################################################################

##### OLD FILE WRITING CODE - DEPRECATED

###################################################################

=head2 create_record

    Description: Creates a single line of a BED file from an API object 
    Returntype : String

=cut

sub create_record {
  my ($self, $translator, $object) = @_;
  my @values;

  ## Add the fields in order
  my $start = $self->munge_start($translator->get_start($object)) || '.';
  my $end = $translator->get_end($object) || '.';
  push @values, $self->munge_seqname($translator->get_seqname($object)) || '.'; 
  push @values, $start;
  push @values, $end;
  if ($self->get_metadata_value('type') =~ /bedgraph/i) {
    push @values, '.'; 
  }
  else {
    push @values, $translator->get_name($object) || '.'; 
    push @values, $translator->get_score($object) eq '.' ? 0 : $translator->get_score($object);
    push @values, $self->munge_strand($translator->get_strand($object)) || '.'; 
    push @values, $translator->get_thickStart($object) ? $self->munge_start($translator->get_thickStart($object)) : $start;
    push @values, $translator->get_thickEnd($object) ? $translator->get_thickEnd($object) : $end;
    push @values, $translator->get_itemRgb($object) || '.'; 
    if ($translator->get_blockCount($object)) {
        push @values, $translator->get_blockCount($object);
        push @values, $translator->get_blockSizes($object);
        my @blockStart;
        foreach my $block_start (split(',', $translator->get_blockStarts($object))) {
            push(@blockStart, $self->munge_start($block_start-$start));
        }
        push @values, join(',', @blockStart);
    }
  }
  return $self->concatenate_fields(@values);
}


1;
