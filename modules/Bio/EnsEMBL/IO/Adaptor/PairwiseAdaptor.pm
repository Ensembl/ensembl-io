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

package Bio::EnsEMBL::IO::Adaptor::PairwiseAdaptor;

use strict;

use Bio::EnsEMBL::IO::Parser::PairwiseTabix;

my $DEBUG = 0;

sub new {
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
    my %pair;

    if (!$parser) {
      $parser = Bio::EnsEMBL::IO::Parser::PairwiseTabix->open($self->url);
      $self->{_cache}->{'parser'} = $parser;
    }

    foreach my $chr_name ($chr,"chr$chr") { # maybe UCSC-type names?

      my $ok_data = eval {$parser->seek($chr_name, $s, $e);};
      next unless $ok_data;
     
      while ($parser->next) {

        my @interacting_region = $parser->get_interacting_region;

        ## Is this the other half of a feature pair?
        if (keys %pair && $pair{'seqname'} eq $interacting_region[0]
                        && $pair{'start_1'} eq $interacting_region[1]
                        && $pair{'end_1'} eq $interacting_region[2]
          ) {
          $pair{'id_2'} = $parser->get_id; 
          my %hash = %pair;
          push @features, \%hash;
          ## Now we have everything we need, so get rid of the old data
          %pair = ();
        }
        else {
          $pair{'seqname'}    = $parser->get_seqname;
          $pair{'start_1'}    = $parser->get_start;
          $pair{'end_1'}      = $parser->get_start;
          $pair{'id_1'}       = $parser->get_id;
          $pair{'score'}      = $parser->get_score;
          $pair{'direction'}  = $parser->get_direction;
          ($pair{'seq_2'}, $pair{'start_2'}, $pair{'end_2'}) = @interacting_region;
          ## We're done here - go to next feature
        }
      } 
    }
    warn ">>> FEATURES @features";
    $self->{_cache}->{features} = \@features;
  }
  return $self->{_cache}->{features};
}

1;
