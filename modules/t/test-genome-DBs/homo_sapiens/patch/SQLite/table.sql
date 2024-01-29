--
-- Created by SQL::Translator::Producer::SQLite
-- Created on Fri Jan 26 15:05:34 2024
--

BEGIN TRANSACTION;

--
-- Table: "assembly"
--
CREATE TABLE "assembly" (
  "asm_seq_region_id" INT(10) NOT NULL,
  "cmp_seq_region_id" INT(10) NOT NULL,
  "asm_start" INT(10) NOT NULL,
  "asm_end" INT(10) NOT NULL,
  "cmp_start" INT(10) NOT NULL,
  "cmp_end" INT(10) NOT NULL,
  "ori" TINYINT(4) NOT NULL
);




--
-- Table: "assembly_exception"
--
CREATE TABLE "assembly_exception" (
  "assembly_exception_id" INTEGER PRIMARY KEY NOT NULL,
  "seq_region_id" INT(10) NOT NULL,
  "seq_region_start" INT(10) NOT NULL,
  "seq_region_end" INT(10) NOT NULL,
  "exc_type" ENUM(11) NOT NULL,
  "exc_seq_region_id" INT(10) NOT NULL,
  "exc_seq_region_start" INT(10) NOT NULL,
  "exc_seq_region_end" INT(10) NOT NULL,
  "ori" int(11) NOT NULL
);



--
-- Table: "coord_system"
--
CREATE TABLE "coord_system" (
  "coord_system_id" INTEGER PRIMARY KEY NOT NULL,
  "species_id" INT(10) NOT NULL DEFAULT 1,
  "name" VARCHAR(40) NOT NULL,
  "version" VARCHAR(255) DEFAULT NULL,
  "rank" int(11) NOT NULL,
  "attrib" varchar
);




--
-- Table: "data_file"
--
CREATE TABLE "data_file" (
  "data_file_id" INTEGER PRIMARY KEY NOT NULL,
  "coord_system_id" INT(10) NOT NULL,
  "analysis_id" SMALLINT(5) NOT NULL,
  "name" VARCHAR(100) NOT NULL,
  "version_lock" TINYINT(1) NOT NULL DEFAULT 0,
  "absolute" TINYINT(1) NOT NULL DEFAULT 0,
  "url" TEXT(65535),
  "file_type" ENUM(6)
);




--
-- Table: "dna"
--
CREATE TABLE "dna" (
  "seq_region_id" INTEGER PRIMARY KEY NOT NULL,
  "sequence" LONGTEXT(4294967295) NOT NULL
);

--
-- Table: "genome_statistics"
--
CREATE TABLE "genome_statistics" (
  "genome_statistics_id" INTEGER PRIMARY KEY NOT NULL,
  "statistic" VARCHAR(128) NOT NULL,
  "value" BIGINT(11) NOT NULL DEFAULT 0,
  "species_id" int(10) DEFAULT 1,
  "attrib_type_id" INT(10) DEFAULT NULL,
  "timestamp" DATETIME DEFAULT NULL
);


--
-- Table: "karyotype"
--
CREATE TABLE "karyotype" (
  "karyotype_id" INTEGER PRIMARY KEY NOT NULL,
  "seq_region_id" INT(10) NOT NULL,
  "seq_region_start" INT(10) NOT NULL,
  "seq_region_end" INT(10) NOT NULL,
  "band" VARCHAR(40) DEFAULT NULL,
  "stain" VARCHAR(40) DEFAULT NULL
);


--
-- Table: "meta"
--
CREATE TABLE "meta" (
  "meta_id" INTEGER PRIMARY KEY NOT NULL,
  "species_id" int(10) DEFAULT 1,
  "meta_key" VARCHAR(40) NOT NULL,
  "meta_value" VARCHAR(255) DEFAULT NULL
);



--
-- Table: "meta_coord"
--
CREATE TABLE "meta_coord" (
  "table_name" VARCHAR(40) NOT NULL,
  "coord_system_id" INT(10) NOT NULL,
  "max_length" int(11)
);


--
-- Table: "seq_region"
--
CREATE TABLE "seq_region" (
  "seq_region_id" INTEGER PRIMARY KEY NOT NULL,
  "name" VARCHAR(255) NOT NULL,
  "coord_system_id" INT(10) NOT NULL,
  "length" INT(10) NOT NULL
);



--
-- Table: "seq_region_synonym"
--
CREATE TABLE "seq_region_synonym" (
  "seq_region_synonym_id" INTEGER PRIMARY KEY NOT NULL,
  "seq_region_id" INT(10) NOT NULL,
  "synonym" VARCHAR(250) NOT NULL,
  "external_db_id" int(10)
);



--
-- Table: "seq_region_attrib"
--
CREATE TABLE "seq_region_attrib" (
  "seq_region_id" INT(10) NOT NULL DEFAULT 0,
  "attrib_type_id" SMALLINT(5) NOT NULL DEFAULT 0,
  "value" TEXT(65535) NOT NULL
);





--
-- Table: "alt_allele"
--
CREATE TABLE "alt_allele" (
  "alt_allele_id" INTEGER PRIMARY KEY NOT NULL,
  "alt_allele_group_id" int(10) NOT NULL,
  "gene_id" int(10) NOT NULL
);



--
-- Table: "alt_allele_attrib"
--
CREATE TABLE "alt_allele_attrib" (
  "alt_allele_id" int(10),
  "attrib" ENUM(35)
);


--
-- Table: "alt_allele_group"
--
CREATE TABLE "alt_allele_group" (
  "alt_allele_group_id" INTEGER PRIMARY KEY NOT NULL
);

--
-- Table: "analysis"
--
CREATE TABLE "analysis" (
  "analysis_id" INTEGER PRIMARY KEY NOT NULL,
  "created" datetime DEFAULT NULL,
  "logic_name" VARCHAR(128) NOT NULL,
  "db" VARCHAR(120),
  "db_version" VARCHAR(40),
  "db_file" VARCHAR(120),
  "program" VARCHAR(80),
  "program_version" VARCHAR(40),
  "program_file" VARCHAR(80),
  "parameters" TEXT(65535),
  "module" VARCHAR(80),
  "module_version" VARCHAR(40),
  "gff_source" VARCHAR(40),
  "gff_feature" VARCHAR(40)
);


--
-- Table: "analysis_description"
--
CREATE TABLE "analysis_description" (
  "analysis_id" SMALLINT(5) NOT NULL,
  "description" TEXT(65535),
  "display_label" VARCHAR(255) NOT NULL,
  "displayable" TINYINT(1) NOT NULL DEFAULT 1,
  "web_data" TEXT(65535)
);


--
-- Table: "attrib_type"
--
CREATE TABLE "attrib_type" (
  "attrib_type_id" INTEGER PRIMARY KEY NOT NULL,
  "code" VARCHAR(20) NOT NULL DEFAULT '',
  "name" VARCHAR(255) NOT NULL DEFAULT '',
  "description" TEXT(65535)
);


--
-- Table: "dna_align_feature"
--
CREATE TABLE "dna_align_feature" (
  "dna_align_feature_id" INTEGER PRIMARY KEY NOT NULL,
  "seq_region_id" INT(10) NOT NULL,
  "seq_region_start" INT(10) NOT NULL,
  "seq_region_end" INT(10) NOT NULL,
  "seq_region_strand" TINYINT(1) NOT NULL,
  "hit_start" int(11) NOT NULL,
  "hit_end" int(11) NOT NULL,
  "hit_strand" TINYINT(1) NOT NULL,
  "hit_name" VARCHAR(40) NOT NULL,
  "analysis_id" SMALLINT(5) NOT NULL,
  "score" DOUBLE,
  "evalue" DOUBLE,
  "perc_ident" FLOAT,
  "cigar_line" TEXT(65535),
  "external_db_id" int(10),
  "hcoverage" DOUBLE,
  "align_type" ENUM(7) DEFAULT 'ensembl'
);






--
-- Table: "dna_align_feature_attrib"
--
CREATE TABLE "dna_align_feature_attrib" (
  "dna_align_feature_id" INT(10) NOT NULL,
  "attrib_type_id" SMALLINT(5) NOT NULL,
  "value" TEXT(65535) NOT NULL
);





--
-- Table: "exon"
--
CREATE TABLE "exon" (
  "exon_id" INTEGER PRIMARY KEY NOT NULL,
  "seq_region_id" INT(10) NOT NULL,
  "seq_region_start" INT(10) NOT NULL,
  "seq_region_end" INT(10) NOT NULL,
  "seq_region_strand" TINYINT(2) NOT NULL,
  "phase" TINYINT(2) NOT NULL,
  "end_phase" TINYINT(2) NOT NULL,
  "is_current" TINYINT(1) NOT NULL DEFAULT 1,
  "is_constitutive" TINYINT(1) NOT NULL DEFAULT 0,
  "stable_id" VARCHAR(128) DEFAULT NULL,
  "version" SMALLINT(5) DEFAULT NULL,
  "created_date" DATETIME DEFAULT NULL,
  "modified_date" DATETIME DEFAULT NULL
);



--
-- Table: "exon_transcript"
--
CREATE TABLE "exon_transcript" (
  "exon_id" INT(10) NOT NULL,
  "transcript_id" INT(10) NOT NULL,
  "rank" INT(10) NOT NULL,
  PRIMARY KEY ("exon_id", "transcript_id", "rank")
);



--
-- Table: "gene"
--
CREATE TABLE "gene" (
  "gene_id" INTEGER PRIMARY KEY NOT NULL,
  "biotype" VARCHAR(40) NOT NULL,
  "analysis_id" SMALLINT(5) NOT NULL,
  "seq_region_id" INT(10) NOT NULL,
  "seq_region_start" INT(10) NOT NULL,
  "seq_region_end" INT(10) NOT NULL,
  "seq_region_strand" TINYINT(2) NOT NULL,
  "display_xref_id" INT(10),
  "source" VARCHAR(40) NOT NULL,
  "description" TEXT(65535),
  "is_current" TINYINT(1) NOT NULL DEFAULT 1,
  "canonical_transcript_id" INT(10) NOT NULL,
  "stable_id" VARCHAR(128) DEFAULT NULL,
  "version" SMALLINT(5) DEFAULT NULL,
  "created_date" DATETIME DEFAULT NULL,
  "modified_date" DATETIME DEFAULT NULL
);






--
-- Table: "gene_attrib"
--
CREATE TABLE "gene_attrib" (
  "gene_id" INT(10) NOT NULL DEFAULT 0,
  "attrib_type_id" SMALLINT(5) NOT NULL DEFAULT 0,
  "value" TEXT(65535) NOT NULL
);





--
-- Table: "protein_align_feature"
--
CREATE TABLE "protein_align_feature" (
  "protein_align_feature_id" INTEGER PRIMARY KEY NOT NULL,
  "seq_region_id" INT(10) NOT NULL,
  "seq_region_start" INT(10) NOT NULL,
  "seq_region_end" INT(10) NOT NULL,
  "seq_region_strand" TINYINT(1) NOT NULL DEFAULT 1,
  "hit_start" INT(10) NOT NULL,
  "hit_end" INT(10) NOT NULL,
  "hit_name" VARCHAR(40) NOT NULL,
  "analysis_id" SMALLINT(5) NOT NULL,
  "score" DOUBLE,
  "evalue" DOUBLE,
  "perc_ident" FLOAT,
  "cigar_line" TEXT(65535),
  "external_db_id" int(10),
  "hcoverage" DOUBLE,
  "align_type" ENUM(7) DEFAULT 'ensembl'
);






--
-- Table: "protein_feature"
--
CREATE TABLE "protein_feature" (
  "protein_feature_id" INTEGER PRIMARY KEY NOT NULL,
  "translation_id" INT(10) NOT NULL,
  "seq_start" INT(10) NOT NULL,
  "seq_end" INT(10) NOT NULL,
  "hit_start" INT(10) NOT NULL,
  "hit_end" INT(10) NOT NULL,
  "hit_name" VARCHAR(40) NOT NULL,
  "analysis_id" SMALLINT(5) NOT NULL,
  "score" DOUBLE,
  "evalue" DOUBLE,
  "perc_ident" FLOAT,
  "external_data" TEXT(65535),
  "hit_description" TEXT(65535),
  "cigar_line" TEXT(65535),
  "align_type" ENUM(9) DEFAULT NULL
);





--
-- Table: "supporting_feature"
--
CREATE TABLE "supporting_feature" (
  "exon_id" INT(10) NOT NULL DEFAULT 0,
  "feature_type" ENUM(21),
  "feature_id" INT(10) NOT NULL DEFAULT 0
);



--
-- Table: "transcript"
--
CREATE TABLE "transcript" (
  "transcript_id" INTEGER PRIMARY KEY NOT NULL,
  "gene_id" INT(10),
  "analysis_id" SMALLINT(5) NOT NULL,
  "seq_region_id" INT(10) NOT NULL,
  "seq_region_start" INT(10) NOT NULL,
  "seq_region_end" INT(10) NOT NULL,
  "seq_region_strand" TINYINT(2) NOT NULL,
  "display_xref_id" INT(10),
  "source" VARCHAR(40) NOT NULL DEFAULT 'ensembl',
  "biotype" VARCHAR(40) NOT NULL,
  "description" TEXT(65535),
  "is_current" TINYINT(1) NOT NULL DEFAULT 1,
  "canonical_translation_id" INT(10),
  "stable_id" VARCHAR(128) DEFAULT NULL,
  "version" SMALLINT(5) DEFAULT NULL,
  "created_date" DATETIME DEFAULT NULL,
  "modified_date" DATETIME DEFAULT NULL
);







--
-- Table: "transcript_attrib"
--
CREATE TABLE "transcript_attrib" (
  "transcript_id" INT(10) NOT NULL DEFAULT 0,
  "attrib_type_id" SMALLINT(5) NOT NULL DEFAULT 0,
  "value" TEXT(65535) NOT NULL
);





--
-- Table: "transcript_supporting_feature"
--
CREATE TABLE "transcript_supporting_feature" (
  "transcript_id" INT(10) NOT NULL DEFAULT 0,
  "feature_type" ENUM(21),
  "feature_id" INT(10) NOT NULL DEFAULT 0
);



--
-- Table: "translation"
--
CREATE TABLE "translation" (
  "translation_id" INTEGER PRIMARY KEY NOT NULL,
  "transcript_id" INT(10) NOT NULL,
  "seq_start" INT(10) NOT NULL,
  -- relative to exon start
  "start_exon_id" INT(10) NOT NULL,
  "seq_end" INT(10) NOT NULL,
  -- relative to exon start
  "end_exon_id" INT(10) NOT NULL,
  "stable_id" VARCHAR(128) DEFAULT NULL,
  "version" SMALLINT(5) DEFAULT NULL,
  "created_date" DATETIME DEFAULT NULL,
  "modified_date" DATETIME DEFAULT NULL
);



--
-- Table: "translation_attrib"
--
CREATE TABLE "translation_attrib" (
  "translation_id" INT(10) NOT NULL DEFAULT 0,
  "attrib_type_id" SMALLINT(5) NOT NULL DEFAULT 0,
  "value" TEXT(65535) NOT NULL
);





--
-- Table: "density_feature"
--
CREATE TABLE "density_feature" (
  "density_feature_id" INTEGER PRIMARY KEY NOT NULL,
  "density_type_id" INT(10) NOT NULL,
  "seq_region_id" INT(10) NOT NULL,
  "seq_region_start" INT(10) NOT NULL,
  "seq_region_end" INT(10) NOT NULL,
  "density_value" FLOAT NOT NULL
);



--
-- Table: "density_type"
--
CREATE TABLE "density_type" (
  "density_type_id" INTEGER PRIMARY KEY NOT NULL,
  "analysis_id" SMALLINT(5) NOT NULL,
  "block_size" int(11) NOT NULL,
  "region_features" int(11) NOT NULL,
  "value_type" ENUM(5) NOT NULL
);


--
-- Table: "ditag"
--
CREATE TABLE "ditag" (
  "ditag_id" INTEGER PRIMARY KEY NOT NULL,
  "name" VARCHAR(30) NOT NULL,
  "type" VARCHAR(30) NOT NULL,
  "tag_count" smallint(6) NOT NULL DEFAULT 1,
  "sequence" TINYTEXT(255) NOT NULL
);

--
-- Table: "ditag_feature"
--
CREATE TABLE "ditag_feature" (
  "ditag_feature_id" INTEGER PRIMARY KEY NOT NULL,
  "ditag_id" INT(10) NOT NULL DEFAULT 0,
  "ditag_pair_id" INT(10) NOT NULL DEFAULT 0,
  "seq_region_id" INT(10) NOT NULL DEFAULT 0,
  "seq_region_start" INT(10) NOT NULL DEFAULT 0,
  "seq_region_end" INT(10) NOT NULL DEFAULT 0,
  "seq_region_strand" TINYINT(1) NOT NULL DEFAULT 0,
  "analysis_id" SMALLINT(5) NOT NULL DEFAULT 0,
  "hit_start" INT(10) NOT NULL DEFAULT 0,
  "hit_end" INT(10) NOT NULL DEFAULT 0,
  "hit_strand" TINYINT(1) NOT NULL DEFAULT 0,
  "cigar_line" TINYTEXT(255) NOT NULL,
  "ditag_side" ENUM(1) NOT NULL
);




--
-- Table: "intron_supporting_evidence"
--
CREATE TABLE "intron_supporting_evidence" (
  "intron_supporting_evidence_id" INTEGER PRIMARY KEY NOT NULL,
  "analysis_id" SMALLINT(5) NOT NULL,
  "seq_region_id" INT(10) NOT NULL,
  "seq_region_start" INT(10) NOT NULL,
  "seq_region_end" INT(10) NOT NULL,
  "seq_region_strand" TINYINT(2) NOT NULL,
  "hit_name" VARCHAR(100) NOT NULL,
  "score" DECIMAL(10,3),
  "score_type" ENUM(5) DEFAULT 'NONE',
  "is_splice_canonical" TINYINT(1) NOT NULL DEFAULT 0
);



--
-- Table: "map"
--
CREATE TABLE "map" (
  "map_id" INTEGER PRIMARY KEY NOT NULL,
  "map_name" VARCHAR(30) NOT NULL
);

--
-- Table: "marker"
--
CREATE TABLE "marker" (
  "marker_id" INTEGER PRIMARY KEY NOT NULL,
  "display_marker_synonym_id" INT(10),
  "left_primer" VARCHAR(100) NOT NULL,
  "right_primer" VARCHAR(100) NOT NULL,
  "min_primer_dist" INT(10) NOT NULL,
  "max_primer_dist" INT(10) NOT NULL,
  "priority" int(11),
  "type" ENUM(14)
);



--
-- Table: "marker_feature"
--
CREATE TABLE "marker_feature" (
  "marker_feature_id" INTEGER PRIMARY KEY NOT NULL,
  "marker_id" INT(10) NOT NULL,
  "seq_region_id" INT(10) NOT NULL,
  "seq_region_start" INT(10) NOT NULL,
  "seq_region_end" INT(10) NOT NULL,
  "analysis_id" SMALLINT(5) NOT NULL,
  "map_weight" INT(10)
);



--
-- Table: "marker_map_location"
--
CREATE TABLE "marker_map_location" (
  "marker_id" INT(10) NOT NULL,
  "map_id" INT(10) NOT NULL,
  "chromosome_name" VARCHAR(15) NOT NULL,
  "marker_synonym_id" INT(10) NOT NULL,
  "position" VARCHAR(15) NOT NULL,
  "lod_score" DOUBLE,
  PRIMARY KEY ("marker_id", "map_id")
);


--
-- Table: "marker_synonym"
--
CREATE TABLE "marker_synonym" (
  "marker_synonym_id" INTEGER PRIMARY KEY NOT NULL,
  "marker_id" INT(10) NOT NULL,
  "source" VARCHAR(20),
  "name" VARCHAR(50)
);



--
-- Table: "misc_attrib"
--
CREATE TABLE "misc_attrib" (
  "misc_feature_id" INT(10) NOT NULL DEFAULT 0,
  "attrib_type_id" SMALLINT(5) NOT NULL DEFAULT 0,
  "value" TEXT(65535) NOT NULL
);





--
-- Table: "misc_feature"
--
CREATE TABLE "misc_feature" (
  "misc_feature_id" INTEGER PRIMARY KEY NOT NULL,
  "seq_region_id" INT(10) NOT NULL DEFAULT 0,
  "seq_region_start" INT(10) NOT NULL DEFAULT 0,
  "seq_region_end" INT(10) NOT NULL DEFAULT 0,
  "seq_region_strand" TINYINT(4) NOT NULL DEFAULT 0
);


--
-- Table: "misc_feature_misc_set"
--
CREATE TABLE "misc_feature_misc_set" (
  "misc_feature_id" INT(10) NOT NULL DEFAULT 0,
  "misc_set_id" SMALLINT(5) NOT NULL DEFAULT 0,
  PRIMARY KEY ("misc_feature_id", "misc_set_id")
);


--
-- Table: "misc_set"
--
CREATE TABLE "misc_set" (
  "misc_set_id" INTEGER PRIMARY KEY NOT NULL,
  "code" VARCHAR(25) NOT NULL DEFAULT '',
  "name" VARCHAR(255) NOT NULL DEFAULT '',
  "description" TEXT(65535) NOT NULL,
  "max_length" int(10) NOT NULL
);


--
-- Table: "prediction_exon"
--
CREATE TABLE "prediction_exon" (
  "prediction_exon_id" INTEGER PRIMARY KEY NOT NULL,
  "prediction_transcript_id" INT(10) NOT NULL,
  "exon_rank" SMALLINT(5) NOT NULL,
  "seq_region_id" INT(10) NOT NULL,
  "seq_region_start" INT(10) NOT NULL,
  "seq_region_end" INT(10) NOT NULL,
  "seq_region_strand" TINYINT(4) NOT NULL,
  "start_phase" TINYINT(4) NOT NULL,
  "score" DOUBLE,
  "p_value" DOUBLE
);



--
-- Table: "prediction_transcript"
--
CREATE TABLE "prediction_transcript" (
  "prediction_transcript_id" INTEGER PRIMARY KEY NOT NULL,
  "seq_region_id" INT(10) NOT NULL,
  "seq_region_start" INT(10) NOT NULL,
  "seq_region_end" INT(10) NOT NULL,
  "seq_region_strand" TINYINT(4) NOT NULL,
  "analysis_id" SMALLINT(5) NOT NULL,
  "display_label" VARCHAR(255)
);



--
-- Table: "repeat_consensus"
--
CREATE TABLE "repeat_consensus" (
  "repeat_consensus_id" INTEGER PRIMARY KEY NOT NULL,
  "repeat_name" VARCHAR(255) NOT NULL,
  "repeat_class" VARCHAR(100) NOT NULL,
  "repeat_type" VARCHAR(40) NOT NULL,
  "repeat_consensus" TEXT(65535)
);





--
-- Table: "repeat_feature"
--
CREATE TABLE "repeat_feature" (
  "repeat_feature_id" INTEGER PRIMARY KEY NOT NULL,
  "seq_region_id" INT(10) NOT NULL,
  "seq_region_start" INT(10) NOT NULL,
  "seq_region_end" INT(10) NOT NULL,
  "seq_region_strand" TINYINT(1) NOT NULL DEFAULT 1,
  "repeat_start" INT(10) NOT NULL,
  "repeat_end" INT(10) NOT NULL,
  "repeat_consensus_id" INT(10) NOT NULL,
  "analysis_id" SMALLINT(5) NOT NULL,
  "score" DOUBLE
);




--
-- Table: "simple_feature"
--
CREATE TABLE "simple_feature" (
  "simple_feature_id" INTEGER PRIMARY KEY NOT NULL,
  "seq_region_id" INT(10) NOT NULL,
  "seq_region_start" INT(10) NOT NULL,
  "seq_region_end" INT(10) NOT NULL,
  "seq_region_strand" TINYINT(1) NOT NULL,
  "display_label" VARCHAR(255) NOT NULL,
  "analysis_id" SMALLINT(5) NOT NULL,
  "score" DOUBLE
);




--
-- Table: "transcript_intron_supporting_evidence"
--
CREATE TABLE "transcript_intron_supporting_evidence" (
  "transcript_id" INT(10) NOT NULL,
  "intron_supporting_evidence_id" INT(10) NOT NULL,
  "previous_exon_id" INT(10) NOT NULL,
  "next_exon_id" INT(10) NOT NULL,
  PRIMARY KEY ("intron_supporting_evidence_id", "transcript_id")
);


--
-- Table: "gene_archive"
--
CREATE TABLE "gene_archive" (
  "gene_stable_id" VARCHAR(128) NOT NULL,
  "gene_version" SMALLINT(6) NOT NULL DEFAULT 1,
  "transcript_stable_id" VARCHAR(128) NOT NULL,
  "transcript_version" SMALLINT(6) NOT NULL DEFAULT 1,
  "translation_stable_id" VARCHAR(128),
  "translation_version" SMALLINT(6) NOT NULL DEFAULT 1,
  "peptide_archive_id" INT(10),
  "mapping_session_id" INT(10) NOT NULL
);





--
-- Table: "mapping_session"
--
CREATE TABLE "mapping_session" (
  "mapping_session_id" INTEGER PRIMARY KEY NOT NULL,
  "old_db_name" VARCHAR(80) NOT NULL DEFAULT '',
  "new_db_name" VARCHAR(80) NOT NULL DEFAULT '',
  "old_release" VARCHAR(5) NOT NULL DEFAULT '',
  "new_release" VARCHAR(5) NOT NULL DEFAULT '',
  "old_assembly" VARCHAR(80) NOT NULL DEFAULT '',
  "new_assembly" VARCHAR(80) NOT NULL DEFAULT '',
  "created" DATETIME NOT NULL
);

--
-- Table: "peptide_archive"
--
CREATE TABLE "peptide_archive" (
  "peptide_archive_id" INTEGER PRIMARY KEY NOT NULL,
  "md5_checksum" VARCHAR(32),
  "peptide_seq" MEDIUMTEXT(16777215) NOT NULL
);


--
-- Table: "mapping_set"
--
CREATE TABLE "mapping_set" (
  "mapping_set_id" INTEGER PRIMARY KEY NOT NULL,
  "internal_schema_build" VARCHAR(20) NOT NULL,
  "external_schema_build" VARCHAR(20) NOT NULL
);


--
-- Table: "stable_id_event"
--
CREATE TABLE "stable_id_event" (
  "old_stable_id" VARCHAR(128),
  "old_version" SMALLINT(6),
  "new_stable_id" VARCHAR(128),
  "new_version" SMALLINT(6),
  "mapping_session_id" INT(10) NOT NULL DEFAULT 0,
  "type" ENUM(11) NOT NULL,
  "score" FLOAT NOT NULL DEFAULT 0
);




--
-- Table: "seq_region_mapping"
--
CREATE TABLE "seq_region_mapping" (
  "external_seq_region_id" INT(10) NOT NULL,
  "internal_seq_region_id" INT(10) NOT NULL,
  "mapping_set_id" INT(10) NOT NULL
);



--
-- Table: "associated_group"
--
CREATE TABLE "associated_group" (
  "associated_group_id" INTEGER PRIMARY KEY NOT NULL,
  "description" VARCHAR(128) DEFAULT NULL
);

--
-- Table: "associated_xref"
--
CREATE TABLE "associated_xref" (
  "associated_xref_id" INTEGER PRIMARY KEY NOT NULL,
  "object_xref_id" INT(10) NOT NULL DEFAULT 0,
  "xref_id" INT(10) NOT NULL DEFAULT 0,
  "source_xref_id" INT(10) DEFAULT NULL,
  "condition_type" VARCHAR(128) DEFAULT NULL,
  "associated_group_id" INT(10) DEFAULT NULL,
  "rank" INT(10) DEFAULT 0
);






--
-- Table: "dependent_xref"
--
CREATE TABLE "dependent_xref" (
  "object_xref_id" INTEGER PRIMARY KEY NOT NULL,
  "master_xref_id" INT(10) NOT NULL,
  "dependent_xref_id" INT(10) NOT NULL
);



--
-- Table: "external_db"
--
CREATE TABLE "external_db" (
  "external_db_id" INTEGER PRIMARY KEY NOT NULL,
  "db_name" VARCHAR(100) NOT NULL,
  "db_release" VARCHAR(255),
  "status" ENUM(9) NOT NULL,
  "priority" int(11) NOT NULL,
  "db_display_name" VARCHAR(255),
  "type" ENUM(18) NOT NULL,
  "secondary_db_name" VARCHAR(255) DEFAULT NULL,
  "secondary_db_table" VARCHAR(255) DEFAULT NULL,
  "description" TEXT(65535)
);


--
-- Table: "biotype"
--
CREATE TABLE "biotype" (
  "biotype_id" INTEGER PRIMARY KEY NOT NULL,
  "name" VARCHAR(64) NOT NULL,
  "object_type" ENUM(10) NOT NULL DEFAULT 'gene',
  "db_type" varchar(19) NOT NULL DEFAULT 'core',
  "attrib_type_id" int(11) DEFAULT NULL,
  "description" TEXT(65535),
  "biotype_group" ENUM(10) DEFAULT NULL,
  "so_acc" VARCHAR(64),
  "so_term" VARCHAR(1023)
);


--
-- Table: "external_synonym"
--
CREATE TABLE "external_synonym" (
  "xref_id" INT(10) NOT NULL,
  "synonym" VARCHAR(100) NOT NULL,
  PRIMARY KEY ("xref_id", "synonym")
);


--
-- Table: "identity_xref"
--
CREATE TABLE "identity_xref" (
  "object_xref_id" INTEGER PRIMARY KEY NOT NULL,
  "xref_identity" INT(5),
  "ensembl_identity" INT(5),
  "xref_start" int(11),
  "xref_end" int(11),
  "ensembl_start" int(11),
  "ensembl_end" int(11),
  "cigar_line" TEXT(65535),
  "score" DOUBLE,
  "evalue" DOUBLE
);

--
-- Table: "interpro"
--
CREATE TABLE "interpro" (
  "interpro_ac" VARCHAR(40) NOT NULL,
  "id" VARCHAR(40) NOT NULL
);



--
-- Table: "object_xref"
--
CREATE TABLE "object_xref" (
  "object_xref_id" INTEGER PRIMARY KEY NOT NULL,
  "ensembl_id" INT(10) NOT NULL,
  "ensembl_object_type" ENUM(16) NOT NULL,
  "xref_id" INT(10) NOT NULL,
  "linkage_annotation" VARCHAR(255) DEFAULT NULL,
  "analysis_id" SMALLINT(5)
);




--
-- Table: "ontology_xref"
--
CREATE TABLE "ontology_xref" (
  "object_xref_id" INT(10) NOT NULL DEFAULT 0,
  "source_xref_id" INT(10) DEFAULT NULL,
  "linkage_type" VARCHAR(3) DEFAULT NULL
);




--
-- Table: "unmapped_object"
--
CREATE TABLE "unmapped_object" (
  "unmapped_object_id" INTEGER PRIMARY KEY NOT NULL,
  "type" ENUM(6) NOT NULL,
  "analysis_id" SMALLINT(5) NOT NULL,
  "external_db_id" int(10),
  "identifier" VARCHAR(255) NOT NULL,
  "unmapped_reason_id" INT(10) NOT NULL,
  "query_score" DOUBLE,
  "target_score" DOUBLE,
  "ensembl_id" INT(10) DEFAULT 0,
  "ensembl_object_type" ENUM(11) DEFAULT 'RawContig',
  "parent" VARCHAR(255) DEFAULT NULL
);





--
-- Table: "unmapped_reason"
--
CREATE TABLE "unmapped_reason" (
  "unmapped_reason_id" INTEGER PRIMARY KEY NOT NULL,
  "summary_description" VARCHAR(255),
  "full_description" VARCHAR(255)
);

--
-- Table: "xref"
--
CREATE TABLE "xref" (
  "xref_id" INTEGER PRIMARY KEY NOT NULL,
  "external_db_id" int(10) NOT NULL,
  "dbprimary_acc" VARCHAR(512) NOT NULL,
  "display_label" VARCHAR(512) NOT NULL,
  "version" VARCHAR(10) DEFAULT NULL,
  "description" TEXT(65535),
  "info_type" ENUM(18) NOT NULL DEFAULT 'NONE',
  "info_text" VARCHAR(255) NOT NULL DEFAULT ''
);




--
-- Table: "operon"
--
CREATE TABLE "operon" (
  "operon_id" INTEGER PRIMARY KEY NOT NULL,
  "seq_region_id" INT(10) NOT NULL,
  "seq_region_start" INT(10) NOT NULL,
  "seq_region_end" INT(10) NOT NULL,
  "seq_region_strand" TINYINT(2) NOT NULL,
  "display_label" VARCHAR(255) DEFAULT NULL,
  "analysis_id" SMALLINT(5) NOT NULL,
  "stable_id" VARCHAR(128) DEFAULT NULL,
  "version" SMALLINT(5) DEFAULT NULL,
  "created_date" DATETIME DEFAULT NULL,
  "modified_date" DATETIME DEFAULT NULL
);




--
-- Table: "operon_transcript"
--
CREATE TABLE "operon_transcript" (
  "operon_transcript_id" INTEGER PRIMARY KEY NOT NULL,
  "seq_region_id" INT(10) NOT NULL,
  "seq_region_start" INT(10) NOT NULL,
  "seq_region_end" INT(10) NOT NULL,
  "seq_region_strand" TINYINT(2) NOT NULL,
  "operon_id" INT(10) NOT NULL,
  "display_label" VARCHAR(255) DEFAULT NULL,
  "analysis_id" SMALLINT(5) NOT NULL,
  "stable_id" VARCHAR(128) DEFAULT NULL,
  "version" SMALLINT(5) DEFAULT NULL,
  "created_date" DATETIME DEFAULT NULL,
  "modified_date" DATETIME DEFAULT NULL
);




--
-- Table: "operon_transcript_gene"
--
CREATE TABLE "operon_transcript_gene" (
  "operon_transcript_id" INT(10),
  "gene_id" INT(10)
);


--
-- Table: "rnaproduct"
--
CREATE TABLE "rnaproduct" (
  "rnaproduct_id" INTEGER PRIMARY KEY NOT NULL,
  "rnaproduct_type_id" SMALLINT(5) NOT NULL,
  "transcript_id" INT(10) NOT NULL,
  "seq_start" INT(10) NOT NULL,
  -- relative to transcript start
  "start_exon_id" INT(10),
  "seq_end" INT(10) NOT NULL,
  -- relative to transcript start
  "end_exon_id" INT(10),
  "stable_id" VARCHAR(128) DEFAULT NULL,
  "version" SMALLINT(5) DEFAULT NULL,
  "created_date" DATETIME DEFAULT NULL,
  "modified_date" DATETIME DEFAULT NULL
);



--
-- Table: "rnaproduct_attrib"
--
CREATE TABLE "rnaproduct_attrib" (
  "rnaproduct_id" INT(10) NOT NULL DEFAULT 0,
  "attrib_type_id" SMALLINT(5) NOT NULL DEFAULT 0,
  "value" TEXT(65535) NOT NULL
);





--
-- Table: "rnaproduct_type"
--
CREATE TABLE "rnaproduct_type" (
  "rnaproduct_type_id" INTEGER PRIMARY KEY NOT NULL,
  "code" VARCHAR(20) NOT NULL DEFAULT '',
  "name" VARCHAR(255) NOT NULL DEFAULT '',
  "description" TEXT(65535)
);


COMMIT;
