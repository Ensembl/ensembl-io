=pod

=head1 LICENSE

  Copyright [2020] EMBL-European Bioinformatics Institute

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

Bio::EnsEMBL::IO::Parser::BCF - A line-based parser devoted to BCF

=cut

=head1 DESCRIPTION

BCF is a binary format of VCF

=cut

package Bio::EnsEMBL::IO::Parser::BCF;

use strict;
use warnings;

use Carp;
use Bio::DB::HTS::VCF;
use Bio::DB::HTS::VCF::Iterator;
use Smart::Comments;
use parent qw/Bio::EnsEMBL::IO::Parser/;

sub open {
  my ($caller, $filename, @other_args) = @_;
  my $class = ref($caller) || $caller;

  # initialize generic parser
  my $self = $class->SUPER::new(@other_args);


  $self->{record} = undef;
  $self->{bcf_file} = Bio::DB::HTS::VCF->new( filename => $filename );

  $self->{iterator} = undef;
  # $self->{delimiter} = "\t";

  return $self;
}

sub seek {
  my ($self, $chrom, $start, $end) = @_;

  $self->{iterator}->close()
    if UNIVERSAL::isa($self->{iterator}, 'Bio::DB::HTS::VCF::Iterator');

  ## Check for both possible versions of chromosome name
  foreach ($chrom, "chr$chrom")
  {
    my $region = "$_:$start-$end";
    $self->{iterator} = $self->{bcf_file}->query($region) ;
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
  my $report = $self->{bcf_file}->DESTROY;
  return (defined $report) ? 0 : 1;
}

sub num_variants {
  my $self = shift;

  return $self->{bcf_file}->num_variants();
}

sub header {
  my $self = shift;

  return $self->{bcf_file}->header();
}

sub next {
  my $self = shift;

  return $self->{bcf_file}->next();
}

sub query {
   my ($self, $region) = @_;

  return $self->{bcf_file}->query($region);
}

1;