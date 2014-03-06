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

=head1 NAME

Bio::EnsEMBL::IO::Parser::FastaParser - A record-based parser devoted to FASTA format

=head1 DESCRIPTION

  Slurps entire sequence chunks into memory. Handle with care and avoid hanging
  onto too many segments of the file if you value your memory.

=cut

package Bio::EnsEMBL::IO::Parser::EMFParser;

use strict;
use warnings;
use Data::Dumper;

use base qw/Bio::EnsEMBL::IO::TokenBasedParser/;


=head2 open

  Description  : Open the EMF file
  Argument [1] : Path to the EMF file
  Returntype   : Ensembl::IO::Parser::EMFParser object

=cut

sub open {
  my ($caller, $filename, @other_args) = @_;
  my $class = ref($caller) || $caller;

  my $self = $class->SUPER::open($filename, undef, '^//', mustParseMetadata=>1, @other_args);
  $self->next_block();

  return $self;
}

sub read_metadata {
  my ($self) = @_;

  my $line = $self->{'current_block'};
  if ($line =~ /^##FORMAT.*(compara|resequencing|gene_alignment)/) {
    $self->format($1);
  } elsif ($line =~ /^##DATE\s*(.*)/) {
    $self->date($1);
  } elsif ($line =~ /^##RELEASE\s*(.*)/){
    my @releases = split /\s+/, $1;
    $self->releases([@releases]);
  }
}

sub read_record {
  my ($self) = @_;

  my $rec;
  $self->next_block;
  while (not $self->is_at_end_of_record) {
    next if ($self->{'current_block'} =~ /^$/);
    $rec .= $self->{'current_block'};
    $self->next_block;
  }

  my @lines = split ("\n", $rec);
  my $first_line = shift @lines;
  chomp $first_line;
  $self->add_first_seq($first_line);

  while (my $line = shift @lines) {
    if ($line  =~ /^SEQ/) {
      $self->add_seq($line);
      next;
    }
    if ($line =~ /^TREE/) {
      $self->add_tree($line);
      next;
    }
    if ($line =~ /^SCORE/) {
      $self->add_score_type($line);
      next;
    }
    if ($line =~ /^DATA/) {
      ## The rest are the actual sequences
      next
    }

    $self->parse_seq($line);
#    exit;
  }

  return [1];
}

sub is_metadata {
  my ($self) = @_;
  return $self->{'current_block'} =~ /^#/;
}


#####################################

sub parse_seq {
  my ($self, $line) = @_;

  my @flds = grep {$_ ne ' '} split('',$line); ## grep because of optional spaces
  my @nts = (@flds[0..scalar@{$self->sequences}-1]);
  my @scores = ();
  if (defined $self->score_types && scalar @{$self->score_types}) {
    @scores = (@flds[scalar@{$self->sequences}..scalar@{$self->sequences}+scalar@{$self->score_types}-1]);
  }

  my $rec = { 'sequence' => [@nts],
	      'scores'   => [@scores],
	    };

  push @{$self->{_columns}}, $rec;

}


sub add_score_type {
  my ($self, $line) = @_;
  $line =~ /^SCORE\s+(.*)/;
  my $score_type = $1;
  push @{$self->{_score_types}}, $score_type;
  return
}

sub add_tree {
  my ($self, $line) = @_;
  $line =~ /TREE\s+(.*)/;
  my $tree = $1;
  $self->tree($tree);
  return;
}

sub add_seq {
  my ($self, $seq) = @_;

  push @{$self->{_seqs}}, $self->parse_seq_line($seq);
  return;
}

sub parse_seq_line {
  my ($self, $seq) = @_;

  my $rec = {};

  my @fields = split /\s+/, $seq;
  shift @fields; # SEQ token
  $rec->{'organism'} = shift @fields;
  if ($self->format eq 'resequencing') {
    $rec->{source} = pop @fields;
    $rec->{individual} = join (" ", @fields);
  } else {
    if ($self->format eq 'gene_alignment') {
      $rec->{'translation_stable_id'} = shift @fields;
    }
    $rec->{chr}        = shift @fields;
    $rec->{seq_start}  = shift @fields;
    $rec->{seq_end}    = shift @fields;
    $rec->{seq_strand} = shift @fields;

    if ($self->format eq 'gene_alignment') {
      $rec->{gene_stable_id} = shift @fields;
      $rec->{display_label}  = shift @fields;
    }
  }

  return $rec;
}

sub add_first_seq {
  my ($self, $seq) = @_;

  $self->{_seqs} = [$self->parse_first_seq_line($seq)];
  return;
}

sub parse_first_seq_line {
  my ($self, $seq) = @_;
  my $rec = {};

  my @fields = split /\s+/,$seq;
  shift @fields; ## SEQ token
  $rec->{organism} = shift @fields;
  if ($self->format eq 'resequencing') {
    $rec->{individual} = shift @fields;
  } elsif ($self->format eq 'gene_alignment') {
    $rec->{translation_stable_id} = shift @fields;
  }

  $rec->{chr}        = shift @fields;
  $rec->{seq_start}  = shift @fields;
  $rec->{seq_end}    = shift @fields;
  $rec->{seq_strand} = shift @fields;

  if ($self->format eq 'gene_alignment') {
    $rec->{gene_stable_id} = shift @fields;
    $rec->{display_label}  = shift @fields;
  }

  return $rec;

}

########## EXTERNAL API ##########

sub sequences {
  my ($self) = @_;
  return $self->{_seqs}
}

sub score_types {
  my ($self) = @_;
  return $self->{_score_types} || [];
}

sub tree {
  my ($self, $tree) = @_;
  if ($self->format eq "resequencing") {
    warn "No TREE is allowed in 'resequencing' EMF format\n";
    return;
  }
  if (defined $tree) {
    $self->{_tree} = $tree;
  }
  return $self->{_tree};
}

sub format {
  my ($self, $format) = @_;
  if (defined $format) {
    $self->{_format} = $format;
  }
  return $self->{_format};
}

sub date {
  my ($self, $date) = @_;
  if (defined $date) {
    $self->{_date} = $date;
  }
  return $self->{_date};
}

sub releases {
  my ($self, $releases) = @_;
  if ((defined $releases) && (ref $releases eq 'ARRAY') && (scalar @$releases)) {
    $self->{_releases} = $releases;
  }
  return $self->{_releases};
}

sub get_next_column {
  my ($self) = @_;
  return shift @{$self->{_columns}};
}

1;

