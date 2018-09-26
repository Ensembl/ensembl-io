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

package Bio::EnsEMBL::IO::Adaptor::PairwiseAdaptor;

######################## DEPRECATED ################################
# No longer in use by the webcode; will be removed in November 2016
####################################################################


use strict;

use Bio::EnsEMBL::IO::Parser::PairwiseTabix;

my $DEBUG = 0;

sub new {
warn "################# DEPRECATED PACKAGE ######################################
## Functionality has been moved into EnsEMBL::Web::IOWrapper::PairwiseTabix
## in the ensembl-webcode repository
###########################################################################
";
  my ($class, $url) = @_;
  my $self = bless {
    _cache => {},
    _url => $url,
  }, $class;
      
  return $self;
}

sub url { return $_[0]->{'_url'} };


sub fetch_features {
  my ($self, $chr, $s, $e) = @_;

  if (!$self->{_cache}->{features} || (ref $self->{_cache}->{features} eq 'ARRAY' && !@{$self->{_cache}->{features}})){
    my @features;

    delete $self->{_cache}->{features};

    my $parser = $self->{_cache}->{'parser'};

    if (!$parser) {
      $parser = Bio::EnsEMBL::IO::Parser::PairwiseTabix->open($self->url);
      $self->{_cache}->{'parser'} = $parser;
    }

    foreach my $chr_name ($chr,"chr$chr") { # maybe UCSC-type names?

      my $ok_data = eval {$parser->seek($chr_name, $s, $e);};
      next unless $ok_data;
     
      while ($parser->next) {
        my $feature;
        $feature->{'seqname'}    = $parser->get_seqname;
        $feature->{'start_1'}    = $parser->get_start;
        $feature->{'end_1'}      = $parser->get_start;
        $feature->{'id_1'}       = $parser->get_id;
        $feature->{'score'}      = $parser->get_score;
        $feature->{'direction'}  = $parser->get_direction;
        ($feature->{'seqname_2'}, $feature->{'start_2'}, $feature->{'end_2'}, $feature->{'score'}) = @{$parser->get_information}; 
        push @features, $feature;
      } 
    }
    $self->{_cache}->{features} = \@features;
  }
  return $self->{_cache}->{features};
}

1;
