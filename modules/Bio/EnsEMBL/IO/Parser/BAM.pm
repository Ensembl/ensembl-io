=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::IO::Parser::BAM;

use strict;
use warnings;

use Data::Dumper;
use Bio::DB::Sam;

use parent qw(Bio::EnsEMBL::IO::Parser);

my $DEBUG = 0;

my $snpCode = {
    'AG' => 'R',
    'GA' => 'R',
    'AC' => 'M',
    'CA' => 'M',
    'AT' => 'W',
    'TA' => 'W',
    'CT' => 'Y',
    'TC' => 'Y',
    'CG' => 'S',
    'GC' => 'S',
    'TG' => 'K',
    'GT' => 'K'
};

=head2 new

    Constructor
    Argument [1+]: Hash of parameters for configuration, e.g. buffer sizes or 
                   specific functions for handling headers or data
    Returntype   : Bio::EnsEMBL::IO::Parser::BAM

=cut

ub new {
    my ($class, $url) = @_;

    my $self = {
      url               => $url,
      cache             => {
                            'file_handle' => undef,
                            'features'    => [],
                            },
      current_block     => undef,
      waiting_block     => undef,
      record            => undef,
      strand_conversion => {'+' => '1', '.' => '0', '-' => '-1'},
    };

    bless $self, $class;

    return $self;
}

=head2 url

    Description : Accessor for file url
    Returntype  : String

=cut

sub url {
  my $self = shift;
  return $self->{'url'};
}

=head2 open

    Constructor
    Argument [1] : Filepath or GLOB or open filehandle
    Argument [2+]: Hash of parameters for configuration, e.g. buffer sizes or 
                   specific functions for handling headers or data
    Returntype   : Bio::EnsEMBL::IO::Parser::BAM

=cut

sub open {
    my ($caller, $url, @other_args) = @_;
    my $class = ref($caller) || $caller;

    my $self = $class->new($url, @other_args);
    
    ## Don't actually open the file here, because some methods 
    ## need a SAM file and others need a BAM file
    return $self;
}

sub sam_open {
  my $self = shift;

  $self->{cache}->{_sam_handle} ||= Bio::DB::Sam->new(-bam => $self->url);
  return $self->{cache}->{_sam_handle};
}

sub bam_open {
  my $self = shift;

  if (!$self->{cache}->{_bam_handle}) {
    if (Bio::DB::Bam->can('set_udc_defaults')) {
      Bio::DB::Bam->set_udc_defaults;
    }
    $self->{cache}->{_bam_handle} = Bio::DB::Bam->open($self->url);
  }
  return $self->{cache}->{_bam_handle};
}

sub bam_index {
  my $self = shift;

  if (!$self->{cache}->{_bam_index}) {
    if (Bio::DB::Bam->can('set_udc_defaults')) {
      Bio::DB::Bam->set_udc_defaults;
    }
    $self->{cache}->{_bam_index} = Bio::DB::Bam->index($self->url);
  }
  return $self->{cache}->{_bam_index};
}

sub snp_code {
    my ($self, $allele) = @_;
    
    return $snpCode->{$allele};
}

=head2

    Description: UCSC prepend 'chr' on human chr ids. We therefore check for either
                  version. 
    Return: String - the seq region name as used in the file 
=cut

sub munge_chr_id {
  my ($self, $chr_id) = @_;

  my $ret_id;

  my $bam = $self->bam_open;
  warn "Failed to open BAM file " . $self->url unless $bam;
  return undef unless $bam;

  my $header = $bam->header;

  my $ret_id = $chr_id;

  # Check we get values back for seq region. Maybe need to add 'chr' 

  # Note there is a bug in samtools version 0.1.18 which means we can't just
  # use the chr_id as the region, we have to specify a range. The range I
  # use is 1-1 which is hopefully valid for all seq regions
  my @coords = $header->parse_region("$chr_id:1-1");

  if (!@coords) {
    @coords = $header->parse_region("chr$chr_id:1-1");
    if (@coords) {
      $ret_id = "chr$chr_id";
    } else {
      warn " *** could not parse_region for BAM with $chr_id in file " . $self->url ."\n";
      return undef;
    }
  }

  return $ret_id;
}

sub fetch_paired_alignments {
  my ($self, $chr_id, $start, $end) = @_;

  my $sam = $self->sam_open;
  warn "Failed to open BAM file (as SAM) " . $self->url unless $sam;
  return [] unless $sam;
  
  my @features;

  my $header = $sam->bam->header;

  # Maybe need to add 'chr' 
  my $seq_id = $self->munge_chr_id($chr_id);
  return [] if !defined($seq_id);

  my @coords = $header->parse_region("$seq_id:$start-$end");

  if (!@coords) {
    warn " *** could not parse_region for BAM with $chr_id:$start-$end\n";
    return [];
  }

  @features = $sam->get_features_by_location(-type   => 'read_pair',
                                             -seq_id => $seq_id,
                                             -start  => $start,
                                             -end    => $end);
  
  if ($DEBUG) {
    warn " *** fetch paired alignments: $chr_id:$start-$end : found ", scalar(@features), " alignments \n";
  }
  
  return \@features;
}

sub fetch_alignments_filtered {
  my ($self, $chr_id, $start, $end, $filter) = @_;

  #warn "bam url:" . $self->url if ($DEBUG > 2);
   
  my $bam = $self->bam_open;
  warn "Failed to open BAM file " . $self->url unless $bam;
  return [] unless $bam;
  
  my $index = $self->bam_index;
  warn "Failed to open BAM index for " . $self->url unless $index;
  return [] unless $index;

  #warn Dumper $filter if ($DEBUG > 2);


  my @features = ();

  my $callback = sub {
    my $a     = shift;
    if ($filter) {
      push @features, $a if ($filter->($a));
    } elsif ($a->start) { # default filter out unmapped mates - the ones that don't have location set
      push @features, $a;
    }
  };

  my $header = $bam->header;

  # Maybe need to add 'chr' 
  my $seq_id = $self->munge_chr_id($chr_id);
  return [] if !defined($seq_id);

  my @coords = $header->parse_region("$seq_id:$start-$end");

  if (!@coords) {
    warn " *** could not parse_region for BAM with $chr_id:$start-$end\n";
    return [];
  }

  $index->fetch($bam, @coords, $callback);
  
  if ($DEBUG) {
    warn " *** fetch alignments filtered: $chr_id:$start-$end : found ", scalar(@features), " alignments \n";
  }
  
  return \@features;
}

sub fetch_coverage {
  my ($self, $chr_id, $start, $end, $bins, $filter) = @_;

  #warn "bam url:" . $self->url if ($DEBUG > 2);
   
  my $sam = $self->sam_open;
  warn "Failed to open BAM file (as SAM)" . $self->url unless $sam;
  return [] unless $sam;
  
  my $index = $self->bam_index;
  warn "Failed to open BAM index for " . $self->url unless $index;
  return [] unless $index;

  #warn Dumper $filter if ($DEBUG > 2);

  # filter out unmapped mates - the ones that don't have location set
  $filter ||= sub {my $a = shift; return 0 unless $a->start; return 1};

  my $header = $sam->bam->header;

  #  Maybe need to add 'chr' 
  my $seq_id = $self->munge_chr_id($chr_id);
  return [] if !defined($seq_id);

  my @coords = $header->parse_region("$seq_id:$start-$end");

  if (!@coords) {
    warn " *** could not parse_region for BAM with $chr_id:$start-$end\n";
    return [];
  }

  my $segment = $sam->segment("$seq_id",$start,$end);

  my ($coverage) = $segment->features('coverage' . (defined($bins) ? ":$bins" : ""), $filter);
  my @data_points = $coverage->coverage;
  
  if ($DEBUG) {
    warn " *** fetch coverage: $chr_id:$start-$end : found ", scalar(@data_points), " coverage points \n";
  }
  
  return \@data_points;
}

sub fetch_consensus {
  my ($self, $chr_id, $start, $end, $min_score) = @_;
  my $T_QSCORE = $min_score || 0;

  if ($DEBUG) {
    warn "*** consensus: $chr_id, $start, $end , $T_QSCORE\n";
  }

  my $bam = $self->sam_open;
  return [] unless $bam;
  
  my @consensus;    # this will be list of basepair

  # the consensus method is real simple:
  # find the most frequent nucleotide in the position and check it against the
  # reference sequence : if they are not the same call a SNP
  # for the next stage we'd like to change it a bit:
  # call a SNP if various nucleotides appear in more than 20% of alignments

 
  #print STDERR "Generating consensus for $chr_id $start $end\n";


  my $consensus_caller = sub {
    my ($seqid, $pos, $p) = @_;

    if (($pos < $start) || ($pos > $end)) {
      return;
    }
#    my $refbase = $bam->segment($seqid, $pos, $pos)->dna;

    my ($total, $different);
    my $qhash;
    for my $pileup (@$p) {
      if ($pileup->indel || $pileup->is_refskip || $pileup->is_del) {
        $qhash->{'-'}++;
        next;
      }

      my $b = $pileup->alignment;

      my $qscore = $b->qscore->[$pileup->qpos];
      next unless $qscore > $T_QSCORE;
      my $qbase = uc(substr($b->qseq, $pileup->qpos, 1));
      $qhash->{$qbase}++;
    }
    my @ca = sort {$qhash->{$b} <=> $qhash->{$a}} keys %$qhash;
    my $c = shift @ca;

    #  my $bp = ($refbase eq $c) ? $c : $snpCode->{"${refbase}${c}"};
    my $bp = $c;
    if (my $c2 = shift(@ca)) {
      my $pr = $qhash->{$c2} / scalar(@$p);
      if ($pr > 0.4) {
#        $bp = $self->snp_code("${c2}${c}");
        $bp = $snpCode->{"${c2}${c}"};
      }
    }

    push @consensus, {
      bp => $bp,
      x  => $pos
      };

  };

  # Maybe need to add 'chr' 
  my $seq_id = $self->munge_chr_id($chr_id);
  return [] if !defined($seq_id);

  $bam->fast_pileup("${seq_id}:${start}-${end}", $consensus_caller);

#  $bam->fast_pileup("chr${chr_id}:${start}-${end}", $consensus_caller);
#  $bam->pileup("chr${chr_id}:${start}-${end}", $consensus_caller);

  return \@consensus;
}

1;
