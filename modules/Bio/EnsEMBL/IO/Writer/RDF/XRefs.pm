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

Bio::EnsEMBL::IO::Writer::RDF::XRefs - 

=head1 SYNOPSIS


=head1 Description


=cut

package Bio::EnsEMBL::IO::Writer::RDF::XRefs;

use parent qw/Bio::EnsEMBL::IO::Writer/;

use strict;
use warnings;
use Carp;

use URI::Escape;
use Bio::EnsEMBL::Utils::RDF qw/u escape prefix triple taxon_triple clean_for_uri feature_uri/;

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

  if (ref($object) =~ /HASH/) {
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

  # if object has not type, assume BulkFetcher derived 'feature'
  if (ref($object) =~ /HASH/) {
    my $record;
    $self->_bulk_fetcher_feature_record($object, $translator, \$record);
    return $record;
  }
}

# This method calls recursively down the gene->transcript->translation chain and prints them all
# It can also be used safely with other kinds of features, at least superficially.
# Any specific vocabulary must be added to describe anything other than the entity and its location

sub _bulk_fetcher_feature_record {
  my ($self, $object, $translator, $record) = @_;
  my $feature_uri = $translator->uri($object);
  my $feature_type = $translator->type($object);

  return if $feature_type eq 'exon';

  my $provenance = $translator->provenance($object);
  my $relation;
  
  foreach my $xref (@{$translator->xrefs($object)}) {
    my $label = $xref->{display_id};
    my $db_name = $xref->{dbname};
    my $id = $xref->{primary_id};
    my $desc = $xref->{description};
    
    # replace generic link with more specific one from Xref record. NONE is boring though.
    $relation = "term:$provenance";
    $relation = 'term:'.$xref->{info_type}
      if exists $xref->{info_type} and defined $xref->{info_type} and $xref->{info_type} ne 'NONE';
    
    # implement the SIO identifier type description see https://github.com/dbcls/bh14/wiki/Identifiers.org-working-document
    my $lod = $translator->lod_uri($db_name); # linked open data uris.    
    # Identifiers.org mappings
    my $id_org_abbrev = $translator->id_org_short($db_name);
    my $id_org_uri;
    if ($id_org_abbrev) {
      $id_org_uri = prefix('identifiers').$id_org_abbrev.'/'.$id;
      ${$record} .= sprintf "%s\n%s\n%s\n",
	triple(u($feature_uri), 'rdfs:seeAlso', u( $id_org_uri )),
	triple(u($id_org_uri), 'rdf:type', 'identifiers:'.$id_org_abbrev),
	triple(u($id_org_uri),'sio:SIO_000671',"[a ident_type:$id_org_abbrev; sio:SIO_000300 \"$id\"]");
      if ($id =~ /^GO/) {
	my $obo_id = $id;
	$obo_id =~ tr/:/_/;
	${$record} .= sprintf "%s\n",
	  triple(u($id_org_uri), 'owl:sameAs', u(prefix('obo').$obo_id));
      }
    }

    # Next make an "ensembl" style xref, either to a known LOD namespace, the identifiers.org URI, or else a generated Ensembl one
    my $xref_uri;
    if ($lod) { 
      $xref_uri = $lod.$id 
    } elsif ($id_org_uri) {
      $xref_uri = $id_org_uri;
    } else {
      # Fall back to a new xref uri without identifiers.org
      $xref_uri = prefix('ensembl').$db_name.'/'.$id;
      # Create Ensembl-centric fallback xref source
      ${$record} .= sprintf "%s\n", triple(u($xref_uri), 'rdf:type', u(prefix('ensembl').$db_name));
    }
    ${$record} .= sprintf "%s\n", triple(u($xref_uri), 'rdf:type', u(prefix('term').'EnsemblDBEntry'));

    ${$record} .= sprintf "%s\n", triple(u($feature_uri), $relation, u($xref_uri));

    ${$record} .= sprintf "%s\n", triple(u($xref_uri),'dc:description','"'.$xref->{info_text}.'"' )
      if exists $xref->{info_text} && defined $xref->{info_text} && $xref->{info_text} ne '';
    ${$record} .= sprintf "%s\n", triple(u($xref_uri), 'dc:identifier', qq("$id"));
    ${$record} .= sprintf "%s\n", triple(u($xref_uri), 'rdfs:label', qq("$label"))
      if defined $label;
    ${$record} .= sprintf "%s\n", triple(u($xref_uri), 'dc:description', '"'.escape($desc).'"')
      if $desc;
  }

  if ($feature_type eq 'gene') {
    # connect gene to transcripts
    foreach my $transcript (@{$translator->transcripts($object)}) {
      $self->_bulk_fetcher_feature_record($transcript, $translator, $record);
    }
  } elsif ($feature_type eq 'transcript') {
    # connect transcript to translations
    foreach my $translation (@{$translator->translations($object)}) {
      $self->_bulk_fetcher_feature_record($translation, $translator, $record);
    }
  }
}

1;
