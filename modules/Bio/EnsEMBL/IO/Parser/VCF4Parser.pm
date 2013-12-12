=pod

=head1 LICENSE

  Copyright (c) 1999-2013 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

  http://www.ensembl.org/info/about/code_licence.html

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

sub getMetadataKeyList {
  my $self = shift;
  return join(", ",sort(keys(%{$self->{'metadata'}})));
}

sub getMetadataByPragma {
  my $self = shift;
  my $pragma = shift;
  return (defined($self->{'metadata'}->{$pragma})) ? $self->{'metadata'}->{$pragma} : undef;
}

=head2 getVCFversion
    Description : Retrieve the VCF format version
    Returntype  : String
=cut

sub getVCFversion {
  my $self = shift;
  return $self->{'metadata'}->{'fileformat'};
}


# Sequence name

=head2 getRawSeqName
    Description : Return the name of the sequence
    Returntype  : String
=cut

sub getRawSeqName {
    my $self = shift;
    return $self->{'record'}[0];
}


=head2 getSeqName
    Description : Return the name of the sequence
    Returntype  : String
=cut

sub getSeqName {
    my $self = shift;
    return $self->getRawSeqName();
}


# Sequence start

=head2 getRawStart
    Description : Return the start position of the feature
    Returntype  : Integer
=cut

sub getRawStart {
    my $self = shift;
    return $self->{'record'}[1];
}


=head2 getStart
    Description : Return the adjusted start position of the feature 
    Returntype  : Integer
=cut

sub getStart {
    my $self = shift;
    my $start = $self->getRawStart();
    # Like indels, SVs have the base before included for reference
    if ($self->getRawInfo =~ /SVTYPE/ || $self->getAlternatives =~ /\<|\[|\]|\>/ ) {
      $start ++;
    }
    else {
      # For InDels, the reference String must include the base before the event (which must be reflected in the POS field).
      my $ref = $self->getRawReference;
      foreach my $alt (split(',',$self->getAlternatives)) {
        if (length($alt) != length($ref)) {
          $start ++;
          last;
        }
      }
    }
    return $start;
}


# Sequence end

=head2 getRawEnd
    Description : Return the end position of the feature
    Returntype  : Integer
=cut

sub getRawEnd {
    my $self = shift;
    my $info = $self->getInfo;
    my $end;
    if (defined($info->{END})) {
      $end = $info->{END};
    }
    elsif(defined($info->{SVLEN})) {
      my $svlen = (split(',',$info->{SVLEN}))[0];
      $end = $self->getRawStart + abs($svlen);
    }
    else {
      $end = $self->getRawStart + length($self->getRawReference) - 1;
    }
    return $end;
}


=head2 getEnd
    Description : Return the adjusted end position of the feature 
    Returntype  : Integer
=cut

sub getEnd {
    my $self = shift;
    my $info = $self->getInfo;
    my $end;
    if (defined($info->{END})) {
      $end = $info->{END};
    }
    elsif(defined($info->{SVLEN})) {
      my $svlen = (split(',',$info->{SVLEN}))[0];
      $end = $self->getStart + abs($svlen)-1;
    }
    else {
      $end = $self->getStart + length($self->getRawReference) - 1;
    }
    return $end;
}


=head2 getOuterStart
    Description : Return the outer start position of the feature if the start 
                  position is imprecise (only for structural variant)
    Returntype  : Integer
=cut

sub getOuterStart {
    my $self = shift;
    my $start = $self->getStart();
    my $key = 'CIPOS';
 
    return $start if ($self->getRawInfo !~ /$key/);
    
    $start += $self->_get_interval_coordinates($key,'outer');
    
    return $start;
}


=head2 getInnerStart
    Description : Return the inner start position of the feature if the start 
                  position is imprecise (only for structural variant)
    Returntype  : Integer
=cut

sub getInnerStart {
    my $self = shift;
    my $start = $self->getStart();
    my $key = 'CIPOS';
 
    return $start if ($self->getRawInfo !~ /$key/);
    
    $start += $self->_get_interval_coordinates($key,'inner');
    
    return $start;
}


=head2 getInnerEnd
    Description : Return the inner end position of the feature if the end 
                  position is imprecise (only for structural variant)
    Returntype  : Integer
=cut

sub getInnerEnd {
    my $self = shift;
    my $end = $self->getEnd();
    my $key = 'CIEND';
 
    return $end if ($self->getRawInfo !~ /$key/);
    
    $end += $self->_get_interval_coordinates($key,'inner');
    
    return $end;
}


=head2 getOuterEnd
    Description : Return the outer end position of the feature if the end 
                  position is imprecise (only for structural variant)
    Returntype  : Integer
=cut

sub getOuterEnd {
    my $self = shift;
    my $end = $self->getEnd();
    my $key = 'CIEND';
 
    return $end if ($self->getRawInfo !~ /$key/);
    
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
    
    my $info = $self->getInfo;
    
    my $pos = $info->{$key};
    my $type = ($outer_inner eq 'outer') ? ($key =~ /cipos/i ? 0 : 1) : ($key =~ /ciend/i ? 0 : 1);
 print "$key POS: $pos =>".(split(',',$pos))[$type]." => $type\n";
    return(split(',',$pos))[$type];
}


# ID(s)

=head2 getRawIDs
    Description : Return the identifier of the feature
    Returntype  : String
=cut

sub getRawIDs {
    my $self = shift;
    return $self->{'record'}[2];
}


=head2 getIDs
    Description : Return the identifier(s) of the feature
    Returntype  : reference to list
=cut

sub getIDs {
    my $self = shift;
    my @ids = split(';',$self->getRawIDs());
    return \@ids;
}


# Sequence reference

=head2 getRawReference
    Description : Return the reference sequence of the feature
    Returntype  : String
=cut

sub getRawReference {
    my $self = shift;
    return $self->{'record'}[3];
}


=head2 getReference
    Description : Return the reference sequence of the feature
    Returntype  : String
=cut

sub getReference {
    my $self = shift;
    return $self->getRawReference();
}


# Sequence alternative

=head2 getRawAlternatives
    Description : Return the alternative(s) sequence(s) of the feature
                  in a string separated by comma(s)
    Returntype  : String
=cut

sub getRawAlternatives {
    my $self = shift;
    return $self->{'record'}[4];
}


=head2 getAlternatives
    Description : Return the alternative(s) sequence(s) of the feature
    Returntype  : reference to list
=cut

sub getAlternatives {
    my $self = shift;
    my @alts = split(',',$self->getRawAlternatives());
    return \@alts;
}


=head2 getAlternativeDescription
    Arg [1]     : String $alt (alternative sequence) 
    Description : Return the description of the given alternative sequence of the feature
    Returntype  : String
=cut

sub getAlternativeDescription {
  my $self = shift;
  my $alt = shift;
  return $self->getMetaDescription('ALT', $alt);
}


# Sequence quality score

=head2 getRawScore
    Description : Return the quality score of the feature
    Returntype  : String
=cut

sub getRawScore {
    my $self = shift;
    return $self->{'record'}[5];
}


=head2 getScore
    Description : Return the quality score of the feature
    Returntype  : String
=cut

sub getScore {
    my $self = shift;
    return $self->getRawScore();
}


# Data filter

=head2 getRawFilterResults
    Description : Return the filter status in a string separated by comma(s)
    Returntype  : String
=cut

sub getRawFilterResults {
    my $self = shift;
    return $self->{'record'}[6];
}


=head2 getFilterResults
    Description : Return the filter status
    Returntype  : reference to list
=cut

sub getFilterResults {
    my $self = shift;
    my @filters = split(';',$self->getRawFilterResults());
    return \@filters;
}


# Additional information

=head2 getRawInfo
    Description : Return additional information associated with the feature.
                  INFO fields are encoded as a semicolon-separated series of short
                  keys with optional values in the format: <key>=<data>[,data]
    Returntype  : String
=cut

sub getRawInfo {
  my $self = shift;
  return $self->{'record'}[7];
}


=head2 getInfo
    Description : Return additional information associated with the feature in a hash,
                  in the format "key => data"
    Returntype  : reference to hash
=cut

sub getInfo {
  my $self = shift;
  my %info_data;
  foreach my $info (split(';',$self->getRawInfo)) {
    my ($key,$value) = split('=',$info);
    $info_data{$key} = $value;
  }
  return \%info_data;
}


=head2 getInformationDescription
    Arg [1]     : String $info (INFO key, e.g. 'AA') 
    Example     : $info_desc = $vcf->getInformationDescription('AA');
                  The result is "Ancestral Allele"
    Description : Return the description of the given INFO key.
    Returntype  : String
=cut

sub getInformationDescription {
  my $self = shift;
  my $info = shift;
  return $self->getMetaDescription('INFO', $info);
}


# Format information

=head2 getRawFormats
    Description : Return the data types used for each individual, e.g. "GT:GQ:DP:HQ"
    Returntype  : String
=cut

sub getRawFormats {
  my $self = shift;
  return undef if (!$self->getMetadataByPragma('header')->[8] || $self->getMetadataByPragma('header')->[8] ne 'FORMAT');
  return $self->{'record'}[8];
}


=head2 getFormats
    Description : Return the list of data types used for each individual, e.g. "[GT,GQ,DP,HQ]"
    Returntype  : reference to list
=cut


sub getFormats {
  my $self = shift;
  my $raw_formats = $self->getRawFormats;
  my @formats = ($raw_formats) ? split(':',$raw_formats) : ();
  return \@formats;
}


=head2 getFormatDescription
    Arg [1]     : String $format (FORMAT key, e.g. 'GT') 
    Example     : $format_desc = $vcf->getFormatDescription('GT');
                  The result is "Genotype"
    Description : Return the description of the given FORMAT key.
    Returntype  : String
=cut

sub getFormatDescription {
  my $self   = shift;
  my $format = shift;
  return $self->getMetaDescription('FORMAT', $format);
}


=head2 getMetaDescription
    Argument [1]: Metadata type, e.g. 'INFO'
    Argument [2]: Metadata ID, e.g. 'AA'
    Description : Retrieve the description of the given metadata type and metadata ID
    Returntype  : String
=cut

sub getMetaDescription {
  my $self = shift;
  my $type = shift;
  my $id   = shift;
  
  if (!defined($type) || !defined($id)) {
    warning("You need to provide a meta type (e.g. 'INFO') and a meta entry ID (e.g. 'AA')");
    return undef;
  }
  
  my $meta = $self->getMetadataByPragma($type);
  foreach my $meta_entry (@$meta) {
    return $meta_entry->{'Description'} if ($meta_entry->{'ID'} eq $id);
  }
  return undef;
}


# Individual information

=head2 getRawIndividualsInfo
    Description: Returns the list of individual name concatenated with the content of individual genotype data
                 e.g. 'NA10000:0|1:44:23'
    Returntype : List reference of strings
=cut

sub getRawIndividualsInfo {
  my $self = shift;
  # Uses an array to keep the individuals order.
  # Not sure if the order is really important. If not, an hash would be better to store the data.
  my @ind_list;
  for(my $i = $self->{'individual_begin'};$i < scalar(@{$self->{'metadata'}{'header'}});$i++) {
    push(@ind_list, $self->{'metadata'}{'header'}->[$i].':'.$self->{'record'}[$i]);
  } 
  return \@ind_list;
}

=head2 getIndividualsInfo
    Description: Returns the list of individual names, formats and the corresponding data
                 e.g. 'NA10000' => ( 'GT' => '0|1' )
    Returntype : Hash with the format 'individual_name' => ( 'format' => 'data' )
=cut

sub getIndividualsInfo {
  my $self = shift;
  my %ind_info;
  my $formats = $self->getFormats;
  foreach my $ind (@{$self->getRawIndividualsInfo}) {
    my @ind_data = split(':',$ind);
    my $ind_name = shift @ind_data;
    for (my $i = 0; $i < scalar(@ind_data); $i++) {
      $ind_info{$ind_name}{$formats->[$i]} = $ind_data[$i];
    }
  } 
  return \%ind_info;
}

=head2 getIndividualsGenotypes
    Description: Returns the list of individual names with their genotypes (with alleles)
                 e.g. 'NA10000' => 'A|G'
    Returntype : Hash with the format 'individual_name' => 'allele1|allele2'
=cut

sub getIndividualsGenotypes {
  my $self = shift;
  my %ind_gen;
  my $ind_info = $self->getIndividualsInfo;
  my @alleles = (($self->getReference),@{$self->getAlternatives});
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
