# KAPEc-AMR
INTRODUCTION

This repository is for pipelines of WGS analysis focused on KAPEc bacterial isolates (Klebsiella, Acinetobacter, Pseudomonas and Escherichia). We will provide pipelines both for Illumina and Nanopore reads separatedly. 

Installation and requirements

    Pipeline pre-requisites:

        Nextflow (v. 25.10.0) or higher, since pipeline is written in DSL2.
        Docker/Singularity as container support
        Java 17 or higher.

    Kraken database: For the moment, automatic Kraken2 database is unsupported, hence the necesity of either downloading and extracting a pre-built database from AWS repository (https://benlangmead.github.io/aws-indexes/k2) or build it with kraken2 commands. When cloning the repository, an empty /db/kraken_db directory is provided where the database must be downloaded/compiled. Remember that the bare minimum files are hash.k2d, opts.k2d and taxo.k2d !!!


Illumina pipeline summary:

1. Quality control of reads: Raw read QC is assessed with FastQC. Low quality bases, adapters and sequencing artifacts (such as Poly-Gs) are removed with FastP. Then trimmed reads QC is assessed. Reports are summarised with MultiQC. 

2. Taxonomic identification: Trimmed reads are analysed with Kraken2 -> only the .report file is generated, to manually check the genus/species (Horrific screw-ups can happen sometimes :P)

3. De novo assembly: For now, only de novo assembly will be supported and done with SPades. However, we are considering a --reference mode option with variant calling (i.e mutant analysis) in a future release.

Nanopore pipeline summary: Work in progress... :P



