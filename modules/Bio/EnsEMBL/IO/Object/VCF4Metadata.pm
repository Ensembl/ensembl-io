=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

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

Bio::EnsEMBL::IO::Object::VCF4Metadata - Object to represent VCF 4.2 metadata

=head1 SYNOPSIS

  use Bio::EnsEMBL::IO::Object::VCF4Metadata;

  $record = Bio::EnsEMBL::IO::Object::VCF4Metadata->new($line);

  $type = $record->{type};

  $directive = $record->{directive};

  @values = $record->{value};

  $line = $record->create_record;

=head1 Description

An object to hold a generic column based format's record as a structure. Allows access to
elements via setters/getters. Setter/getters are dynamically added to the class on instantiation.

=cut

package Bio::EnsEMBL::IO::Object::VCF4Metadata;

use base qw/Bio::EnsEMBL::IO::Object::Metadata/;

use strict;
use warnings;
use Carp;

my $FORMAT_HEADER = 'FORMAT';
my @HEADER = ('CHROM','POS','ID','REF','ALT','QUAL','FILTER','INFO');
my @HEADER_FORMAT = @HEADER;
push @HEADER_FORMAT, $FORMAT_HEADER;

my %INFO = ( 'AA'  => '<ID=AA,Number=1,Type=String,Description="Ancestral Allele">',
             'AC'  => '<ID=AC,Number=1,Type=Integer,Description="Allele Count">',
             'AF'  => '<ID=AF,Number=A,Type=Float,Description="Allele Frequency">',
             'AN'  => '<ID=AN,Number=1,Type=Integer,Description="Total Number of Alleles">',
             'MA'  => '<ID=MA,Number=1,Type=String,Description="Minor Allele">',
             'MAF' => '<ID=MAF,Number=1,Type=Float,Description="Minor Allele Frequency">',
             'MAC' => '<ID=MAC,Number=1,Type=Integer,Description="Minor Allele Count">',
             'NS'  => '<ID=NS,Number=1,Type=Integer,Description="Number of Samples With Data">'
           );

my %FORMAT= ( 'GT' => '<ID=GT,Number=1,Type=String,Description="Genotype">' );

sub new {
    my ($class, $line) = @_;

    my $self = {};

    my ($type, @rest) = split /\s+/, $line;

    if($type =~ /^##(\S+)/) {
	    $self->{type} = 'directive';
	    $self->{directive} = $1;
	    $self->{value} = \@rest;
    } elsif($type =~ /^#(\S+)/) {
      my $indiv_col_start = length(@HEADER_FORMAT)-1;
      my %column_header = map { $_ => 1 } @rest;
      if (!$column_header{$FORMAT_HEADER}) {
        $indiv_col_start = length(@HEADER)-1;
      }
      my @indiv = splice @rest, $indiv_col_start;
	    $self->{type} = 'header';
	    $self->{value} = \@indiv;
    }

    bless $self, $class;

    return $self;
}

=head2 directive

    Description: Create a directive type VCF metadata (##)
    Args[1]    : The directive type (e.g. fileformat)
    Args[2]    : Directive value (e.g. VCFv4.2).
    Returntype : Bio::EnsEMBL::IO::Object::VCF4Metadata

=cut

sub directive {
    my $class = shift;
    my $directive = shift;
    my $arg = shift;

    return bless {type => 'directive', directive => $directive, value => [$arg]}, $class;
}

=head2 info

    Description: Create a info directive type VCF metadata (##INFO)
    Args[1]    : INFO value (e.g. AA).
    Returntype : Bio::EnsEMBL::IO::Object::VCF4Metadata

=cut

sub info {
    my $class = shift;
    my $arg   = shift;

    if ($arg && $INFO{$arg}) {
      return bless {type => 'directive', directive => 'INFO', value => [$INFO{$arg}]}, $class;
    }
    else {
      warn "Info type '$arg' is not found in the list of the predefined INFO values (".join(',',keys(%INFO)).").\n";
      return bless {type => 'directive', directive => 'INFO', value => []}, $class;
    }
}

=head2 format

    Description: Create a format directive type VCF metadata (##FORMAT)
    Args[1]    : FORMAT value (e.g. GT).
    Returntype : Bio::EnsEMBL::IO::Object::VCF4Metadata

=cut

sub format {
    my $class = shift;
    my $arg   = shift;

    return bless {type => 'directive', directive => 'FORMAT', value => [$FORMAT{$arg}]}, $class;
}

=head2 header

    Description: Create a VCF header line (#)
    Args[1]    : Individual/sample names as an array.
                 It will be put together as a tab separated 
                 string when create_record is called.
    Returntype : Bio::EnsEMBL::IO::Object::VCF4Metadata

=cut

sub header {
    my $class = shift;
    my $args  = shift;

    if (ref($args) ne 'ARRAY' || !$args) {
      warn "No individuals/samples list defined for the VCF header!\n";
      $args = [];
    }

    my @header_cols = (scalar(@$args) > 0) ? @HEADER_FORMAT : @HEADER;

    return bless {type => 'header', header => join("\t", @header_cols), value => $args}, $class;
}



sub create_record {
  my $self = shift;

  my $line;

  if($self->{type} eq 'directive') {
    return if (scalar(@{$self->{value}}) == 0);
	  $line = "##" . $self->{directive} . "=" . join(',', @{$self->{value}}) . "\n";
  } elsif($self->{type} eq 'header') {
    my $header_sep = (scalar(@{$self->{value}}) > 0) ? "\t" : '';
	  $line = "#" . $self->{header} . "$header_sep" . join("\t", @{$self->{value}}) . "\n";	
  }

  return $line;
}
