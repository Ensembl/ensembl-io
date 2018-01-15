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

Bio::EnsEMBL::IO::Object::GFF3Metadata - Object to represent 

=head1 SYNOPSIS

  use Bio::EnsEMBL::IO::Object::GFF3Metadata;

  $record = Bio::EnsEMBL::IO::Object::GFF3Metadata->new($line);

  $type = $record->{type};

  $directive = $record->{directive};

  @values = $record->{value};

  $line = $record->create_record;

=head1 Description

An object to hold a generic column based format's record as a structure. Allows access to
elements via setters/getters. Setter/getters are dynamically added to the class on instantiation.

=cut

package Bio::EnsEMBL::IO::Object::GFF3Metadata;

use strict;
use warnings;
use Carp;

sub new {
    my ($class, $line) = @_;

    my $self = {};

    my ($type, @rest) = split /\s+/, $line;

    if($type =~ /^###/) {
	$self->{type} = 'fwd-ref-delimeter';
    } elsif($type =~ /^##(\S+)/) {
	$self->{type} = 'directive';
	$self->{directive} = $1;
	$self->{value} = \@rest;
    } elsif($type =~ /^#!(\S+)/) {
	$self->{type} = 'ens-directive';
	$self->{directive} = $1;
	$self->{value} = \@rest;
    } else {
	$self->{type} = 'comment';
	$self->{value} = substr $line, 1;
    }

    bless $self, $class;

    return $self;
}

sub create_record {
    my $self = shift;

    my $line;

    if($self->{type} eq 'fwd-ref-delimeter') {
	$line = "###\n";
    } elsif($self->{type} eq 'directive') {
	$line = "##$self->{directive} " . join(' ', @{$self->{value}}) . "\n";
    } elsif($self->{type} eq 'ens-directive') {
	$line = "#!$self->{directive} " . join(' ', @{$self->{value}}) . "\n";	
    } else {
	$line = "#$self->{value}\n";
    }

    return $line;
}

1;
