=pod

=head1 LICENSE

  Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

Bio::EnsEMBL::IO::Parser::VCF4Parser - A line-based parser devoted to VCF format version 4.2

=cut

=head1 DESCRIPTION

The Variant Call Format (VCF) specification for the version 4.2 is available at the following adress:
http://samtools.github.io/hts-specs/VCFv4.2.pdf

=cut

package Bio::EnsEMBL::IO::Parser::VCF4Parser;

use strict;
use warnings;
use Bio::EnsEMBL::Utils::Exception qw(warning);

use base qw/Bio::EnsEMBL::IO::ColumnBasedParser/;

my $version = 4.2;

sub open {
    my ($caller, $filename, $other_args) = @_;
    my $class = ref($caller) || $caller;
    
    my $self = $class->SUPER::open($filename, "\t", $other_args);

    #############
    ## OPTIONS ##
    #############
    # TO BE IMPLEMENTED
    # 1) Use tabix (i.e. given a coordinate like 2:10000-20000)
    # 2) Use GP coordinates (INFO column)
    
    
    # pre-load peek buffer
    $self->next_block();
    
    return $self;
}

sub is_metadata {
    my $self = shift;
    return $self->{'current_block'} =~ /^#/;
}

sub read_metadata {
  my $self = shift;
  my $line = $self->{'current_block'};
  
  my %meta_info = ( 'INFO'     => 1, 
                    'FILTER'   => 1, 
                    'FORMAT'   => 1,
                    'ALT'      => 1,
                    'SAMPLE'   => 1,
                    'PEDIGREE' => 1 );
  
  if ($line =~ /^##\s*(\w+)=(.+)$/) {
    my $m_type = $1;
    my $m_data = $2;
    
    # Check the fileformat
    if ($m_type eq 'fileformat') {
      if ($m_data =~ /(\d+\.\d+)/) {
        die "The VCF file format version $1 is not compatible with the parser version (VCF v$version)" if ($1 != $version);
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
      if ($m_data =~ /(".+")/) {
        my $desc_content = $1;
        my $new_desc_content = $desc_content;
        $new_desc_content =~ s/,/!#!/g;
        $m_data =~ s/$desc_content/$new_desc_content/;
      }
      foreach my $meta (split(',',$m_data)) {
        my ($key,$value) = split('=',$meta);
        $value =~ s/"//g;
        $value =~ s/!#!/,/g; # Revert the fix for the character ","
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
    $self->{'individual_begin'} = ($self->{'metadata'}->{'header'}->[8] eq 'FORMAT') ? 9 : 8;
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
    # Like indels, SVs have the base before included for reference
    if ($self->get_raw_info =~ /SVTYPE/ || $self->get_alternatives =~ /\<|\[|\]|\>/ ) {
      $start ++;
    }
    else {
      # For InDels, the reference String must include the base before the event (which must be reflected in the POS field).
      my $ref = $self->get_raw_reference;
      foreach my $alt (split(',',$self->get_alternatives)) {
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
      my $svlen = (split(',',$info->{SVLEN}))[0];
      $end = $self->get_start + abs($svlen)-1;
    }
    else {
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
  my %info_data;
  foreach my $info (split(';',$self->get_raw_info)) {
    my ($key,$value) = split('=',$info);
    $info_data{$key} = $value;
  }
  return \%info_data;
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
    warning("You need to provide a meta type (e.g. 'INFO') and a meta entry ID (e.g. 'AA')");
    return undef;
  }
  
  my $meta = $self->get_metadata_by_pragma($type);
  foreach my $meta_entry (@$meta) {
    return $meta_entry->{'Description'} if ($meta_entry->{'ID'} eq $id);
  }
  return undef;
}


# Individual information

=head2 get_raw_individuals_info
    Description: Returns the list of individual name concatenated with the content of individual genotype data
                 e.g. 'NA10000:0|1:44:23'
    Returntype : List reference of strings
=cut

sub get_raw_individuals_info {
  my $self = shift;
  # Uses an array to keep the individuals order.
  # Not sure if the order is really important. If not, an hash would be better to store the data.
  my @ind_list;
  for(my $i = $self->{'individual_begin'};$i < scalar(@{$self->{'metadata'}{'header'}});$i++) {
    push(@ind_list, $self->{'metadata'}{'header'}->[$i].':'.$self->{'record'}[$i]);
  } 
  return \@ind_list;
}

=head2 get_individuals_info
    Description: Returns the list of individual names, formats and the corresponding data
                 e.g. 'NA10000' => ( 'GT' => '0|1' )
    Returntype : Hash with the format 'individual_name' => ( 'format' => 'data' )
=cut

sub get_individuals_info {
  my $self = shift;
  my %ind_info;
  my $formats = $self->get_formats;
  foreach my $ind (@{$self->get_raw_individuals_info}) {
    my @ind_data = split(':',$ind);
    my $ind_name = shift @ind_data;
    for (my $i = 0; $i < scalar(@ind_data); $i++) {
      $ind_info{$ind_name}{$formats->[$i]} = $ind_data[$i];
    }
  } 
  return \%ind_info;
}

=head2 get_individuals_genotypes
    Description: Returns the list of individual names with their genotypes (with alleles)
                 e.g. 'NA10000' => 'A|G'
    Returntype : Hash with the format 'individual_name' => 'allele1|allele2'
=cut

sub get_individuals_genotypes {
  my $self = shift;
  my %ind_gen;
  my $ind_info = $self->get_individuals_info;
  my @alleles = (($self->get_reference),@{$self->get_alternatives});
  foreach my $ind (keys(%$ind_info)) {
    my $al_separator = ($ind_info->{$ind}{'GT'} =~ /\|/) ? '\|' : '/'; 
    my ($al1,$al2) = split($al_separator,$ind_info->{$ind}{'GT'});
    my $allele1 = ($al1 eq '.') ? '' : $alleles[$al1];
    my $allele2 = ($al2 eq '.') ? '' : $alleles[$al2];
    $ind_gen{$ind} = "$allele1|$allele2";
  }
  return \%ind_gen;
}

1;
