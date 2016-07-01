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

Bio::EnsEMBL::IO::Parser::Bed - A line-based parser devoted to BED format

=cut

package Bio::EnsEMBL::IO::Parser::Bed;

use strict;
use warnings;
no warnings 'uninitialized';

use base qw/Bio::EnsEMBL::IO::TrackBasedParser/;
 

=head2 set_fields

    Description: Setter for list of fields used in this format - uses the
                  "public" (i.e. non-raw) names of getter methods
    Returntype : Void

=cut

sub set_fields {
  my $self = shift;
  $self->{'fields'} = [qw(seqname start end name score strand thickStart thickEnd itemRgb blockCount blockSizes blockStarts)];
}

=head2 set_minimum_column_count

    Description: Sets minimum column count for a valid BED file 
    Returntype : Void 

=cut

sub set_minimum_column_count {
    my $self = shift;
    $self->{'min_col_count'} = 3;
}

## ----------- Mandatory fields -------------

=head2 get_raw_chrom

    Description: Getter for chrom field
    Returntype : String 

=cut

sub get_raw_chrom {
  my $self = shift;
  return $self->{'record'}[0];
}

=head2 get_seqname

    Description: Getter - wrapper around raw method 
                  (uses standard method name, not format-specific)
    Returntype : String 

=cut

sub get_seqname {
  my $self = shift;
  (my $chr = $self->get_raw_chrom()) =~ s/^chr//;
  return $chr;
}

=head2 munge_seqname

    Description: Converts Ensembl seq region name to standard BED format  
    Returntype : String 

=cut

sub munge_seqname {
  my ($self, $value) = @_;
  $value = "chr$value" unless $value =~ /^chr/;
  return $value;
}

=head2 get_raw_chromStart

    Description: Getter for chromStart field
    Returntype : Integer 

=cut

sub get_raw_chromStart {
  my $self = shift;
  return $self->{'record'}[1];
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
  return $self->{'record'}[2];
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

## ----------- Optional fields -------------

=head2 get_raw_name

    Description: Getter for name field
    Returntype : String 

=cut

sub get_raw_name {
  my $self = shift;
  my $column = $self->get_metadata_value('type') eq 'bedGraph' ? undef : $self->{'record'}[3];
  return $column;
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
  my $column = $self->get_metadata_value('type') eq 'bedGraph' ? 3 : 4;
  return $self->{'record'}[$column];
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
  return $self->{'record'}[5];
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
  return $self->{'record'}[6];
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
  return $self->{'record'}[7];
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
  return $self->{'record'}[8];
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
  return $self->{'record'}[9];
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
  return $self->{'record'}[10];
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
  return $self->{'record'}[11];
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

=head2 validate 

    Description: Format_specific validation
    Returntype: String

=cut

sub validate {
    my ($self, $subtype) = @_;

    my $valid     = 0;
    my $col_count = 0;
    my $format    = '';

    while ($self->next) {
     
      if ($self->is_metadata && !$subtype) {
        $subtype = $self->get_metadata_value('type');
      }
      next if $self->{'current_block'} !~ /\w/;
      $self->read_record;

      ## Check we have the correct number of columns for this format
      $col_count = scalar(@{$self->{'record'}});

      ## Identify bedgraph content
      if ($col_count == 4 && $self->{'record'}[3] =~ /^[-+]?[0-9]*\.?[0-9]+$/) {
        $format = 'bedgraph';
        if ($subtype =~ /bedgraph/i) {
          $valid = 1;
        }
      }
      elsif ($col_count >= $self->get_minimum_column_count
              && $col_count <= $self->get_maximum_column_count) {
        $format = 'bed';
        $valid = 1;
      }
      last unless $valid;

      ## Check we have coordinates
      $valid = 0 if !$self->get_seqname;
      $valid = 0 unless ($self->get_start =~ /\d+/ && $self->get_start > 0 && $self->get_end =~ /\d+/);
      last;
    }

    ## Finished validating, so return parser to beginning of file
    $self->reset;

    return ($valid, $format, $col_count);
}


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
