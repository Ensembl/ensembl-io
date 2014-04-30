=pod

=head1 LICENSE

  Copyright (c) 1999-2014 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

  http://www.ensembl.org/info/about/code_licence.html

=head1 NAME

Bio::EnsEMBL::IO::Parser::GenbankParser - GenBankParser

=cut

package Bio::EnsEMBL::IO::Parser::GenbankParser;

use strict;
use warnings;

use Bio::EnsEMBL::Utils::Exception qw/throw/;
use Bio::EnsEMBL::Utils::Scalar qw/assert_ref/;

use base qw/Bio::EnsEMBL::IO::TokenBasedParser/;

=head2 open

    Description: Open the file given in parameters, the file has to be a valid Genbank file
    Returntype : Filehandle to the GenBank file

=cut

sub open {
    my $caller = shift;
    my $class = ref($caller) || $caller;
    my $filename = shift;
    
    my $self = $class->SUPER::open($filename, 'LOCUS', '//', @_);
    
    $self->next_block();
    return $self;
}

=head2 is_metadata

    Description: Define what a meta data is for the GenBank file
    Returntype : Boolean, 1 if the line contains metadata

=cut

sub is_metadata {
    my $self = shift;
    return $self->{'current_block'} =~ /^#/;
}

=head2 read_record

    Description: Placeholder for user-defined record lexing function.
                 Function must pre-process the data in $self->current block so that it is
                 readily available to accessor methods.
    Returntype : Void 

=cut

sub read_record {
    my $self = shift;
    
    while (!$self->is_at_end_of_record) {
        my ($field_type, $field) = $self->{'current_block'} =~ /^(\w+)\s+(.*)/;
        chomp $field;
        if ($field_type eq 'LOCUS') {
            $field =~ /(\S+)\s+(\d+)\s[bpa]{2}/;
            $self->{'record'}->{'_locus_id'} = $1;
            $self->{'record'}->{'_length'}   = $2;
            my $molecule = substr($field, 31, 12);
            if ($molecule =~ /(\w+)/) {
                $self->{'record'}->{'_molecule'} = $1;
            }
            $self->{'record'}->{'_tax'}               = substr($field, 52, 3);
            $self->{'record'}->{'_modification_date'} = substr($field, 56, 11);
            if (substr($field, 43, 8) eq 'circular') {
                $self->{'record'}->{'_is_circular'} = 1;
            }
            else {
                $self->{'record'}->{'_is_circular'} = 0;
            }
        }
        elsif ($field_type eq 'ACCESSION') {
            $self->{'record'}->{'_raw_accession'} = $field;
        }
        elsif ($field_type eq 'VERSION') {
            if ($field =~ /\S+\.(\d+)\s+GI:(\d+)/) {
                $self->{'record'}->{'_version'} = $1;
                $self->{'record'}->{'_genebank_id'} = $2;
            }
            else {
                $self->{'record'}->{'_version'} = $field;
            }
        }
        elsif ($field_type eq 'COMMENT' || $field_type eq 'REFERENCE') {
            # REFERENCE is not used by the genebuild team so it can be "removed"
            push(@{$self->{'record'}->{'_raw_'.lc($field_type)}},  $field.$self->_get_multiline);
        }
        elsif ($field_type eq 'ORIGIN') {
            $field .= $self->_get_multiline;
            $field =~ s/[\d\s]+//g;
            $self->{'record'}->{'_seq'} = $field;
        }
        elsif (defined $field_type) {
            $self->{'record'}->{'_raw_'.lc($field_type)} = $field.$self->_get_multiline;
        }
        else {
            push(@{$self->{'record'}->{'_unknown'}}, $field);
        }
        $self->next_block;
    }
}

=head2 _get_multiline

    Description: Some field can be on multiple lines, this method makes sure that we have all
                 the field information on one line
    Returntype : String

=cut

sub _get_multiline {
    my $self = shift;
    my $field = '';
#    while (defined $self->{'waiting_block'} && $self->{'waiting_block'} !~ /^\w|^$self->{'end_tag'}/) {
    while (defined $self->{'waiting_block'} && $self->{'waiting_block'} !~ /^\S/) {
        $self->next_block;
        $field .= $self->{'current_block'};
        chomp $field;
    }
    # We replace multiple spaces/tabulation to be 1 space
    $field =~ s/\s\s+/ /g;
    return $field;
}

=head2 read_metadata

    Description: Read the metadata field of the line
                 As far as I know, there is no metadata in the GenBank file so we return nothing
    Returntype : Void

=cut

sub read_metadata {
    my $self = shift;

    # We do nothing
    # print STDERR 'DEBUG: Met metadata!! :', $self->{'current_block'}, ":\n";
}

=head2 get_raw_description

    Description: Return the raw definition field from the GenBank file
    Returntype : String

=cut

sub get_raw_description {
    my $self = shift;

    return $self->{'record'}->{'_raw_definition'};
}

=head2 get_description

    Description: Return the definition field from the GenBank file
    Returntype : String

=cut

sub get_description {
    my $self = shift;

    return $self->get_raw_description;
}

=head2 get_sequence

    Description: Return the sequence from the GenBank file
    Returntype : String

=cut

sub get_sequence {
    my $self = shift;

    return $self->{'record'}->{'_seq'};
}

=head2 get_accession

    Description: Return the accession of the sequence
    Returntype : String

=cut

sub get_accession {
    my $self = shift;

    if (!exists $self->{'record'}->{'_accession'}) {
        ($self->{'record'}->{'_accession'}) = $self->{'record'}->{'_raw_accession'} =~ /^(\w+)/;
    }
    return $self->{'record'}->{'_accession'};
}

=head2 get_sequence_name

    Description: Return the accession withe the sequence version of the sequence
    Returntype : String

=cut

sub get_sequence_name {
    my $self = shift;

    return $self->{'record'}->{'_accession'}.'.'.$self->{'record'}->{'_version'};
}

=head2 get_genbank_id

    Description: Return the GenBank Id of the sequence
    Returntype : String

=cut

sub get_genbank_id {
    my $self = shift;

    return $self->{'record'}->{'_genebank_id'};
}

=head2 get_sequence_version

    Description: Return the sequence version of the sequence
    Returntype : String

=cut

sub get_sequence_version {
    my $self = shift;

    return $self->{'record'}->{'_version'};
}

=head2 get_length

    Description: Return the length of the sequence
    Returntype : String

=cut

sub get_length {
    my $self = shift;

    return $self->{'record'}->{'_length'};
}

=head2 get_locus_id

    Description: Return the locus id of the sequence. It can be the gene name if it exists
    Returntype : String

=cut

sub get_locus_id {
    my $self = shift;

    return $self->{'record'}->{'_locus_id'};
}

=head2 get_sequence_type

    Description: Return the type of the sequence: mRNA, DNA, RNA
    Returntype : String

=cut

sub get_sequence_type {
    my $self = shift;

    return $self->{'record'}->{'_molecule'};
}

=head2 get_modification_date

    Description: Return the last modification date in the GenBank format
    Returntype : String

=cut

sub get_modification_date {
    my $self = shift;

    return $self->{'record'}->{'_modification_date'};
}

=head2 is_circular

    Description: Return true if the sequence is circular
    Returntype : Boolean

=cut

sub is_circular {
    my $self = shift;

    return $self->{'record'}->{'_is_circular'};
}

=head2 get_raw_organism

    Description: Return the organism name 
    Returntype : String

=cut

sub get_raw_organism {
    my $self = shift;

    return $self->{'record'}->{'_raw_source'};
}

=head2 get_source

    Description: Return the organism name in the ORGANISM field
    Returntype : String

=cut

sub get_source {
    my $self = shift;

    $self->{'record'}->{'_raw_source'} =~ /^(.+)\s+ORGANISM/;
    # A bit ugly I agree
    return $1;
}

=head2 get_organism

    Description: Return the organism name 
    Returntype : String

=cut

sub get_organism {
    my $self = shift;

    if (!exists $self->{'record'}->{'_organism'}) {
        # Instead of trying an impossible regex, I first get the line until ';', then I remove the last word
        # as it will be the root of the taxonomy
        ($self->{'record'}->{'_organism'}) = $self->{'record'}->{'_raw_source'} =~ /ORGANISM\s*([^;]+)/;
        $self->{'record'}->{'_organism'} =~ s/\s+\w+$//;
    }
    return $self->{'record'}->{'_organism'};
}

=head2 get_taxon_id

    Description: Return the NCBI taxonomy id of the organism
    Returntype : Integer

=cut

sub get_taxon_id {
    my $self = shift;

    if (!exists $self->{'record'}->{'_taxon_id'}) {
        ($self->{'record'}->{'_taxon_id'}) = $self->{'record'}->{'_raw_features'} =~ /db_xref="taxon:(\d+)/;
    }
    return $self->{'record'}->{'_taxon_id'};
}

=head2 get_raw_dblinks

    Description: Return the DBLINK fields from the GenBank file
    Returntype : String

=cut

sub get_raw_dblinks {
    my $self = shift;
    if (!exists $self->{'record'}->{'_raw_dblink'}) {
        return
    }
    return $self->{'record'}->{'_raw_dblink'};
}

=head2 get_raw_comment

    Description: Return the COMMENT fields from the GenBank file
    Returntype : String

=cut

sub get_raw_comment
{
    my $self = shift;
    if (! exists $self->{'record'}->{'_raw_comment'}) {
        return;
    }
    return $self->{'record'}->{'_raw_comment'};
}

=head2 get_features

    Description: Return an array of hashes representing the features of the GenBank file
                 Each subfeature has its own key except db_xref which is an array
                 the key __fragment is coded:
                  0 not a fragment
                  1 incomplete on 5' end
                  2 incomplete on 3' end
                  3 incomplete on both end
    Returntype : Array reference

=cut

sub get_features {
    my $self = shift;

    if (!exists $self->{'record'}->{'_features'}) {
        my $tmp = substr($self->{'record'}->{'_raw_features'}, 20);
        $tmp =~ s/"\s+(\w)/"\/$1/g;
        my $index = -1;
        my @features = split(' /', $tmp);
        for (my $i = 0; $i < @features; $i++) {
            if ($features[$i] =~ /^\s*([^= ]+)\s+(\S.*)\s*/) {
                $index++; 
                push(@{$self->{'record'}->{'_features'}}, { '__name' => $1}); 
                $self->_calculate_coordinates($index, $2);
            }
            else {
                my ($key, $value) = $features[$i] =~ /(\w+)="*([^"]+)"*/;
                    if ($key eq 'db_xref') {
                        $value =~ /(\w+):(.*)/;
                        push(@{$self->{'record'}->{'_features'}->[$index]->{'__db_xref'}}, {$1 => $2});
                    }
                    else {
                        $value =~ s/\s\s+//g;
                        $self->{'record'}->{'_features'}->[$index]->{'__'.$key} = $value;
                    }
            }
        }
    }
    return $self->{'record'}->{'_features'};
}

=head2 _calculate_coordinates

    Description: Transform the GenBank coordinates into readable coordinate
    Returntype : Void

=cut

sub _calculate_coordinates {
    my ($self, $index, $positions) = @_;

    $self->{'record'}->{'_features'}->[$index]->{'__fragment'} = 0;
    # Simple forward coordinates:
    # gene            577..647
    # < and > indicates that the feature is incomplete on the 5' or/and 3' end respetively
    if ($positions =~ /^<?(\d+)\.\.>?(\d+)/) {
        $self->{'record'}->{'_features'}->[$index]->{'__start'} = $1;
        $self->{'record'}->{'_features'}->[$index]->{'__end'} = $2;
        $self->{'record'}->{'_features'}->[$index]->{'__strand'} = 1;
        $self->{'record'}->{'_features'}->[$index]->{'__fragment'} += 1 if ($positions =~ /</);
        $self->{'record'}->{'_features'}->[$index]->{'__fragment'} += 2 if ($positions =~ />/);
    }
    # Simple reverse coordinates
    # gene            complement(4329..4400)
    elsif ($positions =~ /^complement\(<?(\d+)\.\.>?(\d+)/) {
        $self->{'record'}->{'_features'}->[$index]->{'__start'} = $1;
        $self->{'record'}->{'_features'}->[$index]->{'__end'} = $2;
        $self->{'record'}->{'_features'}->[$index]->{'__strand'} = -1;
        $self->{'record'}->{'_features'}->[$index]->{'__fragment'} += 1 if ($positions =~ /</);
        $self->{'record'}->{'_features'}->[$index]->{'__fragment'} += 2 if ($positions =~ />/);
    }
    else {
        $self->{'record'}->{'_features'}->[$index]->{'__positions'} = $positions;
    }
}

1;
