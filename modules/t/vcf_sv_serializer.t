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

=cut

use strict;
use warnings;

use Test::More;
use Test::Differences;

use Bio::EnsEMBL::CoordSystem;
use Bio::EnsEMBL::Slice;
use Bio::EnsEMBL::Variation::StructuralVariation;
use Bio::EnsEMBL::Variation::StructuralVariationFeature;
use IO::String;

use Bio::EnsEMBL::IO::Translator::StructuralVariationFeature;
use Bio::EnsEMBL::IO::Writer::VCF4;
use Bio::EnsEMBL::IO::Object::VCF4Metadata;

## Create some sample objects (we don't want unit tests to depend on a db connection
my $chr = 1;
## Create some sample objects (we don't want unit tests to depend on a db connection
my $cs = Bio::EnsEMBL::CoordSystem->new(-NAME    => 'chromosome',
                                        -VERSION => 'GRCh38',
                                        -RANK    => 1,
                                        ); 
my $slice = Bio::EnsEMBL::Slice->new( -coord_system     => $cs,
                                      -seq_region_name  => $chr,
                                      -start            => 1,
                                      -end              => 248956422,
                                      -strand           => 1,
                                      );
    
my %sv_data = ( 
  'nsv7879'      => { 'outer_start' => undef,
                      'start'       => 10001, 
                      'inner_start' => undef,
                      'inner_end'   => undef,
                      'end'         => 127330,
                      'outer_end'   => undef,
                      'length'      => 117330,
                      'so_term'     => 'copy_number_variation'
                    },  
  'nssv1529569'  => { 'outer_start' => undef,
                      'start'       => 10001, 
                      'inner_start' => undef,
                      'inner_end'   => undef,
                      'end'         => 297968,
                      'outer_end'   => undef,
                      'length'      => 287968,
                      'so_term'     => 'copy_number_gain'
                    },
  'nssv1614481'  => { 'outer_start' => undef,
                      'start'       => 10001, 
                      'inner_start' => undef,
                      'inner_end'   => undef, 
                      'end'         => 1535693,
                      'outer_end'   => undef,
                      'length'      => 1525693,
                      'so_term'     => 'deletion'
                    },
  'esv3364878'   => { 'outer_start' => 10052,
                      'start'       => 10052, 
                      'inner_start' => 10615,
                      'inner_end'   => 35287,
                      'end'         => 37287,
                      'outer_end'   => 37287,
                      'length'      => 27236,
                      'so_term'     => 'copy_number_variation'
                    },
  'nssv4000242'  => { 'outer_start' => undef,
                      'start'       => 11099,
                      'inner_start' => undef,
                      'inner_end'   => undef, 
                      'end'         => 47000,
                      'outer_end'   => undef,
                      'length'      => 35902,
                      'so_term'     => 'duplication'
                    },
  'esv2867013'   => { 'outer_start' => undef,
                      'start'       => 62297, 
                      'inner_start' => undef,
                      'inner_end'   => undef,  
                      'end'         => 62297,
                      'outer_end'   => undef,
                      'length'      => undef,
                      'so_term'     => 'insertion'
                    },
              );

#my %sample_data = ( 'NA18594' => { 'genotype' => {'rs699' => '1/1'}, 'phased' => 0},
#                    'NA18573' => { 'genotype' => {'rs699' => '1/1'}, 'phased' => 0},
#                    'NA12875' => { 'genotype' => {'rs699' => '1/1'}, 'phased' => 0},
#                    'NA12874' => { 'genotype' => {'rs699' => '1/1'}, 'phased' => 0},
#                    'HG00096' => { 'genotype' => {'rs699' => '1/1'}, 'phased' => 0},
#                  );


my @svs = map { $_ } sort { $sv_data{$a}{'start'} <=> $sv_data{$b}{'start'} || $sv_data{$a}{'end'} <=> $sv_data{$b}{'end'}} keys(%sv_data);
my @samples_list; #my @samples_list = sort(keys(%sample_data));

my @info = ('SVTYPE','END','SVLEN','CIPOS','CIEND','IMPRECISE');

my @alt  = ('CNV','CNV:GAIN','CNV:LOSS',
            'DEL',
            'DUP','DUP:TANDEM',
            'INS','INS:ME','INS:ME:ALU',
            'INV',
            'SA','CSA','CS','INDEL',
            'TL','TL:Inter','TL:Intra',
            'BP:InterC','BP:IntraC'
           );
my @formats = (); #('GT');


my @features = ();
foreach my $sv (@svs) {

  my $sv_d = $sv_data{$sv};

  my $sv_obj = Bio::EnsEMBL::Variation::StructuralVariation->new(
     -VARIATION_NAME => $sv,
     -IS_EVIDENCE    => 0
  );
  
  #my %sample_genotypes = ();
  #foreach my $sample (@samples_list) {
  #  if ($sample_data{$sample}{'genotype'} && $sample_data{$sample}{'genotype'}{$var}) {
  #    $sample_genotypes{$sample}{'genotype'} = $sample_data{$sample}{'genotype'}{$var};
  #    $sample_genotypes{$sample}{'phased'} = $sample_data{$sample}{'phased'};
  #  }
  #}
  #$var_obj->{'sample_genotypes'} = \%sample_genotypes if (scalar(keys(%sample_genotypes)) > 0);
  
  push @features, Bio::EnsEMBL::Variation::StructuralVariationFeature->new(
    -OUTER_START => $sv_d->{'outer_start'},
    -START       => $sv_d->{'start'},
    -INNER_START => $sv_d->{'inner_start'},
    -INNER_END   => $sv_d->{'inner_end'},
    -END         => $sv_d->{'end'},
    -OUTER_END   => $sv_d->{'outer_end'},
    -STRAND      => 1,
    -SLICE       => $slice,
    -LENGTH      => $sv_d->{'length'},
    -STRUCTURAL_VARIATION => $sv_obj,
    -VARIATION_NAME => $sv,
    -CLASS_SO_TERM  => $sv_d->{'so_term'},
  );
  
}

my $vcf_string = <<VCF;
##fileformat=VCFv4.2
##INFO=<ID=SVTYPE,Number=1,Type=String,Description="Type of structural variant">
##INFO=<ID=END,Number=1,Type=Integer,Description="End position of the variant described in this record">
##INFO=<ID=SVLEN,Number=.,Type=Integer,Description="Difference in length between REF and ALT alleles">
##INFO=<ID=CIPOS,Number=2,Type=Integer,Description="Confidence interval around POS for imprecise variants">
##INFO=<ID=CIEND,Number=2,Type=Integer,Description="Confidence interval around END for imprecise variants">
##INFO=<ID=IMPRECISE,Number=0,Type=Flag,Description="Imprecise structural variation">
##ALT=<ID=CNV,Description="Copy number variable region">
##ALT=<ID=CNV,Description="Copy number gain region">
##ALT=<ID=CNV,Description="Copy number loss region">
##ALT=<ID=DEL,Description="Deletion">
##ALT=<ID=DUP,Description="Duplication">
##ALT=<ID=DUP:TANDEM,Description="Tandem Duplication">
##ALT=<ID=INS,Description="Insertion of novel sequence">
##ALT=<ID=INS:ME,Description="Mobile Element Insertion">
##ALT=<ID=INS:ME:ALU,Description="Insertion of ALU element">
##ALT=<ID=INV,Description="Inversion">
##ALT=<ID=SA,Description="Sequence Alteration">
##ALT=<ID=CSA,Description="Complex Structural Alteration">
##ALT=<ID=CS,Description="Complex Substitution">
##ALT=<ID=INDEL,Description="Indel">
##ALT=<ID=TL,Description="Translocation">
##ALT=<ID=TL:Inter,Description="Interchromosomal Translocation">
##ALT=<ID=TL:Intra,Description="Intrachromosomal Translocation">
##ALT=<ID=BP:InterC,Description="Interchromosomal Breakpoint">
##ALT=<ID=BP:IntraC,Description="Intrachromosomal Breakpoint">
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO
1	10000	nsv7879	N	<CNV>	.	.	SVTYPE=CNV;END=127330;SVLEN=117330
1	10000	nssv1529569	N	<CNV:GAIN>	.	.	SVTYPE=CNV;END=297968;SVLEN=287968
1	10000	nssv1614481	N	<DEL>	.	.	SVTYPE=DEL;END=1535693;SVLEN=-1525693
1	10051	esv3364878	N	<CNV>	.	.	SVTYPE=CNV;END=37287;SVLEN=27236;CIPOS=0,563;CIEND=-2000,0;IMPRECISE
1	11098	nssv4000242	N	<DUP>	.	.	SVTYPE=DUP;END=47000;SVLEN=35902
1	62296	esv2867013	N	<INS>	.	.	SVTYPE=INS;END=62297
VCF

# Create a string file handle to write to
my $fh = IO::String->new();

my $translator = Bio::EnsEMBL::IO::Translator::StructuralVariationFeature->new(\@info);
my $serializer = Bio::EnsEMBL::IO::Writer::VCF4->new($translator);
$serializer->open($fh);

# Write headers
$serializer->write(Bio::EnsEMBL::IO::Object::VCF4Metadata->directive('fileformat', 'VCFv4.2'));
foreach my $i (@info) {
  $serializer->write(Bio::EnsEMBL::IO::Object::VCF4Metadata->info($i));
}
foreach my $a (@alt) {
  $serializer->write(Bio::EnsEMBL::IO::Object::VCF4Metadata->alt($a));
}
foreach my $f (@formats) {
  $serializer->write(Bio::EnsEMBL::IO::Object::VCF4Metadata->format($f));
}
$serializer->write(Bio::EnsEMBL::IO::Object::VCF4Metadata->header(\@samples_list));

foreach my $feature (@features) {
  $serializer->write($feature);
}

eq_or_diff(${$fh->string_ref()}, $vcf_string, "Checking is serializer matches expected VCF");

done_testing();
