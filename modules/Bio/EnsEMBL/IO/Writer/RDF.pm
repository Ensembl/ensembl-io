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

Bio::EnsEMBL::IO::Writer::ColumnBasedGeneric - Generic writer for column based formats

=head1 SYNOPSIS

  The class should not be directly instantiated, but derived to a subclass
  based on the format.

=head1 Description


=cut

package Bio::EnsEMBL::IO::Writer::RDF;

use parent qw/Bio::EnsEMBL::IO::Writer/;

use strict;
use warnings;
use Carp;

use URI::Escape;
use Bio::EnsEMBL::Utils::RDF qw/u escape prefix triple taxon_triple clean_for_uri seq_region_uri feature_uri/;

=head2 new

=cut

sub new {
    my $class = shift;
    my $translator = shift;

    my $self = $class->SUPER::new();

    $self->translator($translator) if $translator;

    return $self;
}

=head2 write

    Description: Write a record to the output, it will use the given
                 translator to interrogate the object for the needed fields
    Args[1]    : Object to write out
    Args[2]    : an alternative translator to use for this record

=cut

sub write {
  my $self = shift;
  my $object = shift;
  my $translator = shift;

  if (ref($object) =~ /HASH/ || $object->isa('Bio::EnsEMBL::Slice')) {
    print { $self->{writer_handle} } $self->create_record($object, $translator), "\n";
  } elsif ($object->isa('Bio::EnsEMBL::IO::Object::RDF')) {
    print { $self->{writer_handle} } $object->create_record(), "\n";
  } 
}

=head2 create_record

    Description: Create the record in native format to write out to the file
    Args[1]    : Object to format
    Args[2]    : Translator
    Returntype : String

=cut

sub create_record {
  my $self = shift;
  my $object = shift;

  # Use the default translator if we haven't been given one
  my $translator = shift || $self->translator;
  return unless $translator;

  if (ref($object) =~ /HASH/) {
    my $record;
    $self->_bulk_fetcher_feature_record($object, $translator, \$record);
    return $record;
  }
  
  return $self->_seq_region_record($object, $translator)
    if $object->isa('Bio::EnsEMBL::Slice');
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

# This method calls recursively down the gene->transcript->translation chain and prints them all
# It can also be used safely with other kinds of features, at least superficially.
# Any specific vocabulary must be added to describe anything other than the entity and its location

sub _bulk_fetcher_feature_record {
  my ($self, $object, $translator, $record) = @_;
  my $feature_uri = $translator->uri($object);
  my $feature_type = $translator->type($object);
  
  # Translations don't have biotypes. Other features won't either.
  my $biotype = $translator->biotype($object);
  if ($biotype) {
    my $so_term = $translator->so_term($object);
    ${$record} .= sprintf "%s\n", triple(u($feature_uri), 'rdf:type', 'obo:'.clean_for_uri($so_term)) if $so_term;
    ${$record} .= sprintf "%s\n", triple(u($feature_uri), 'rdf:type', 'term:'.clean_for_uri($biotype));
  }
  
  my ($feature_id, $feature_name, $feature_description) = $translator->batch_fields($object, [qw/id name description/]);
  ${$record} .= sprintf "%s\n", triple(u($feature_uri), 'rdfs:label', '"'.$feature_name.'"') if $feature_name;
  ${$record} .= sprintf "%s\n", triple(u($feature_uri), 'dc:description', '"'.escape($feature_description).'"') if $feature_description;
  ${$record} .= sprintf "%s\n%s\n",
    taxon_triple(u($feature_uri), $translator->taxon_id),
    triple(u($feature_uri), 'dc:identifier', '"'.$feature_id.'"' );

  # Identifiers.org mappings
  my $id_org_abbrev = $translator->id_org_short('ensembl');
  if ($id_org_abbrev) {
    my $id_org_uri = prefix('identifiers').$id_org_abbrev.'/'.uri_escape($feature_id);
    ${$record} .= sprintf "%s\n%s\n%s\n",
      triple(u($feature_uri), 'rdfs:seeAlso', u( $id_org_uri )),
      triple(u($id_org_uri), 'rdf:type', 'identifiers:'.$id_org_abbrev),
      triple(u($id_org_uri),'sio:SIO_000671',"[a ident_type:$id_org_abbrev; sio:SIO_000300 \"$feature_id\"]");
  }
  
  # describe location in Faldo
  $self->_add_faldo_location($object, $translator, $record) unless $feature_type eq 'translation';

  # print out synonyms
  for my $synonym (@{$translator->synonyms($object)}) {
    ${$record} .= sprintf "%s\n", triple(u($feature_uri),'skos:altlabel', '"'.escape($synonym).'"' );
  }
  
  if ($feature_type eq 'gene') {
    # connect gene to transcripts
    foreach my $transcript (@{$translator->transcripts($object)}) {
      my $transcript_uri = $translator->uri($transcript);
      $self->_bulk_fetcher_feature_record($transcript, $translator, $record);
      ${$record} .= sprintf "%s\n", triple(u($transcript_uri),'obo:SO_transcribed_from', u($feature_uri));
    }
    
    # Homologues come in three types
    # Orthologues - shared ancestor, same gene different species
    # Paralogues - same species, unexpected copy not repeatmasked by the assembly
    # Homeologues - same species, different sub-genome in a polyploid species.
    foreach my $alt_gene (@{$translator->homologues($object)}) {
      my $predicate = ($alt_gene->{description} eq 'within_species_paralog') ? 'sio:SIO_000630': 'sio:SIO_000558';
      ${$record} .= sprintf "%s\n", triple(u($feature_uri), $predicate, 'ensembl:'.uri_escape($alt_gene->{stable_id}));
    }
  }

  if ($feature_type eq 'transcript') {
    # connect transcript to exons
    foreach my $exon (@{$translator->exons($object)}) {
      # exon type of SO exon, both gene and transcript are linked via has part
      my $exon_uri = $translator->uri($exon);
      
      ${$record} .= sprintf "%s\n%s\n%s\n",
	triple(u($exon_uri),'rdf:type','obo:SO_0000147'),
	triple(u($exon_uri), 'rdfs:label', '"'.$translator->id($exon).'"'),
	triple(u($feature_uri), 'obo:SO_has_part', u($exon_uri));
      
      $self->_bulk_fetcher_feature_record($exon, $translator, $record);
      
      my $rank = $translator->rank($exon);
      ${$record} .= sprintf "%s\n%s\n%s\n%s\n",
	triple(u($feature_uri), 'sio:SIO_000974',  u($feature_uri.'#Exon_'.$rank)),
	triple(u($feature_uri.'#Exon_'.$rank),  'rdf:type', 'sio:SIO_001261'),
	triple(u($feature_uri.'#Exon_'.$rank), 'sio:SIO_000628', u($exon_uri)),
	triple(u($feature_uri.'#Exon_'.$rank), 'sio:SIO_000300', $rank);
    }
    # # connect transcript to CDS
    # foreach my $cds (@{$translator->cds($object)}) {
    #  
    #  ${$record} .= sprintf "%s\n", $self->_seq_region_record($cds, $translator)
    # }

    # connect transcript to translations
    foreach my $translation (@{$translator->translations($object)}) {
      $self->_bulk_fetcher_feature_record($translation, $translator, $record);
	
      my $translation_uri = $translator->uri($translation);
      ${$record} .= sprintf "%s\n%s\n",
	triple(u($feature_uri),'obo:SO_translates_to',u($translation_uri)),
	triple(u($translation_uri), 'rdf:type', 'term:protein');
	
      foreach my $protein_feature (@{$translator->protein_features($translation)}) {
	my $pf_name = $translator->name($protein_feature);
	my $pf_dbname = $translator->dbname($protein_feature);
	next unless defined $pf_name && defined $pf_dbname;
	$pf_dbname = lc($pf_dbname);

	${$record} .= sprintf "%s\n", triple(u($translation_uri), 'rdfs:seeAlso', $pf_dbname.':'.$pf_name)
	  if defined prefix($pf_dbname);
      }
    }
    
  }
  
}

sub _add_faldo_location {
  my ($self, $object, $translator, $record) = @_;
  
  my ($feature_uri, $region_name, $cs_name, $cs_version, $start, $end, $strand) =
    $translator->batch_fields($object, [qw/uri seq_region_name cs_name cs_version start end strand/]);
  my ($schema_version, $production_name) = ($translator->version, $translator->production_name);

  my $prefix = prefix('ensembl');
  unless (defined $schema_version && defined $region_name && defined $cs_name) {
    croak ('Cannot print location triple without seq_region_name, coord_system name, and a release');
  }
  # LRGs have their own special seq regions... they may not make a lot of sense
  # in the RDF context.
  # The same is true of toplevel contigs in other species.
  my ($version_uri, $unversioned_uri) = seq_region_uri($translator->version, $translator->production_name, $cs_version, $region_name);
  
  my $begin = ($strand >= 0) ? $start : $end;
  my $stop = ($strand >= 0) ? $end : $start;
  my ($location) = seq_region_uri($schema_version, $production_name, $cs_version, $region_name, $start, $end, $strand);
  my ($beginUri) = seq_region_uri($schema_version, $production_name, $cs_version, $region_name, $begin, undef, $strand);
  my ($endUri) = seq_region_uri($schema_version, $production_name, $cs_version, $region_name, undef, $stop, $strand);
  
  ${$record} .= sprintf "%s\n%s\n%s\n%s\n%s\n%s\n",
    triple(u($feature_uri), 'faldo:location', $location),
    triple($location, 'rdfs:label', qq("$cs_name $region_name:$start-$end:$strand")),
    triple($location, 'rdf:type', 'faldo:Region'),
    triple($location, 'faldo:begin', $beginUri),
    triple($location, 'faldo:end', $endUri),
    triple($location, 'faldo:reference', $version_uri);
  
  ${$record} .= sprintf "%s\n%s\n%s\n%s\n",
    triple($beginUri, 'rdf:type', 'faldo:ExactPosition'),
    triple($beginUri, 'rdf:type', ($strand >= 0)? 'faldo:ForwardStrandPosition':'faldo:ReverseStrandPosition'),
    triple($beginUri, 'faldo:position', $begin),
    triple($beginUri, 'faldo:reference', $version_uri);

  ${$record} .= sprintf "%s\n%s\n%s\n%s\n",
    triple($endUri, 'rdf:type', 'faldo:ExactPosition'),
    triple($endUri, 'rdf:type', ($strand >= 0)? 'faldo:ForwardStrandPosition':'faldo:ReverseStrandPosition'),
    triple($endUri, 'faldo:position', $stop),
    triple($endUri, 'faldo:reference', $version_uri);
  
}

1;
