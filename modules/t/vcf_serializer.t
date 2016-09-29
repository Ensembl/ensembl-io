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
use Bio::EnsEMBL::Variation::Variation;
use Bio::EnsEMBL::Variation::VariationFeature;
use IO::String;

use Bio::EnsEMBL::IO::Translator::SampleGenotypeFeature;
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


my %var_data = ( 'rs754176245' => { 'start'   => 230710045, 
                                    'end'     => 230710045,
                                    'alleles' => 'C/T',
                                    'aa'      => 'C'
                                  },  
                 'rs11568053'  => { 'start'   => 230710047, 
                                    'end'     => 230710047,
                                    'alleles' => 'C/T',
                                    'aa'      => 'C'
                                  },
                 'rs699'       => { 'start'   => 230710048, 
                                    'end'     => 230710048,
                                    'alleles' => 'A/G',
                                    'aa'      => 'G',
                                    'ma'      => 'A',
                                    'maf'     => 0.3,
                                    'mac'     => 1477
                                  }
              );

#my %sample_data = ( 'NA18594' => { 'genotype' => {'rs699' => '1/1'}, 'phased' => 0},
#                    'NA18573' => { 'genotype' => {'rs699' => '1/1'}, 'phased' => 0},
#                    'NA12875' => { 'genotype' => {'rs699' => '1/1'}, 'phased' => 0},
#                    'NA12874' => { 'genotype' => {'rs699' => '1/1'}, 'phased' => 0},
#                    'HG00096' => { 'genotype' => {'rs699' => '1/1'}, 'phased' => 0},
#                  );


my @vars = map { $_ } sort { $var_data{$a}{'start'} <=> $var_data{$b}{'start'} } keys(%var_data);
my @samples_list; #my @samples_list = sort(keys(%sample_data));

my @info    = ('AA','MA','MAF','MAC'); #('AA','MA','MAF','MAC', 'NS');
my @formats = (); #('GT');


my @features = ();
foreach my $var (@vars) {

  my $var_d = $var_data{$var};

  my $var_obj = Bio::EnsEMBL::Variation::Variation->new(
     -NAME   => $var,
     -ANCESTRAL_ALLELE => $var_d->{'aa'}
  );
  
  #my %sample_genotypes = ();
  #foreach my $sample (@samples_list) {
  #  if ($sample_data{$sample}{'genotype'} && $sample_data{$sample}{'genotype'}{$var}) {
  #    $sample_genotypes{$sample}{'genotype'} = $sample_data{$sample}{'genotype'}{$var};
  #    $sample_genotypes{$sample}{'phased'} = $sample_data{$sample}{'phased'};
  #  }
  #}
  #$var_obj->{'sample_genotypes'} = \%sample_genotypes if (scalar(keys(%sample_genotypes)) > 0);
  
  push @features, Bio::EnsEMBL::Variation::VariationFeature->new(
    -START => $var_d->{'start'},
    -END   => $var_d->{'end'},
    -STRAND        => 1,
    -SLICE => $slice,
    -ALLELE_STRING => $var_d->{'alleles'},
    -VARIATION     => $var_obj,
    -VARIATION_NAME => $var,
    -MINOR_ALLELE => $var_d->{'ma'},
    -MINOR_ALLELE_FREQUENCY => $var_d->{'maf'},
    -MINOR_ALLELE_COUNT => $var_d->{'mac'}
  );
  
  
}

#my $vcf_string = <<VCF;
# ##fileformat=VCFv4.2
# ##INFO=<ID=AA,Number=1,Type=String,Description="Ancestral Allele">
# ##INFO=<ID=MA,Number=1,Type=String,Description="Minor Allele">
# ##INFO=<ID=MAF,Number=1,Type=Float,Description="Minor Allele Frequency">
# ##INFO=<ID=MAC,Number=1,Type=Integer,Description="Minor Allele Count">
# ##INFO=<ID=NS,Number=1,Type=Integer,Description="Number of Samples With Data">
# ##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">
# #CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	HG00096	NA12874	NA12875	NA18573	NA18594
# 1	230710045	rs754176245	C	T	.	.	AA=C;NS=0	GT	.	.	.	.	.	.	.
# 1	230710047	rs11568053	C	T	.	.	AA=C;NS=0	GT	.	.	.	.	.	.	.
# 1	230710048	rs699	A	G	.	.	AA=G;MA=A;MAF=0.3;MAC=1477;NS=4	GT	1/1	1/1	1/1	1/1	.
# VCF

my $vcf_string = <<VCF;
##fileformat=VCFv4.2
##INFO=<ID=AA,Number=1,Type=String,Description="Ancestral Allele">
##INFO=<ID=MA,Number=1,Type=String,Description="Minor Allele">
##INFO=<ID=MAF,Number=1,Type=Float,Description="Minor Allele Frequency">
##INFO=<ID=MAC,Number=1,Type=Integer,Description="Minor Allele Count">
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO
1	230710045	rs754176245	C	T	.	.	AA=C
1	230710047	rs11568053	C	T	.	.	AA=C
1	230710048	rs699	A	G	.	.	AA=G;MA=A;MAF=0.3;MAC=1477
VCF

# Create a string file handle to write to
my $fh = IO::String->new();

my $translator = Bio::EnsEMBL::IO::Translator::SampleGenotypeFeature->new(\@info,\@formats,\@samples_list);
my $serializer = Bio::EnsEMBL::IO::Writer::VCF4->new($translator);
$serializer->open($fh);

# Write headers
$serializer->write(Bio::EnsEMBL::IO::Object::VCF4Metadata->directive('fileformat', 'VCFv4.2'));
foreach my $i (@info) {
  $serializer->write(Bio::EnsEMBL::IO::Object::VCF4Metadata->info($i));
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
