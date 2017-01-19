=pod

=head1 LICENSE

  Copyright (c) 1999-2014 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

  http://www.ensembl.org/info/about/code_licence.html

=head1 NAME

Bio::EnsEMBL::IO::Parser::Genbank - GenBankParser

=cut

package Bio::EnsEMBL::IO::Parser::Genbank;

use strict;
use warnings;
use Carp;

use base qw/Bio::EnsEMBL::IO::TokenBasedParser/;

=head2 open

    Description: Open the file given in parameters, the file has to be a valid Genbank file
    Returntype : Filehandle to the GenBank file

=cut

sub open {
    my $caller = shift;
    my $class = ref($caller) || $caller;
    my $filename = shift;
    
    my $self = $class->SUPER::open($filename, '^LOCUS', '^//', @_);
    
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
        unless (defined($field_type)) { croak ("Genbank record parsing going badly.\n".$self->{current_block}."\n".$self->{filename}) };
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
            $field .= $self->_get_multiline;
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
        elsif ($field_type eq 'DEFINITION') {
            $field .= $self->_get_multiline;
            $self->{'record'}->{'_raw_definition'} = $field;
        }
        elsif ($field_type eq 'ORIGIN') {
            $field .= $self->_get_multiline;
            $field =~ s/[\d\s]+//g;
            $self->{'record'}->{'_seq'} = $field;
        }
        elsif ($field_type eq 'FEATURES') {
            $self->{record}->{_raw_features} = $self->_get_raw_multiline;
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
    while (defined $self->{'waiting_block'} && $self->{'waiting_block'} !~ /^\S/) {
        $self->next_block;
        $field .= $self->{'current_block'};
        chomp $field;
    }
    # We replace multiple spaces/tabulation to be 1 space
    $field =~ s/\s\s+/ /g;
    return $field;
}

=head2 _get_raw_multiline

    Description: Feature blocks can have significant whitespace and newlines. This method returns the
                 whole multiline section as a it appears in the file
    Returntype : String (with linefeeds)

=cut

sub _get_raw_multiline {
    my $self = shift;
    my $field = '';
    while (defined $self->{'waiting_block'} && $self->{'waiting_block'} !~ /^\S/) {
        $self->next_block;
        $field .= $self->{'current_block'};
    }
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

    Description: Return an array of features as hashes. Feature type is given the 'header' key
                 All keys barring header and the position string are arrayrefs to allow for
                 a multiplicity of keys. Multi-line strings have been concatenated into a single line.
                 The "position" coordinates are with reference to get_sequence()

                 Example keys include: gene, gene_synonym, db_xref, product and many more as per Genbank spec
    Example    : @features = @{ $parser->get_features};
                 foreach my $feat (@features) {
                    if ($feat->{header} eq 'gene') {
                        print $feat->{position}.':'.$feat->{gene}."\n"
                    }
                 }
    Returntype : Array reference

=cut

sub get_features {
    my $self = shift;
    my @features;
    my %feature;
    my $line_buffer;
    if (!exists $self->{record}->{_features}) {
        foreach my $line (split /\n/, $self->{record}->{_raw_features}) {
            if ($line =~ /^\s{5}(\w+)/) {
                push @features,$self->_finish_feature(\%feature, $line_buffer) if %feature;
                undef %feature;
                $line_buffer = '';
                my ($header,$position) = $line =~ /^\s{5}(\w+)\s+(.+)/;
                # Note that position can be complement() and or join(coord1,coord2)
                %feature = ( header => $header, position => $position);
            } else {
                $line =~ s/^\s+//;
                chomp $line;
                $line_buffer .= $line;
            }

        }
        push @features,$self->_finish_feature(\%feature, $line_buffer); # Commit last feature from buffer
        $self->{record}->{_features} = \@features;
    }
    return $self->{record}->{_features};
}

sub _finish_feature {
    my $self = shift;
    my $feature = shift;
    my $line_buffer = shift;

    my @sections = split '/',$line_buffer;
    foreach my $section (@sections) {
        my ($key,$value) = split '=',$section;
        $value =~ s/"//g if $value;
        push @{ $feature->{$key} },$value if ($key && $value);
    }
    my %final_copy = %$feature;
    return \%final_copy;
}

1;
