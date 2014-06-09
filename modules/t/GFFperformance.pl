use strict;
use warnings;

use Bio::EnsEMBL::Utils::IO qw( work_with_file );
use Bio::EnsEMBL::IO::Parser::GFF3;
use Bio::EnsEMBL::Variation::Variation;
use Bio::EnsEMBL::Variation::VariationFeature;

use Benchmark qw(cmpthese timethese);

my $count = shift;
$count ||= -15;

my $test_file = "Saccharomyces_cerevisiae.gvf";

my $r = timethese(
    $count,
    {
        'dud' => \&naked_file_read,
        'gff' => \&gff,
        'gff+' => \&gff_with_happy_stuff,
        'gff_to_objects' => \&gff_to_objects,
        'gff_to_fast_objects' => \&gff_to_fast_objects,
        'regex' => \&regex,
    }
);

cmpthese($r);

#gff();

sub gff {
    work_with_file( $test_file, "r", sub {
        my $fh = shift;
        my $parser = Bio::EnsEMBL::IO::Parser::GFF3->new($fh);
        while($parser->read_record) {next;};    
        return;
    } );
}

sub naked_file_read {
    work_with_file( $test_file, "r", sub {
        my $fh = shift;
        while (my $line = <$fh>) {
            my @columns = split(/\t|\s\s+/,$line,9);
        }
        return;
    } );
}

sub regex {
    work_with_file( $test_file, "r", sub {
        my $fh = shift;
        while (my $line = <$fh>) {
            my @columns = $line =~ /[\w.\+=;]+/g;
        }
        return;
    } );
}

sub gff_with_happy_stuff {
    my $happy_stuff = sub {
        my $line = shift;
        my @columns = split('\t|\s\s+',$line,9);
        return 1;
    };
    work_with_file( $test_file, "r", sub {
        my $fh = shift;
        my $parser = Bio::EnsEMBL::IO::Parser::GFF3->new($fh);
        $parser->set_data_function($happy_stuff);
        while($parser->read_record) {next;};
        return;
    });
}

my %stranding = (
    '+' => 1,
    '-' => -1,
    '.' => 0,
);
# make very sparse variation objects from a yeast GVF file
sub gff_to_objects {
    my $function = sub {
        my $line = shift;
        my ($chromosome,$source,$type,$start,$end,$score,$strand,$phase,$stuff) = split('\t|\s\s+',$line);
        
        $strand = $stranding{$strand};
        
        my $slice;
        my @attribs = split(';',$stuff);
        my ($id,$variant_seq,$ref_seq,$xref);
        
        foreach (@attribs) {
            if (/ID=(.+)/) {$id = $1}
            elsif (/Variant_seq=(.+)/i) {$variant_seq = $1}
            elsif (/Reference_seq=(.+)/i) {$ref_seq = $1}
            elsif (/Dbxref=(.+)/i) {$xref = $1}
            
        }
        my ($name) = $xref =~ /s\d+\-\d+/;
        
        my $variation = Bio::EnsEMBL::Variation::Variation->new(
            -NAME          => $name,
            -SOURCE_ID     => $source,
        );
        
        my $variation_feature = Bio::EnsEMBL::Variation::VariationFeature->new(
            -START         => $start,
            -END           => $end,
            -STRAND        => $strand,
            -SLICE         => undef,
            -ALLELE_STRING => $ref_seq."/".$variant_seq,
            -VARIATION_NAME=> "",
            -MAP_WEIGHT    => 1,
            -VARIATION     => $variation,
        );
        return $variation_feature;
    };
    
    work_with_file( $test_file, "r", sub {
        my $fh = shift;
        my $parser = Bio::EnsEMBL::IO::Parser::GFF3->new($fh);
        $parser->set_data_function($function);
        while($parser->read_record) {next;};
        return;
    });
}
# This is probably producing wrong objects, but it serves its speed-testing purpose.
sub gff_to_fast_objects {
    my $function = sub {
        my $line = shift;
        my ($chromosome,$source,$type,$start,$end,$score,$strand,$phase,$stuff) = split('\t|\s\s+',$line);
        
        $strand = $stranding{$strand};
        
        my $slice;
        my @attribs = split(';',$stuff);
        my ($id,$variant_seq,$ref_seq,$xref);
        
        foreach (@attribs) {
            if (/ID=(.+)/) {$id = $1}
            elsif (/Variant_seq=(.+)/i) {$variant_seq = $1}
            elsif (/Reference_seq=(.+)/i) {$ref_seq = $1}
            elsif (/Dbxref=(.+)/i) {$xref = $1}
            
        }
        my ($name) = $xref =~ /s\d+\-\d+/;
        
        my $variation = Bio::EnsEMBL::Variation::Variation->new_fast(
            {
                name => $name,
                source_id => $source,
            });
        my %feature = (
            start         => $start,
            end           => $end,
            strand        => $strand,
            slice         => undef,
            allele_string => $ref_seq."/".$variant_seq,
            _variation_id => "",
            map_weight    => 1,
            variation     => $variation,
        );
        my $variation_feature = Bio::EnsEMBL::Variation::VariationFeature->new_fast(\%feature);
            
        return $variation_feature;
    };
    
    work_with_file( $test_file, "r", sub {
        my $fh = shift;
        my $parser = Bio::EnsEMBL::IO::Parser::GFF3->new($fh);
        $parser->set_data_function($function);
        while($parser->read_record) {next;};
        return;
    });
}
