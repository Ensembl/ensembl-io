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

=cut


=head1 NAME

Bio::EnsEMBL::IO::Parser::VCF4 - A line-based parser devoted to VCF format version 4.2

=cut

=head1 DESCRIPTION

The Variant Call Format (VCF) specification for the version 4.2 is available at the following adress:
http://samtools.github.io/hts-specs/VCFv4.2.pdf

=cut

package Bio::EnsEMBL::IO::Parser::BaseVCF4;

use strict;
use warnings;
use Carp;
use Storable qw(freeze thaw);

use Bio::EnsEMBL::IO::Format::VCF4;

use base qw/Bio::EnsEMBL::IO::ColumnBasedParser/;

my $version = 4.2;

my %FREEZE_EXCLUDE = (
  current_block => 1,
  delimiter => 1,
  filehandle => 1,
  iterator => 1,
  waiting_block => 1,
  tabix_file => 1,
);

=head2 add_format

    Description : Add a format object and configure the parser
    Returntype  : none

=cut

sub add_format {
  my $self = shift;
  my $class = "Bio::EnsEMBL::IO::Format::VCF4";
  my $format = $class->new();
  $self->format($format);
}

sub next {
  my $self = shift;

  # reset the per-record cache
  $self->{_cache} = {};

  return $self->SUPER::next(@_);
}

sub is_metadata {
    my $self = shift;
    return $self->{'current_block'} =~ /^#/;
}

sub read_metadata {
  my $self = shift;
  my $line = ($self->{'current_block'}) ? $self->{'current_block'} : shift;

  my %meta_info = ( 'INFO'     => 1,
                    'FILTER'   => 1,
                    'FORMAT'   => 1,
                    'ALT'      => 1,
                    'SAMPLE'   => 1,
                    'PEDIGREE' => 1 );

  chomp $line;
  push @{$self->{_raw_metadata}}, $line;

  if ($line =~ /^##\s*(\w+)=(.+)$/) {
    my $m_type = $1;
    my $m_data = $2;

    push @{$self->{_metadata_order}}, $m_type;

    # Check the fileformat
    if ($m_type eq 'fileformat') {
      if ($m_data =~ /(\d+)\.(\d+)/) {
        my ($file_version_major, $file_version_minor) = ($1, $2);
        my $f_version = $file_version_major.'.'.$file_version_minor;

        # get version of this parser
        $version =~ /(\d+)\.(\d+)/;
        my ($parser_version_major, $parser_version_minor) = ($1, $2);

        confess "The VCF file format version $f_version is not compatible with the parser version (VCF v$version)" if ($file_version_major != $parser_version_major) || ($file_version_major == $parser_version_major && $parser_version_major < $file_version_major);
        #warn "VCF file version $f_version may be incompatible with parser version $version" if ($file_version_major == $parser_version_major && $parser_version_minor != $file_version_minor);
      }
      else {
        die "The script can't read the VCF file format version of '$m_type'";
      }
    }

    # Can have more than 1 sequence region
    if ($meta_info{$m_type}) {
      $m_data =~ s/[<>]//g;
      my %metadata;

      # Fix when the character "," is found in the description field
      if($m_data =~ /(.*)(".+")(.*)/) {
        my ($before, $content, $after) = ($1, $2, $3);
        $content =~ s/,/!#!/g;
        $m_data = ($before || '').$content.($after || '');
      }
      foreach my $meta (split(',',$m_data)) {

        my ($key,$value) = split('=',$meta);
        if(defined($value)) {
          $value =~ s/"//g;
          $value =~ s/!#!/,/g; # Revert the fix for the character ","
        }
        $metadata{$key}=$value;
      }

      if ($self->{'metadata'}->{$m_type}) {
        push(@{$self->{'metadata'}->{$m_type}}, \%metadata);
      }
      else {
        $self->{'metadata'}->{$m_type} = [\%metadata];
      }
    }
    else {
      $self->{'metadata'}->{$m_type} = $m_data;
    }
  }
  elsif ($line =~ /^#\s*(.+)$/) {
    $self->{'metadata'}->{'header'} = [split("\t",$1)];
    $self->{'sample_begin'} = (scalar @{$self->{'metadata'}->{'header'}} >= 9 && $self->{'metadata'}->{'header'}->[8] eq 'FORMAT') ? 9 : 8;
  }
}


=head2 get_metadata_key_list
    Description : Retrieve the list of metadata keys available as a
                  string with each term separated by a comma.
    Returntype  : String
=cut

sub get_metadata_key_list {
  my $self = shift;
  return join(", ",sort(keys(%{$self->{'metadata'}})));
}


=head2 get_metadata_by_pragma
    Description : Retrieve the metadata associated with the given key (pragma).
    Returntype  : String or reference to an array (depending on the type of metadata)
=cut

sub get_metadata_by_pragma {
  my $self = shift;
  my $pragma = shift;
  return (defined($self->{'metadata'}->{$pragma})) ? $self->{'metadata'}->{$pragma} : undef;
}


=head2 get_vcf_version
    Description : Retrieve the VCF format version
    Returntype  : String
=cut

sub get_vcf_version {
  my $self = shift;
  return $self->{'metadata'}->{'fileformat'};
}


=head2 set_fields
    Description: Setter for list of fields used in this format - uses the
                 "public" (i.e. non-raw) names of getter methods
    Returntype : Void
=cut

sub set_fields {
  my $self = shift;
  $self->{'fields'} = [qw(seqname start end IDs reference alternatives score filter_results info formats)];
}


# Sequence name

=head2 get_raw_seqname
    Description : Return the name of the sequence
    Returntype  : String
=cut

sub get_raw_seqname {
    my $self = shift;
    return $self->{'record'}[0];
}


=head2 get_seqname
    Description : Return the name of the sequence
    Returntype  : String
=cut

sub get_seqname {
    my $self = shift;
    return $self->get_raw_seqname();
}


# Sequence start

=head2 get_raw_start
    Description : Return the start position of the feature
    Returntype  : Integer
=cut

sub get_raw_start {
    my $self = shift;
    return $self->{'record'}[1];
}


=head2 get_start
    Description : Return the adjusted start position of the feature
    Returntype  : Integer
=cut

sub get_start {
    my $self = shift;
    my $start = $self->get_raw_start();
    return unless defined $start;

    # Like indels, SVs have the base before included for reference
    my $alternatives = join(",", @{$self->get_alternatives});
    if (($self->get_raw_info && $self->get_raw_info =~ /SVTYPE/) || ($alternatives && $alternatives =~ /\<|\[|\]|\>/)) {
      $start ++;
    }
    else {
      # For InDels, the reference String must include the base before the event (which must be reflected in the POS field).
      my $ref = $self->get_raw_reference;
      foreach my $alt (@{$self->get_alternatives}) {
        if (length($alt) != length($ref)) {
          $start ++;
          last;
        }
      }
    }
    return $start;
}


# Sequence end

=head2 get_raw_end
    Description : Return the end position of the feature
    Returntype  : Integer
=cut

sub get_raw_end {
    my $self = shift;
    my $info = $self->get_info;
    my $end;
    if (defined($info->{END})) {
      $end = $info->{END};
    }
    elsif(defined($info->{SVLEN})) {
      my $svlen = (split(',',$info->{SVLEN}))[0];
      $end = $self->get_raw_start + abs($svlen);
    }
    else {
      $end = $self->get_raw_start + length($self->get_raw_reference) - 1;
    }
    return $end;
}


=head2 get_end
    Description : Return the adjusted end position of the feature
    Returntype  : Integer
=cut

sub get_end {
    my $self = shift;
    my $info = $self->get_info;
    my $end;
    if (defined($info->{END})) {
      $end = $info->{END};
    }
    elsif(defined($info->{SVLEN})) {
      return unless $self->get_start;
      my $svlen = (split(',',$info->{SVLEN}))[0];
      $end = $self->get_start + abs($svlen)-1;
    }
    else {
      return unless $self->get_start;
      $end = $self->get_start + length($self->get_raw_reference) - 1;
    }
    return $end;
}


=head2 get_outer_start
    Description : Return the outer start position of the feature if the start
                  position is imprecise (only for structural variant)
    Returntype  : Integer
=cut

sub get_outer_start {
    my $self = shift;
    my $start = $self->get_start();
    my $key = 'CIPOS';

    return $start if ($self->get_raw_info !~ /$key/);

    $start += $self->_get_interval_coordinates($key,'outer');

    return $start;
}


=head2 get_inner_start
    Description : Return the inner start position of the feature if the start
                  position is imprecise (only for structural variant)
    Returntype  : Integer
=cut

sub get_inner_start {
    my $self = shift;
    my $start = $self->get_start();
    my $key = 'CIPOS';

    return $start if ($self->get_raw_info !~ /$key/);

    $start += $self->_get_interval_coordinates($key,'inner');

    return $start;
}


=head2 get_inner_end
    Description : Return the inner end position of the feature if the end
                  position is imprecise (only for structural variant)
    Returntype  : Integer
=cut

sub get_inner_end {
    my $self = shift;
    my $end = $self->get_end();
    my $key = 'CIEND';

    return $end if ($self->get_raw_info !~ /$key/);

    $end += $self->_get_interval_coordinates($key,'inner');

    return $end;
}


=head2 get_outer_end
    Description : Return the outer end position of the feature if the end
                  position is imprecise (only for structural variant)
    Returntype  : Integer
=cut

sub get_outer_end {
    my $self = shift;
    my $end = $self->get_end();
    my $key = 'CIEND';

    return $end if ($self->get_raw_info !~ /$key/);

    $end += $self->_get_interval_coordinates($key,'outer');

    return $end;
}


=head2 _get_interval_coordinates
    Arg [1]     : String $key (i.e. 'CIPOS' or 'CIEND')
    Arg [2]     : String $outer_inner (i.e. 'outer' or 'inner')
    Description : Return the outer or inner position of the start (CIPOS) or end (CIEND)
                  of the imprecise feature (only for structural variant)
    Returntype  : Integer
=cut

sub _get_interval_coordinates {
    my $self = shift;
    my $key  = shift;
    my $outer_inner = shift;

    my $info = $self->get_info;

    my $pos = $info->{$key};
    my $type = ($outer_inner eq 'outer') ? ($key =~ /cipos/i ? 0 : 1) : ($key =~ /ciend/i ? 0 : 1);

    return(split(',',$pos))[$type];
}


# ID(s)

=head2 get_raw_IDs
    Description : Return the identifier of the feature
    Returntype  : String
=cut

sub get_raw_IDs {
    my $self = shift;
    return $self->{'record'}[2];
}


=head2 get_IDs
    Description : Return the identifier(s) of the feature
    Returntype  : reference to list
=cut

sub get_IDs {
    my $self = shift;
    my @ids = split(';',$self->get_raw_IDs());
    return \@ids;
}


# Sequence reference

=head2 get_raw_reference
    Description : Return the reference sequence of the feature
    Returntype  : String
=cut

sub get_raw_reference {
    my $self = shift;
    return $self->{'record'}[3];
}


=head2 get_reference
    Description : Return the reference sequence of the feature
    Returntype  : String
=cut

sub get_reference {
    my $self = shift;
    return $self->get_raw_reference();
}


# Sequence alternative

=head2 get_raw_alternatives
    Description : Return the alternative(s) sequence(s) of the feature
                  in a string separated by comma(s)
    Returntype  : String
=cut

sub get_raw_alternatives {
    my $self = shift;
    return $self->{'record'}[4];
}


=head2 get_alternatives
    Description : Return the alternative(s) sequence(s) of the feature
    Returntype  : reference to list
=cut

sub get_alternatives {
    my $self = shift;
    my $alt_allele = $self->get_raw_alternatives();
    return ($alt_allele) ? [split(',',$alt_allele)] : [];
}


=head2 get_alternative_description
    Arg [1]     : String $alt (alternative sequence)
    Description : Return the description of the given alternative sequence of the feature
    Returntype  : String
=cut

sub get_alternative_description {
  my $self = shift;
  my $alt = shift;
  return $self->get_metadata_description('ALT', $alt);
}


# Sequence quality score

=head2 get_raw_score
    Description : Return the quality score of the feature
    Returntype  : String
=cut

sub get_raw_score {
    my $self = shift;
    return $self->{'record'}[5];
}


=head2 get_score
    Description : Return the quality score of the feature
    Returntype  : String
=cut

sub get_score {
    my $self = shift;
    return $self->get_raw_score();
}


# Data filter

=head2 get_raw_filter_results
    Description : Return the filter status in a string separated by comma(s)
    Returntype  : String
=cut

sub get_raw_filter_results {
    my $self = shift;
    return $self->{'record'}[6];
}


=head2 get_filter_results
    Description : Return the filter status
    Returntype  : reference to list
=cut

sub get_filter_results {
    my $self = shift;
    my @filters = split(';',$self->get_raw_filter_results());
    return \@filters;
}


# Additional information

=head2 get_raw_info
    Description : Return additional information associated with the feature.
                  INFO fields are encoded as a semicolon-separated series of short
                  keys with optional values in the format: <key>=<data>[,data]
    Returntype  : String
=cut

sub get_raw_info {
  my $self = shift;
  return $self->{'record'}[7];
}


=head2 get_info
    Description : Return additional information associated with the feature in a hash,
                  in the format "key => data"
    Returntype  : reference to hash
=cut

sub get_info {
  my $self = shift;

  if(!exists($self->{_cache}->{info})) {
    my %info_data;
    foreach my $info (split(';', ($self->get_raw_info || ''))) {
      my ($key,$value) = split('=',$info);
      $info_data{$key} = $value;
    }
    $self->{_cache}->{info} = \%info_data;
  }

  return $self->{_cache}->{info};
}


=head2 get_info_description
    Arg [1]     : String $info (INFO key, e.g. 'AA')
    Example     : $info_desc = $vcf->get_info_description('AA');
                  The result is "Ancestral Allele"
    Description : Return the description of the given INFO key.
    Returntype  : String
=cut

sub get_info_description {
  my $self = shift;
  my $info = shift;
  return $self->get_metadata_description('INFO', $info);
}


# Format information

=head2 get_raw_formats
    Description : Return the data types used for each individual, e.g. "GT:GQ:DP:HQ"
    Returntype  : String
=cut

sub get_raw_formats {
  my $self = shift;
  return undef if (!$self->get_metadata_by_pragma('header')->[8] || $self->get_metadata_by_pragma('header')->[8] ne 'FORMAT');
  return $self->{'record'}[8];
}


=head2 get_formats
    Description : Return the list of data types used for each individual, e.g. "[GT,GQ,DP,HQ]"
    Returntype  : reference to list
=cut


sub get_formats {
  my $self = shift;
  my $raw_formats = $self->get_raw_formats;
  my @formats = ($raw_formats) ? split(':',$raw_formats) : ();
  return \@formats;
}


=head2 get_format_description
    Arg [1]     : String $format (FORMAT key, e.g. 'GT')
    Example     : $format_desc = $vcf->get_format_description('GT');
                  The result is "Genotype"
    Description : Return the description of the given FORMAT key.
    Returntype  : String
=cut

sub get_format_description {
  my $self   = shift;
  my $format = shift;
  return $self->get_metadata_description('FORMAT', $format);
}


=head2 get_metadata_description
    Argument [1]: Metadata type, e.g. 'INFO'
    Argument [2]: Metadata ID, e.g. 'AA'
    Description : Retrieve the description of the given metadata type and metadata ID
    Returntype  : String
=cut

sub get_metadata_description {
  my $self = shift;
  my $type = shift;
  my $id   = shift;

  if (!defined($type) || !defined($id)) {
    carp("You need to provide a meta type (e.g. 'INFO') and a meta entry ID (e.g. 'AA')");
    return undef;
  }

  my $meta = $self->get_metadata_by_pragma($type);
  foreach my $meta_entry (@$meta) {
    return $meta_entry->{'Description'} if ($meta_entry->{'ID'} eq $id);
  }
  return undef;
}


# Individual information

=head2 get_individuals
    Description: Returns list of individual names
    Returntype : Listref of strings
=cut

sub get_individuals {
  my $self = shift;

  return $self->get_samples;
}

=head2 get_individual_column_indices
    Description: Returns hashref of individual names with value
                 being the column index they appear in the file
    Returntype : Hashref of { individual => index }
    Status     : DEPRECATED
=cut

sub get_individual_column_indices {
  my $self = shift;

  return $self->get_sample_column_indices;
}

=head2 get_raw_individuals_info
    Description: Returns the listref of listrefs of individual name and individual genotype data
                 e.g. ['NA10000', '0|1:44:23'], ['NA10001', '1|1:34:30']
    Returntype : List reference of strings
    Status     : DEPRECATED
=cut

sub get_raw_individuals_info {
  my $self = shift;
  my $individual_ids = shift;

  return $self->get_raw_samples_info($individual_ids);
}

# this sub caches a list of individual column indices
# might be unnecessary, but every millisecond counts!
sub _get_individual_index_list {
  my $self = shift;
  return $self->_get_sample_index_list(@_);
}

=head2 get_individuals_info
    Description: Returns the list of individual names, formats and the corresponding data
                 e.g. 'NA10000' => ( 'GT' => '0|1' )
    Returntype : Hash with the format 'individual_name' => ( 'format' => 'data' )
    Status     : DEPRECATED
=cut

sub get_individuals_info {
  my $self = shift;
  return $self->get_samples_info(@_);
}

=head2 get_individuals_genotypes
    Description: Returns the list of individual names with their genotypes (with alleles)
                 e.g. 'NA10000' => 'A|G'
    Returntype : Hash with the format 'individual_name' => 'allele1|allele2'
    Status     : DEPRECATED
=cut

sub get_individuals_genotypes {
  my $self = shift;
  return $self->get_samples_genotypes(@_);
}

# Sample information

=head2 get_samples
    Description: Returns list of sample names
    Returntype : Listref of strings
=cut

sub get_samples {
  my $self = shift;

  if(!exists($self->{samples})) {
    my $indices = $self->get_sample_column_indices;
    @{$self->{samples}} = sort {$indices->{$a} <=> $indices->{$b}} keys %$indices;
  }
  return $self->{samples};
}


=head2 get_sample_column_indices
    Description: Returns hashref of sample names with value
                 being the column index they appear in the file
    Returntype : Hashref of { sample => index }
=cut

sub get_sample_column_indices {
  my $self = shift;

  if(!exists($self->{sample_column_indices})) {
    my %indices =
      map {$self->{metadata}{header}->[$_] => $_}
      ($self->{sample_begin}..(scalar(@{$self->{metadata}{header}}) - 1));

    $self->{sample_column_indices} = \%indices;
  }

  return $self->{sample_column_indices};
}

=head2 get_raw_samples_info
    Description: Returns the listref of listrefs of sample name and sample genotype data
                 e.g. ['NA10000', '0|1:44:23'], ['NA10001', '1|1:34:30']
    Returntype : List reference of strings
=cut

sub get_raw_samples_info {
  my $self = shift;
  my $sample_ids = shift;

  # restrict by sample list?

  my $limit = $sample_ids ? $self->_get_sample_index_list($sample_ids) : [];

  # get a list of indices
  # this is either a limited list based on the samples provided
  # or a list for all samples in the file
  my @index_list = scalar @$limit ? @$limit : ($self->{sample_begin}..(scalar(@{$self->{metadata}{header}}) - 1));

  return [
    map {[$self->{metadata}{header}->[$_], $self->{record}[$_]]}
    @index_list
  ];
}

# this sub caches a list of sample column indices
# might be unnecessary, but every millisecond counts!
sub _get_sample_index_list {
  my $self = shift;
  my $sample_ids = shift;

  my $cache_key = $sample_ids;
  $cache_key = join("\n",sort @$sample_ids) if ref($sample_ids) eq 'ARRAY';

  if(!exists($self->{_sample_limit_list}->{$cache_key})) {

    # clear the cache
    $self->{_sample_limit_list} = {};
    my @limit = ();

    # check we have a valid array
    if(defined($sample_ids) && ref($sample_ids) eq 'ARRAY' && scalar @$sample_ids) {
      my $all_sample_cols = $self->get_sample_column_indices();

      # we have to check that each sample exists
      # otherwise we'll get undefined warnings everywhere
      foreach my $sample_id(@$sample_ids) {
        next unless $all_sample_cols->{$sample_id};
        push @limit, $all_sample_cols->{$sample_id};
      }

      # it won't be much use if none of the sample names you gave appear in the file
      confess("ERROR: No valid sample IDs given") unless scalar @limit;
    }

    # key the hash on the reference of the list
    $self->{_sample_limit_list}->{$cache_key} = [sort {$a <=> $b} @limit];
  }

  return $self->{_sample_limit_list}->{$cache_key};
}

=head2 get_samples_info
    Description: Returns the list of sample names, formats and the corresponding data
                 e.g. 'NA10000' => ( 'GT' => '0|1' )
    Returntype : Hash with the format 'sample_name' => ( 'format' => 'data' )
=cut

sub get_samples_info {
  my $self = shift;
  my $sample_ids = shift;
  my $key = shift;

  my %sample_info;
  my $formats = $self->get_formats;

  # restrict by key, e.g. to only fetch GT
  my $format_index;
  if(defined($key)) {
    my %tmp = map {$formats->[$_] => $_} (0..$#{$formats});
    $format_index = $tmp{$key};
    return {} unless defined($format_index);
  }

  foreach my $tmp_sample_data (@{$self->get_raw_samples_info($sample_ids)}) {

    # first element is sample name, second element is ":"-separated string
    my @sample_data = shift @$tmp_sample_data;
    push @sample_data, split(':', $tmp_sample_data->[0]);

    # limit to one key
    if(defined($format_index)) {
      $sample_info{$sample_data[0]}{$key} = $sample_data[$format_index + 1];
    }

    # get all keys
    else {
      my $sample_name = shift @sample_data;
      for (my $i = 0; $i < scalar(@sample_data); $i++) {
        $sample_info{$sample_name}{$formats->[$i]} = $sample_data[$i];
      }
    }
  }
  return \%sample_info;
}

=head2 get_samples_genotypes
    Description: Returns the list of sample names with their genotypes (with alleles)
                 e.g. 'NA10000' => 'A|G'
    Returntype : Hash with the format 'sample_name' => 'allele1|allele2'
=cut

sub get_samples_genotypes {
  my $self = shift;
  my $sample_ids = shift;
  my $non_ref_only = shift;

  my %sample_gen;
  my $sample_info = $self->get_samples_info($sample_ids, 'GT');
  my @alleles = (($self->get_reference),@{$self->get_alternatives});

  foreach my $sample (keys(%$sample_info)) {
    my $gt = $sample_info->{$sample}{'GT'};

    # skip reference homozygotes if $non_ref_only is true
    # e.g. 0|0 (phased diploid), 0/0/0 (unphased triploid), 0 (monoploid e.g. male X)
    next if $non_ref_only && $gt =~ /^(0[\\\|\/]?)+$/;

    my $phased = ($gt =~ /\|/ ? 1 : 0);
    my $translated_gt = join(
      ($phased ? '|' : '/'),
      map {$alleles[$_]}
      grep {$_ ne '.'}
      split(($phased ? '\|' : '/'), $gt)
    );
    next if (!$translated_gt);
    $sample_gen{$sample} = $translated_gt;

  }
  return \%sample_gen;
}

sub is_polymorphic {
  my $self = shift;
  my $sample_ids = shift;

  my $limit = $sample_ids ? $self->_get_sample_index_list($sample_ids) : [];

  # get a list of indices
  # this is either a limited list based on the samples provided
  # or a list for all samples in the file
  my @index_list = scalar @$limit ? @$limit : ($self->{sample_begin}..(scalar(@{$self->{metadata}{header}}) - 1));

  my %uniq_gts = map {$self->{record}->[$_] => 1} @index_list;

  return scalar keys %uniq_gts > 1 ? 1 : 0;
}

# freeze a copy of the VCF record
sub get_frozen_copy {
  my $self = shift;
  
  my $copy = {
    record => \@{$self->{record}}
  };
  # my $copy = thaw(freeze({ record => $self->{record} }));
  $copy->{$_} ||= $self->{$_} for grep {!$FREEZE_EXCLUDE{$_}} keys %$self;
  bless $copy, ref($self);
  
  return $copy;
}

1;
