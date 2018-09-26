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

package Bio::EnsEMBL::IO::Adaptor::HTSAdaptor;
use strict;

use Bio::EnsEMBL::Feature;
use Data::Dumper;
use Bio::DB::HTS;

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

sub new {
  my ($class, $url) = @_;

  my $self = bless {
    _cache => {},
    _url => $url,
  }, $class;

  return $self;
}

sub url { return $_[0]->{'_url'} };

#
# Open a Bio::DB::HTS object
#
sub hts_open
{
  my $self = shift;

  $self->{_cache}->{_htsobj_handle} ||= Bio::DB::HTS->new(-bam => $self->url);
  return $self->{_cache}->{_htsobj_handle};
}

sub snp_code {
    my ($self, $allele) = @_;

    return $snpCode->{$allele};
}

# UCSC prepend 'chr' on human chr ids. These are in some of the BAM
# files. This method returns a possibly modified chr_id after
# checking whats in the bam file
sub munge_chr_id {
  my ($self, $chr_id, $hts_obj) = @_;

  unless ( $chr_id && $hts_obj ) {
    unless ( $hts_obj && $hts_obj->hts_file ) {
      warn "Failed to open BAM/CRAM file " . $self->url;
    }
    return;
  }
  
  my $header = $hts_obj->header;

  # Check we get values back for seq region. May need to add 'chr' or 'Chr'
  my @coords = $header->parse_region("$chr_id");
  if (@coords) {
    return "$chr_id";
  }

  if (!@coords) {
    @coords = $header->parse_region("chr$chr_id");
    if (@coords) {
      return "chr$chr_id";
    }
  }

  if (!@coords) {
    @coords = $header->parse_region("Chr$chr_id");
    if (@coords) {
      return "Chr$chr_id";
    }
  }

  warn " *** could not parse_region for BAM/CRAM with $chr_id in file " . $self->url ."\n";
  return undef;
}

sub fetch_paired_alignments {
  my ($self, $chr_id, $start, $end) = @_;

  my $hts_obj = $self->hts_open;
  warn "Failed to open HTS object for file " . $self->url unless $hts_obj;
  return [] unless $hts_obj;

  my @features;

  my $header = $hts_obj->header;

  # Maybe need to add 'chr'
  my $seq_id = $self->munge_chr_id($chr_id, $hts_obj);
  return [] if !defined($seq_id);

  my @coords = $header->parse_region("$seq_id:$start-$end");

  if (!@coords) {
    warn " *** could not parse_region for BAM with $chr_id:$start-$end\n";
    return [];
  }

  @features = $hts_obj->get_features_by_location(-type   => 'read_pair',
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

  my $hts_obj = $self->hts_open;
  warn "Failed to open file " . $self->url unless $hts_obj;
  return [] unless $hts_obj;

  my $index = $hts_obj->hts_index;
  warn "Failed to open index for " . $self->url unless $index;
  return [] unless $index;

  my @features = ();

  my $callback = sub {
    my $a     = shift;
    if ($filter) {
      push @features, $a if ($filter->($a));
    } elsif ($a->start) { # default filter out unmapped mates - the ones that don't have location set
      push @features, $a;
    }
  };

  my $header = $hts_obj->header;

  # Maybe need to add 'chr'
  my $seq_id = $self->munge_chr_id($chr_id, $hts_obj);
  return [] if !defined($seq_id);

  my @coords = $header->parse_region("$seq_id:$start-$end");
  if (!@coords) {
    warn " *** could not parse_region for BAM with $chr_id:$start-$end\n";
    return [];
  }

  $index->fetch($hts_obj->hts_file, @coords, $callback);

  if ($DEBUG)
  {
    warn " *** fetch alignments filtered: $chr_id:$start-$end : found ", scalar(@features), " alignments \n";
  }
  my $num_features = scalar(@features) ;

  if ($DEBUG)
  {
    warn "The first 10 and last 10 features to see if this triggers an issue.\n" ;
    if( $num_features>10 )
    {
      warn "The first 10\n" ;
      for( my $i=0 ; $i<10 ; $i++ )
      {
        my $f = @features[$i] ;
        warn( "Feature $i: ".$f->start."\n" ) ;
      }
      warn "The last 10\n" ;
      for( my $i=($num_features-10) ; $i<$num_features ; $i++ )
      {
        my $f = @features[$i] ;
        warn( "Feature $i: ".$f->start."\n" ) ;
      }
    }
  }

  return \@features;
}

sub fetch_coverage {
  my ($self, $chr_id, $start, $end, $bins, $filter) = @_;

  my $hts_obj = $self->hts_open;
  warn "Failed to make HTS object from file " . $self->url unless $hts_obj;
  return [] unless $hts_obj;

  my $index = $hts_obj->hts_index;
  warn "Failed to open BAM index for " . $self->url unless $index;
  return [] unless $index;

  # filter out unmapped mates - the ones that don't have location set
  $filter ||= sub {my $a = shift; return 0 unless $a->start; return 1};

  my $header = $hts_obj->header;

  #  Maybe need to add 'chr'
  my $seq_id = $self->munge_chr_id($chr_id, $hts_obj);
  return [] if !defined($seq_id);

  my @coords = $header->parse_region("$seq_id:$start-$end");

  if (!@coords) {
    warn " *** could not parse_region for BAM with $chr_id:$start-$end\n";
    return [];
  }

  my $segment = $hts_obj->segment("$seq_id",$start,$end);

  my ($coverage) = $segment->features('coverage' . (defined($bins) ? ":$bins" : ""), $filter);
  my @data_points = $coverage->coverage;

  if ($DEBUG)
  {
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

  my $hts_obj = $self->hts_open;
  return [] unless $hts_obj;

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
#    my $refbase = $hts_obj->segment($seqid, $pos, $pos)->dna;

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
  my $seq_id = $self->munge_chr_id($chr_id, $hts_obj);
  return [] if !defined($seq_id);

  $hts_obj->fast_pileup("${seq_id}:${start}-${end}", $consensus_caller);

  return \@consensus;
}

1;
