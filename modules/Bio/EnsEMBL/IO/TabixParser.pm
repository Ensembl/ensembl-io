=pod

=head1 LICENSE

  Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

Bio::EnsEMBL::IO::TabixParser - A line-based parser devoted to files using tabix indexing tool

=cut

=head1 DESCRIPTION

See tabix: https://github.com/samtools/tabix

=cut

package Bio::EnsEMBL::IO::TabixParser;

use strict;
use warnings;

use Carp;
use Bio::DB::HTS::Tabix;
use Bio::DB::HTS::Tabix::Iterator;

use base qw/Bio::EnsEMBL::IO::Parser/;

sub open {
  my ($caller, $filename, @other_args) = @_;
  my $class = ref($caller) || $caller;

  my $delimiter = "\t";
  my $self = $class->SUPER::new(@other_args);

  confess "ERROR: Input file is not bgzipped, cannot use tabix\n" unless $filename =~ /\.gz$/;

  $self->{record}     = undef;
  $self->{tabix_file} = Bio::DB::HTS::Tabix->new(filename => $filename);
  $self->{iterator}   = undef;

  return $self;
}

sub seek {
  my ($self, $chrom, $start, $end) = @_;
  if (defined $self->{iterator})
  {
    $self->{iterator}->close();
  }

  ## Check for both possible versions of chromosome name
  foreach ($chrom, "chr$chrom")
  {
    $self->{iterator} = $self->{tabix_file}->query("$chrom:$start-$end") ;
    last if $self->{iterator};
  }

  # pre-load peek buffer
  if ($self->{iterator}) {
    $self->next_block();
    return 1;
  }
  else {
    return 0;
  }
}

sub next_block {
  my $self = shift;
  if (!defined $self->{iterator}) {
    ## Not sure if it's sensible to warn this by default, as it gets triggered in legitimate circumstances
    ## and will thus tend to fill up the web logs
    #warn "Must seek region before reading with TabixParser\n";
    exit 1;
  }
  $self->shift_block();
}

sub read_block {
    my $self = shift;
    $self->{waiting_block} = $self->{iterator}->next;
}

sub close {
  my $self = shift;
  $self->{iterator}->close if $self->{iterator};
  my $report = $self->{tabix_file}->DESTROY;
  return (defined $report) ? 0 : 1;
}

1;
