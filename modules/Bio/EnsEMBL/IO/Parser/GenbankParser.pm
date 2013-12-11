=pod

=head1 LICENSE

  Copyright (c) 1999-2013 The European Bioinformatics Institute and
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

sub open {
    my $caller = shift;
    my $class = ref($caller) || $caller;
    my $filename = shift;
    
    my $self = $class->SUPER::open($filename, 'LOCUS', '//', @_);
    
    $self->next_block();
    return $self;
}

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
        if ($field_type =~ /^LOCUS/) {
            $field =~ /(\S+)\s+(\d+)\s+bp\s+(\w+)\s+(\w+)\s+(\w+)\s+(\S+)/;
            $self->{'record'}->{'_locus_id'}          = $1;
            $self->{'record'}->{'_length'}            = $2;
            $self->{'record'}->{'_molecule'}          = $3;
            $self->{'record'}->{'_tax'}               = $5;
            $self->{'record'}->{'_modification_date'} = $6;
            if ($4 eq 'circular') {
                $self->{'record'}->{'_is_circular'} = 1;
            }
            else {
                $self->{'record'}->{'_is_circular'} = 0;
            }
        }
        elsif ($field_type eq 'DEFINITION') {
            $self->{'record'}->{'_definition'} = $field.$self->_get_multiline;
        }
        elsif ($field_type eq 'ACCESSION') {
            $field =~ s/\s*$//;
            $self->{'record'}->{'_accession'} = $field;
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
        elsif ($field_type eq 'DBLINK') {
            $self->{'record'}->{_dblink} = $field.$self->_get_multiline;
        }
        elsif ($field_type eq 'DBSOURCE') {
            $self->{'record'}->{_dbsource} = $field.$self->_get_multiline;
        }
        elsif ($field_type eq 'KEYWORDS') {
            $self->{'record'}->{_raw_keywords} = $field.$self->_get_multiline;
        }
        elsif ($field_type eq 'SOURCE') {
            $self->{'record'}->{_raw_source} = $field.$self->_get_multiline;
        }
        elsif ($field_type eq 'COMMENT') {
            push(@{$self->{'record'}->{_raw_comments}},  $field.$self->_get_multiline);
        }
        elsif ($field_type eq 'REFERENCE') {
            push(@{$self->{'record'}->{_raw_references}}, $field.$self->_get_multiline);
        }
        elsif ($field_type eq 'FEATURES') {
            $self->{'record'}->{_raw_features} = $field.$self->_get_multiline;
        }
        elsif ($field_type eq 'ORIGIN') {
            $field .= $self->_get_multiline;
            $field =~ s/[\d\s]+//g;
            $self->{'record'}->{'_seq'} = $field;
        }
        else {
            print STDERR 'UNKNOWN: ', $self->{'current_block'}, "\n";
            push(@{$self->{'record'}->{'_unknown'}}, $field);
        }
        $self->next_block;
    }
}

sub _get_multiline {
    my $self = shift;
    my $field = '';
    while (defined $self->{'waiting_block'} and $self->{'waiting_block'} !~ /^\w|^$self->{'end_tag'}/) {
        $self->next_block;
        $field .= $self->{'current_block'};
        $field =~ s/\s\s+/ /g;
        chomp $field;
    }
    return $field;
}

sub read_metadata {
    my $self = shift;

#    print STDERR 'DEBUG: Met metadata!! :', $self->{'current_block'}, ":\n";
}
=head2 getDescription

    Description: Return the definition field from the GenBank file
    Returntype : String

=cut

sub getDescription {
    my $self = shift;

    return $self->{'record'}->{'_definition'};
}

=head2 getSequence

    Description: Return the sequence from the GenBank file
    Returntype : String

=cut

sub getSequence {
    my $self = shift;

    return $self->{'record'}->{'_seq'};
}

=head2 getSeqName

    Description: Return the accession withe the sequence version of the sequence
    Returntype : String

=cut

sub getSeqName {
    my $self = shift;

    return $self->{'record'}->{'_accession'}.'.'.$self->{'record'}->{'_version'};
}

=head2 getGenbankId

    Description: Return the GenBank Id of the sequence
    Returntype : String

=cut

sub getGenbankId {
    my $self = shift;

    return $self->{'record'}->{'_genebank_id'};
}

=head2 getVersion

    Description: Return the sequence version of the sequence
    Returntype : String

=cut

sub getSeqVersion {
    my $self = shift;

    return $self->{'record'}->{'_version'};
}

=head2 getLength

    Description: Return the length of the sequence
    Returntype : String

=cut

sub getLength {
    my $self = shift;

    return $self->{'record'}->{'_length'};
}

=head2 getLocusId

    Description: Return the locus id of the sequence. It can be the gene name if it exists
    Returntype : String

=cut

sub getLocusId {
    my $self = shift;

    return $self->{'record'}->{'_locus_id'};
}

=head2 getType

    Description: Return the type of the sequence: mRNA, DNA, RNA
    Returntype : String

=cut

sub getType {
    my $self = shift;

    return $self->{'record'}->{'_molecule'};
}

=head2 getModificationDate

    Description: Return the last modification date in the GenBank format
    Returntype : String

=cut

sub getModificationDate {
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

=head2 getRawOrganism

    Description: Return the organism name 
    Returntype : String

=cut

sub getRawOrganism {
    my $self = shift;

    if (!exists $self->{'record'}->{'_organism'}) {
        ($self->{'record'}->{'_organism'}) = $self->{'record'}->{'_raw_source'} =~ /ORGANISM\s*(\S+.+)\s*$/m;
    }
    return $self->{'record'}->{'_organism'};
}

=head2 getOrganism

    Description: Return the organism name 
    Returntype : String

=cut

sub getOrganism {
    my $self = shift;

    if (!exists $self->{'record'}->{'_organism'}) {
        ($self->{'record'}->{'_organism'}) = $self->{'record'}->{'_raw_source'} =~ /ORGANISM\s*(\S+.+)\s*$/m;
    }
    return $self->{'record'}->{'_organism'};
}

=head2 getTaxonId

    Description: Return the NCBI taxonomy id of the organism
    Returntype : Integer

=cut

sub getTaxonId {
    my $self = shift;

    if (!exists $self->{'record'}->{'_taxon_id'}) {
        ($self->{'record'}->{'_taxon_id'}) = $self->{'record'}->{'_raw_features'} =~ /db_xref="taxon:(\d+)/;
    }
    return $self->{'record'}->{'_taxon_id'};
}

=head2 getFeatures

    Description: Return an array of hashes representing the features of the GenBank file
                 Each subfeature has its own key except db_xref which is an array
                 the key __fragment is coded:
                  0 not a fragment
                  1 incomplete on 5' end
                  2 incomplete on 3' end
                  3 incomplete on both end
    Returntype : Array reference

=cut

sub getFeatures {
    my $self = shift;

    if (!exists $self->{'record'}->{'_features'}) {
        my $tmp = join('',split("\n", $self->{'record'}->{'_raw_features'}));
        $tmp =~ s/FEATURES\s+\S+\s*//;
        $tmp =~ s/"\s+(\w)/"\/$1/g;
        my $index = -1;
        my @features = split('/', $tmp);
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
    if ($positions =~ /^<?(\d+)\.\.>?(\d+)/) {
        $self->{'record'}->{'_features'}->[$index]->{'__start'} = $1;
        $self->{'record'}->{'_features'}->[$index]->{'__end'} = $2;
        $self->{'record'}->{'_features'}->[$index]->{'__strand'} = 1;
        $self->{'record'}->{'_features'}->[$index]->{'__fragment'} += 1 if ($positions =~ /</);
        $self->{'record'}->{'_features'}->[$index]->{'__fragment'} += 2 if ($positions =~ />/);
    }
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

sub next {
    my $self = shift;

    $self->{'record'} = undef;
    $self->next_block();

    if (defined $self->{'current_block'} and $self->is_at_beginning_of_record) {
            $self->read_record();
            return 1;
    } else {
            return 0;
    }
}

=head2 is_at_beginning_of_record

    Description : Determines whether the current line is the first line of a record
    Returntype  : Boolean

=cut

sub is_at_beginning_of_record {
    my $self = shift;
    return !defined $self->{'start_tag'} || $self->{'current_block'} =~ /$self->{'start_tag'}/;
}

1;
