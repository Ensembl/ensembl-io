=pod

=head1 LICENSE

  Copyright (c) 1999-2013 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

  http://www.ensembl.org/info/about/code_licence.html

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
    print STDERR "FIRST NOT SEQ LINE: $line\n";
    last;
  }

  # if ($rec =~ /^SEQ\s*(.*)/) {
  #   $self->add_seq($1);
  # }
  return [1];
}

sub is_metadata {
  my ($self) = @_;
  return $self->{'current_block'} =~ /^#/;
}


#####################################

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
    $self->{individual} = shift @fields;
    $self->{source}     = shift @fields;
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

########## RECORD BASED API ##########

sub sequences {
  my ($self) = @_;
  return $self->{_seqs}
}

1;

