=pod

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

=head1 NAME

Bio::EnsEMBL::IO::Parser::BigBed - A line-based parser devoted to BigBed

=cut

package Bio::EnsEMBL::IO::Parser::BigBed;

use strict;
use warnings;
no warnings 'uninitialized';

use parent qw/Bio::EnsEMBL::IO::BigFileParser Bio::EnsEMBL::IO::Parser::Bed/;
 
=head2 type

    Description : Return case-correct version of format name, for use in method names 
    Returntype  : String

=cut

sub type {
    return 'bigBed'; 
}

=head2 seek

    Description: Fetches the raw data from the requested region and caches it 
    Returntype : Void

=cut

sub seek {
    my ($self, $chr_id, $start, $end) = @_;

    my $fh = $self->open_file;
    warn "Failed to open file ".$self->url unless $fh;
    return unless $fh;

    ## Get the internal chromosome name
    my $seq_id = $self->cache->{'chromosomes'}{$chr_id};
    return unless $seq_id;

    ## Remember this method takes half-open coords (subtract 1 from start)
    my $list_head = $fh->bigBedIntervalQuery("$seq_id", $start-1, $end);

    my $feature_cache = $self->cache->{'features'};

    for (my $i=$list_head->head; $i; $i=$i->next) {
      my @line = ($chr_id, $i->start, $i->end, split(/\t/,$i->rest));
      push @$feature_cache, \@line;
    }
    ## pre-load peek buffer
    $self->next_block();
}

=head2 fetch_summary_data 

    Description: fetches data from the requested region, grouped into 
                  a set number of bins, and caches it
    Returntype : Void

=cut

sub fetch_summary_data {
    my ($self, @args) = @_;
    
    ## In effect we're creating a bedGraph, so tell the Bed parser this
    $self->{'metadata'}{'type'} = 'bedGraph';
    $self->SUPER::fetch_summary_data(@args);
}


1;
