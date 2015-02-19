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

Bio::EnsEMBL::IO::Parser::GTF - A line-based parser devoted to GTF

=cut

package Bio::EnsEMBL::IO::Parser::GTF;

use strict;
use warnings;

use base qw/Bio::EnsEMBL::IO::Parser::GXF/;

sub open {
    my ($caller, $filename, @other_args) = @_;
    my $class = ref($caller) || $caller;

    my $self = $class->SUPER::open($filename, @other_args);

    # Metadata defaults
    if ($self->{'params'}->{'mustReadMetadata'}) {
       $self->{'metadata'}->{'gtf-version'} = '2';
       $self->{'metadata'}->{'Type'} = 'DNA';
    }

    # pre-load peek buffer
    $self->next_block();

    return $self;
}

sub read_metadata {
    my $self = shift;
    my $line = $self->{'current_block'};

    if ($line =~ /^\s*##(\S+)\s+(\S+)/) {
        $self->{'metadata'}->{$1} = $2;
    }
    elsif ($line =~ /^#/ and $line !~ /^#\s*$/) {
        chomp $line;
        push(@{$self->{metadata}->{comments}}, $line);
    }
}

=head2 get_attributes
    Description : Return the content of the 9th column of the line in a hash: "attribute => value"
    Returntype  : Reference to a hash
=cut

sub get_attributes {
  my $self = shift;
  my %attributes;
  foreach my $attr (split(';',$self->get_raw_attributes)) {
    my ($key,$value) = split(' ',$attr, 2);
    $value =~ s/"//g;
    $attributes{$key} = $value;
  }
  return \%attributes;
}

=head2 get_attribute_by_name
    Argument[1] : $name, name of the attribute
    Description : Return the value for attribute $name
                  If you want to use several attributes, use $self->get_attributes,
                  which returns a hashref where the key are the attribute names
    Returntype  : String
=cut

sub get_attribute_by_name {
    my ($self, $name) = @_;

    # We're looking at beginning of line or ';', then getting the attribute value.
    # We hope that people don't use the same attribute multiple times
    # This implementation is either very smart or pretty bad...
    my (undef, $value) = $self->get_raw_attributes =~ /(\A|;)$name "([^"]+)"/;
    # If $value is not undef, return decoded $value
    return $value ? $self->decode_html($value) : $value;
}

1;
