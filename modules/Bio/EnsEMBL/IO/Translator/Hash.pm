=pod

=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2020] EMBL-European Bioinformatics Institute

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

Translator::Hash - generic class for accessing the simple data structures used by the new drawing code 

Note that if the method needs to return something other than a string, it is necessary
to define a method in this module

=cut

package Bio::EnsEMBL::IO::Translator::Hash;

use strict;
use warnings;

use Carp;

use parent qw/Bio::EnsEMBL::IO::Translator/;


=head2 get_field

    Description: Fetch a field from the feature. Use the 
                  local method if available, otherwise
                  just get the corresponding key from 
                  the data hash
    Args[1]    : Feature to fetch fields from
    Args[2]    : Field name
    Returntype : String, hashref or undef

=cut

sub get_field {
    my $self    = shift;
    my $feature = shift;
    my $field   = shift;
    #warn "@@@ GETTING FIELD $field FROM FEATURE";

    # If we have the requested method, use it
    my $method = 'get_'.$field;
    my $value;
    if ($self->can($method)) {
      #warn ">>> USING METHOD $method";
      $value = $self->$method($feature);
    }
    else {
      #warn "### USING HASH KEY";
      $value = $feature->{$field};
    }
    $value ||= '.';
    #warn "... VALUE $value";

    return $value;
}


=head2 seqname

    Description: Wrapper around hash key 
    Returntype : String

=cut

sub get_seqname {
  my ($self, $feature) = @_;
  return $feature->{'chr'};
}


=head2 get_name

    Description: Wrapper around hash key 
    Returntype : String

=cut

sub get_name {
  my ($self, $feature) = @_;
  return $feature->{'label'};
}

=head2 get_attributes

    Description: Wrapper around hash key 
    Returntype : Hashref

=cut

sub get_attributes {
  my ($self, $feature) = @_;
  return $feature->{'attributes'} || {};
}



=head2 get_thickStart

    Description: Returns feature start or start of transcribed region
    Returntype : Integer

=cut

sub get_thickStart {
  my ($self, $feature) = @_;
  return $feature->{'start'} unless $feature->{'structure'};
  return $feature->{'structure'}[0]{'start'};
}

=head2 get_thickEnd

    Description: Returns feature end or end of transcribed region 
    Returntype : Integer

=cut

sub get_thickEnd {
  my ($self, $feature) = @_;
  return $feature->{'end'} unless $feature->{'structure'};
  return $feature->{'structure'}[-1]{'end'};
}

=head2 get_itemRgb

    Description: Returns feature colour 
    Returntype : String

=cut

sub get_itemRgb {
  my ($self, $feature) = @_;
  return $feature->{'colour'} || '.'; 
}

=head2 get_blockCount

    Description: Returns details of internal structure of feature, if it has one 
    Returntype : Integer

=cut

sub get_blockCount {
  my ($self, $feature) = @_;
  return scalar @{$feature->{'structure'}||[]};
}

=head2 get_blockStarts

    Description: Returns details of internal structure of feature, if it has one 
    Returntype : String

=cut

sub get_blockStarts {
  my ($self, $feature) = @_;
  return '.' unless $feature->{'structure'};

  my @starts;
  foreach (@{$feature->{'structure'}}) {
    push @starts, $_->{'start'};
  }
  return join(',', @starts);
}

=head2 get_blockSizes

    Description: Returns details of internal structure of feature, if it has one 
    Returntype : String

=cut

sub get_blockSizes {
  my ($self, $feature) = @_;
  return '.' unless $feature->{'structure'};

  my @starts;
  foreach (@{$feature->{'structure'}}) {
    push @starts, ($_->{'end'} - $_->{'start'});
  }
  return join(',', @starts);
}

1;
