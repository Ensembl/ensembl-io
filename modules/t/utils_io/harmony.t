# Copyright [2018-2023] EMBL-European Bioinformatics Institute
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use strict;
use warnings;

use FindBin qw/$Bin/;
use Test::More;
use Test::Deep;
use Test::Differences;
use Test::Exception;

use IO::String;

use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::CoordSystem;
use Bio::EnsEMBL::Slice;

use Bio::EnsEMBL::Utils::IO::FASTASerializer;
use Bio::EnsEMBL::Utils::IO::GFFSerializer;
use Bio::EnsEMBL::Utils::IO::GTFSerializer;
use Bio::EnsEMBL::Utils::IO::BEDSerializer;
use Bio::EnsEMBL::IO::Writer;
use Bio::EnsEMBL::IO::Translator::Gene;
use Bio::EnsEMBL::IO::Writer::GFF3;
use Bio::EnsEMBL::IO::Object::GXFMetadata;
use Bio::EnsEMBL::IO::Writer::GTF;
use Bio::EnsEMBL::IO::Writer::BED;



# Get a DBAdaptor to from the test system
my $multi = Bio::EnsEMBL::Test::MultiTestDB->new(undef, "$Bin/..");
ok($multi, "Test DB loaded successfully");
my $db = $multi->get_DBAdaptor("core");
ok($db, "Core DB adaptor loaded successfully");


# fetch a protein_coding gene object
my $ga = $db->get_GeneAdaptor();
my $genes = $ga->fetch_all;
is(ref @{$genes}[0], 'Bio::EnsEMBL::Gene', "Gene objects loaded successfully");



# to test with a single gene

# my $gene = $ga->fetch_by_stable_id("ENSG00000171456");
# ok($gene, "Gene object loaded successfully");



# GFF
{
  my ($utils_output, $ensio_output);

  open my $utils_fh, '>', \$utils_output;
  my $utils_gff_writer = Bio::EnsEMBL::Utils::IO::GFFSerializer->new($utils_fh); # No need to fiddle with chunk sizes at this point

  # $utils_gff_writer->print_main_header([$gene->feature_Slice()]);
  $utils_gff_writer->print_main_header;
  foreach my $gene (@{$genes}) {
    $utils_gff_writer->print_feature($gene);
  }
  close $utils_fh;



  open my $ensio_fh, '>', \$ensio_output;

  my $translator = Bio::EnsEMBL::IO::Translator::Gene->new();
  my $serializer = Bio::EnsEMBL::IO::Writer::GFF3->new($translator);

  $serializer->open($ensio_fh);

  # Write headers
  $serializer->write(Bio::EnsEMBL::IO::Object::GXFMetadata->directive('gff-version', 3));
  # $serializer->write(Bio::EnsEMBL::IO::Object::GXFMetadata->ens_directive('genome-build', 'ensembl', 'GRCh38'));

  foreach my $gene (@{$genes}) {
    $serializer->write($gene);
  }

  close $ensio_fh;


  is($utils_output, $ensio_output, "GFF3 harmonization test pass");
}





# GTF
{
  my ($utils_output, $ensio_output);

  open my $utils_fh, '>', \$utils_output;
  my $utils_gtf_writer = Bio::EnsEMBL::Utils::IO::GTFSerializer->new($utils_fh); # No need to fiddle with chunk sizes at this point

  # $utils_gtf_writer->print_main_header([$gene->feature_Slice()]);
  # $utils_gtf_writer->print_main_header($db);
  foreach my $gene (@{$genes}) {
    $utils_gtf_writer->print_Gene($gene);
  }

  my @utils_output = split (/\n/, $utils_output);
  my $utils_output_clean = shift @utils_output;

  foreach my $line (@utils_output) {
   if ($line =~ /^\d+\t\w+\tgene\t/ ) {
      $utils_output_clean .= "$line\n";
    }
  }

  my $utils_data;
  foreach my $line (split (/\n/, $utils_output_clean)) {

    my @line_data = split (/\t/, $line);

    my $last_field = pop @line_data;
    my @fields = split(/;/, $last_field);

    my $hash_data = {};
    foreach my $data (@fields) {
      my ($key, $value) = $data =~ /\s?(\w*)\s+\"?(\w*)\"?/;
      $hash_data->{$key} = $value;
    }
    push (@line_data, $hash_data);
    push @{$utils_data}, [@line_data];
  }

  close $utils_fh;



  open my $ensio_fh, '>', \$ensio_output;

  my $translator = Bio::EnsEMBL::IO::Translator::Gene->new();
  my $serializer = Bio::EnsEMBL::IO::Writer::GTF->new($translator);

  $serializer->open($ensio_fh);

  # Write headers
  # $serializer->write(Bio::EnsEMBL::IO::Object::GXFMetadata->directive('gff-version', 3));
  # $serializer->write(Bio::EnsEMBL::IO::Object::GXFMetadata->ens_directive('genome-build', 'ensembl', 'GRCh38'));

  foreach my $gene (@{$genes}) {
    $serializer->write($gene);
  }

  my $ensio_data;
  foreach my $line (split (/\n/, $utils_output_clean)) {

    my @line_data = split (/\t/, $line);

    my $last_field = pop @line_data;
    my @fields = split(/;/, $last_field);

    my $hash_data = {};
    foreach my $data (@fields) {
      my ($key, $value) = $data =~ /\s?(\w*)\s+\"?(\w*)\"?/;
      $hash_data->{$key} = $value;
    }
    push (@line_data, $hash_data);
    push @{$ensio_data}, [@line_data];
  }

  close $ensio_fh;


  is_deeply($utils_data, $ensio_data, "GTF harmonization test pass");
}




# # ensembl-io and utils-io BED writers seem to produce different BED formats. Investigation needed.
# # BED
# {
#   my ($utils_output, $ensio_output);

#   open my $utils_fh, '>', \$utils_output;

#   my $utils_bed_writer = Bio::EnsEMBL::Utils::IO::BEDSerializer->new($utils_fh);

#   foreach my $gene (@{$genes}) {
#     $utils_bed_writer->print_feature($gene);
#   }

#   close $utils_fh;

#   open my $ensio_fh, '>', \$ensio_output;

#   my $translator = Bio::EnsEMBL::IO::Translator::Gene->new();
#   my $serializer = Bio::EnsEMBL::IO::Writer::BED->new($translator);

#   $serializer->open($ensio_fh);

#   foreach my $gene (@{$genes}) {
#     $serializer->write($gene);
#   }

#   close $ensio_fh;

#   is($utils_output, $ensio_output, "BED harmonization test pass");
# }




# # ensembl-io FASTA writer is currently missing. Implementation required?
# # FASTA
# {
#   my ($utils_output, $ensio_output);

#   open my $utils_fh, '>', \$utils_output;
#   my $utils_fasta_writer = Bio::EnsEMBL::Utils::IO::FASTASerializer->new($utils_fh); # No need to fiddle with chunk sizes at this point

#   # foreach my $gene (@{$genes}) {
#     $utils_fasta_writer->print_Seq($gene->feature_Slice);
#   # }

#   close $utils_fh;

#   open my $ensio_fh, '>', \$ensio_output;

#   my $ensio_fasta_writer = Bio::EnsEMBL::IO::Writer->new('Fasta', $ensio_fh);
#   my $translator = Bio::EnsEMBL::IO::Translator::Gene->new();
#   # my $serializer = Bio::EnsEMBL::IO::Writer::FASTA->new($translator);

#   # foreach my $gene (@{$genes}) {
#     $ensio_fasta_writer->write($translator);
#     # $serializer->write($gene);
#   # }

#   close $ensio_fh;

#   is($utils_output, $ensio_output, "FASTA harmonization test pass");
# }



done_testing();
