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

=head2 read_block

    Description : Reads a line of text, stores it into next_block, 
                  moving next_block to current_block.
    Returntype   : True/False on existence of a defined current_block after running.

=cut

sub next_block {
    my $self = shift;
    my $fh = $self->{'filehandle'};

    if (eof($fh)) {
        $self->{'waiting_block'} = undef;
        return 0;
    }
    $self->{'current_block'} = $self->{'waiting_block'};
    while() {
        if (eof($fh)) {
            $self->{'waiting_block'} = undef;
            return 0;
        }
        elsif (my $line = <$fh>) {
            if ($line =~ /^\S/) {
                $self->{'waiting_block'} = $line;   
                return 1;
            }
            else {
                $self->{'current_block'} .= $line;   
            }
        }
    }
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
    if ($self->{'current_block'} =~ /^LOCUS\s+(\S+)\s+(\d+)\s+bp\s+(\w+)\s+(\w+)\s+(\w+)\s+(\S+)/i) {
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
    elsif ($self->{'current_block'} =~ s/^DEFINITION\s*//) {
        $self->{'record'}->{'_definition'} = $self->{'current_block'};
        $self->{'record'}->{'_definition'} =~ s/\s*\n\s*/ /g;
    }
    elsif ($self->{'current_block'} =~ /^ACCESSION\s+(\S+)/i) {
       $self->{'record'}->{'_accession'} = $1;
    }
    elsif ($self->{'current_block'} =~ /^VERSION\s+\S+\.(\d+)\s+GI:(\d+)/i) {
        $self->{'record'}->{'_version'} = $1;
        $self->{'record'}->{'_secondary_id'} = $2;
    }
    elsif ($self->{'current_block'} =~ /^DBLINK\s+(\S+.*\S)\s*$/i) {
        $self->{'record'}->{_dblink} = $1;
    }
    elsif ($self->{'current_block'} =~ /^DBSOURCE\s+(\S+.*\S)\s*$/i) {
        $self->{'record'}->{_dbsource} = $1;
    }
    elsif ($self->{'current_block'} =~ /^KEYWORDS/) {
        $self->{'record'}->{_raw_keywords} = $self->{'current_block'};
    }
    elsif ($self->{'current_block'} =~ /^SOURCE/) {
        $self->{'record'}->{_raw_source} = $self->{'current_block'};
    }
    elsif ($self->{'current_block'} =~ /^COMMENT/) {
        $self->{'record'}->{_raw_comments} = $self->{'current_block'};
    }
    elsif ($self->{'current_block'} =~ /^REFERENCE/) {
        push(@{$self->{'record'}->{_raw_references}}, $self->{'current_block'});
    }
    elsif ($self->{'current_block'} =~ /^FEATURES/) {
        $self->{'record'}->{_raw_features} = $self->{'current_block'};
    }
    elsif ($self->{'current_block'} =~ /^ORIGIN/) {
        $self->{'current_block'} =~ s/[\d\s]+//g;
        $self->{'record'}->{'_seq'} = $self->{'current_block'};
        $self->{'record'}->{'_seq'} =~ s/ORIGIN\s*//;
    }
    else {
        push(@{$self->{'record'}->{'_unknown'}}, $self->{'current_block'});
    }
    $self->next_block;
    }
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

=head2 getGi

    Description: Return the GenBank Id of the sequence
    Returntype : String

=cut

sub getGi {
    my $self = shift;

    return $self->{'record'}->{'_secondary_id'};
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

sub getOrganism {
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

1;
