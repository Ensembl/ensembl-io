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


=head1 NAME

Bio::EnsEMBL::IO::Parser::GTF - A line-based parser devoted to GTF

=cut

package Bio::EnsEMBL::IO::Parser::GTF;

use strict;
use warnings;

use base qw/Bio::EnsEMBL::IO::Parser::GXF/;

use Bio::EnsEMBL::IO::Object::GTF;

sub open {
    my ($caller, $filename, @other_args) = @_;
    my $class = ref($caller) || $caller;

    my $self = $class->SUPER::open($filename, @other_args);

    # Metadata defaults
    if ($self->{'params'}->{'must_parse_metadata'}) {
       $self->{'metadata'}->{'gtf-version'} = '2';
       $self->{'metadata'}->{'Type'} = 'DNA';
    }

    # pre-load peek buffer
    $self->next_block();

    return $self;
}

=head2 set_minimum_column_count

    Description: Sets minimum column count for a valid GTF file
    Returntype : Void

=cut

sub set_minimum_column_count {
    my $self = shift;
    $self->{'min_col_count'} = 8;
}

=head2 is_metadata

    Description: Identifies track lines and other metadata 
    Returntype : String 

=cut

sub is_metadata {
    my $self = shift;
    if ($self->{'current_block'} =~ /^track/
        || $self->{'current_block'} =~ /^browser/
        || $self->{'current_block'} =~ /^#/
      ) {
      return $self->{'current_block'};
    }
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
    elsif ($line =~ /^browser\s+(\w+)\s+(.*)/i ) {
      $self->{'metadata'}->{'browser_switches'}{$1} = $2;
    }
    elsif ($line =~ /^track/) {
      ## Grab any params wrapped in double quotes (to enclose whitespace)
      while ($line =~ s/(\w+)\s*=\s*"(([\\"]|[^"])+?)"//) {
        my $key = $1;
        (my $value = $2) =~ s/\\//g;
        $self->{'metadata'}->{$key} = $value;
      }
      ## Deal with any remaining whitespace-free content
      if ($line) {
        while ($line =~ s/(\w+)\s*=\s*(\S+)//) {
          $self->{'metadata'}->{$1} = $2;
        }
      }
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
    my ($key, $value) = split(' ',$attr, 2);
    $value =~ s/"//g if $value;
    $key =~ s/^\s+//;
    $key =~ s/\s+$//;
    $attributes{$key} = $value ? $self->decode_string($value) : $value;
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
    my (undef, $value) = $self->get_raw_attributes =~ /(\A|;) *$name "([^"]+)"/;
    # If $value is not undef, return decoded $value
    return $value ? $self->decode_string($value) : $value;
}

=head2 create_object

    Description: Create an object encapsulation for the record
    Returntype : Bio::EnsEMBL::IO::Object::GTF
=cut

sub create_object {
    my $self = shift;

    return $self->SUPER::create_object(Bio::EnsEMBL::IO::Object::GTF->new($self->get_fields));
}

1;
