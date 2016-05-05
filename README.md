# ensembl-io

![Build Status](https://travis-ci.org/Ensembl/ensembl-io.svg)

## File parsing and writing code for Ensembl

The ensembl-io repo is intended as a shared codebase for handling
the parsing and writing of popular biological formats used by Ensembl,
such as BED, BigWig and FASTA. For a full list of supported formats,
see the child objects in modules/Bio/EnsEMBL/IO/Parser/.

As the code matures, it is anticipated that various teams within the
Ensembl project will begin to integrate Bio::EnsEMBL::IO modules into
their pipelines; it is now used in future releases of the Ensembl
website to handle parsing of uploaded data.

All parsers should have associated unit tests, which can also serve as
simple tutorials on how to use ensembl-io.

### Bio::DB::HTS

Tabix and BAM/CRAM file access requires the Bio::DB::HTS module
to be installed. For details on how to obtain and install this please
see [https://github.com/Ensembl/Bio-HTS](https://github.com/Ensembl/Bio-HTS).

Alternatively, Bio::DB::HTS can be installed from CPAN.
