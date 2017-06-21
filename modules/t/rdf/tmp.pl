#!/usr/bin/env/perl

use strict;
use warnings;

my $var = qw/a b/; # fun();

print "$var\n";

sub fun {
  return ('a', 'b');
}





  sub namespaces {
    my ($class, %prefix) = @_;
    %prefix = %Bio::EnsEMBL::Utils::RDF::prefix unless %prefix;
    
    return bless { type => 'namespaces', prefix => \%prefix }, $class;
  }

  sub species {
    my $class = shift;
    my %args = @_;
    exists $args{taxon_id} or croak "Undefined species taxon_id";
    exists $args{scientific_name} or croak "Undefined species scientific name";
    exists $args{common_name} or croak "Undefined species common name";
  
    return bless { type => 'species', %args }, $class;
  }




  sub create_record {
    my $self = shift;
    
    my $line;
    
    if($self->{type} eq 'namespaces') {
      return unless scalar keys %{$self->{prefix}};
      
      $line = join("\n", map { sprintf "\@prefix %s: %s .", $_, u($self->{prefix}{$_}) } sort keys %{$self->{prefix}});
    } elsif($self->{type} eq 'species') {
      my $taxon_id = $self->{taxon_id};
      my $scientific_name = $self->{scientific_name};
      my $common_name = $self->{common_name};
      
      # return global triples about the organism  
      $line = sprintf "%s\n%s\n%s\n%s",
	triple('taxon:'.$taxon_id, 'rdfs:subClassOf', 'obo:OBI_0100026'),
	triple('taxon:'.$taxon_id, 'rdfs:label', qq("$scientific_name")),
	triple('taxon:'.$taxon_id, 'skos:altLabel', qq("$common_name")),
	triple('taxon:'.$taxon_id, 'dc:identifier', qq("$taxon_id"));
    } else {
      croak "Unrecognised RDF object type";
    }
    
    return $line;
  }



  my %field_callbacks = (version         => 'version',
			 production_name => 'production_name',
			 taxon_id        => 'taxon_id',
			 scientific_name => 'scientific_name',
			 name            => 'name',
			 cs_name         => 'coord_system_name',
			 cs_version      => 'coord_system_version',
			 uri             => 'uri'
			);


  sub write {
    my $self = shift;
    my $object = shift;
    my $translator = shift;

    if($object->isa('Bio::EnsEMBL::IO::Object::Metadata')) {
	    print { $self->{writer_handle} } $object->create_record();
    } else {
	    # Use the default translator if we haven't been given one
	    $translator ||= $self->translator();
	    print { $self->{writer_handle} } $self->create_record($object, $translator);
    }
  }



  
  sub create_record {
    my $self = shift;
    my $object = shift;
    my $translator = shift || $self->translator;
    return unless $translator;
    
    my @values = $translator->batch_fields($object, $self->fields());
    
    return $self->concatenate_fields(\@values), "\n";
    
  }




 sub create_record {
   my $self = shift;

   my $line;

   if ($self->{type} eq 'directive') {
     return if (scalar(@{$self->{value}}) == 0);
     $line = "##" . $self->{directive} . "=" . join(',', @{$self->{value}}) . "\n";
   } elsif ($self->{type} eq 'header') {
     my $header_sep = (scalar(@{$self->{value}}) > 0) ? "\t" : '';
     $line = "#" . $self->{header} . "$header_sep" . join("\t", @{$self->{value}}) . "\n";	
   }

   return $line;
 }




 
 
 sub _seq_region_record {
   my ($class, $object, $translator) = @_;

   my $version = $translator->version();
   my ($region_name, $cs_name, $cs_version, $scientific_name) =
     $translator->batch_fields($object, [qw/name cs_name cs_version scientific_name/]);
   my ($version_uri, $non_version_uri) = $translator->uri($object);

   my $record;
  
   # we also create a non versioned URI that is a superclass e.g. 
   $record = sprintf "%s\n", triple($version_uri, 'rdfs:subClassOf', $non_version_uri);
  
   if ($cs_name eq 'chromosome') { 
     $record .= sprintf "%s\n", triple($non_version_uri, 'rdfs:subClassOf', 'obo:SO_0000340');
     # Find SO term for patches and region in general?
   } else {
     $record .= sprintf "%s\n%s\n",
       triple($non_version_uri, 'rdfs:subClassOf', 'term:'.$cs_name),
       triple('term:'.$cs_name, 'rdfs:subClassOf', 'term:EnsemblRegion');
   }
   $record .= sprintf "%s\n%s\n%s\n%s\n%s",
     triple($non_version_uri, 'rdfs:label', qq("$scientific_name $cs_name $region_name")),
     triple($version_uri, 'rdfs:label', qq("$scientific_name $region_name ($cs_version)")),
     triple($version_uri, 'dc:identifier', qq("$region_name")),
     triple($version_uri, 'term:inEnsemblSchemaNumber', qq("$version")),
     triple($version_uri, 'term:inEnsemblAssembly', qq("$cs_version"));

   return $record;
 }


 
