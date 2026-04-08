# KAPEc-AMR
INTRODUCTION

This repository is for antimicrobial resistance analysis of sequenced isolates, focused on KAPEc bacteria (Klebsiella, Acinetobacter, Pseudomonas and Escherichia) and built on nextflow. Compatible with docker (usage in standalone computers) or Singularity (High Performance Cluster), see -profile for these options. We will provide pipelines both for Illumina and Nanopore reads separatedly. 

....................................................................................................

Installation and requirements

    Pipeline pre-requisites:

        Nextflow (v. 25.10.0) or higher, since pipeline is written in DSL2.
        Docker/Singularity as container support
        Java 17 or higher.
        Databases for Kraken2, Checkm2 and Bakta (see below)

Kraken2 database: You must provide a database, either by downloading and extracting a pre-built database from AWS repository (https://benlangmead.github.io/aws-indexes/k2) or build it with kraken2 commands if pre-installed. When cloning the repository, you should make an empty KAPEc-AMR(repo name)/db/kraken_db directory, where the database must be downloaded/compiled. Remember that the bare minimum files are hash.k2d, opts.k2d and taxo.k2d !!!

Checkm2 database: You must provide a Checkm2 database. You can download it from Zenodo database (https://zenodo.org/records/14897628) or built it with Checkm2 commands if pre-installed. Its expected to be inside db/checkm2. The route should be KAPEc-AMR(repo name)/db/checkm2_db/CheckM2_database/uniref100.KO.1.dmnd (database file).

Bakta database: You must provide a database compatible with BAKTA v. 1.12.0. If you have bakta pre-installed in your computer, you can use Bakta commands to build it. Otherwise, you can download it from official repository in Zenodo (https://zenodo.org/records/14916843), unzip it with tar -xvf and force update the internal amrfinderplus database once. 
    
    For the latter case, an idea for usage in a HPC with singularity:
        
    CONTAINER_IMG="path/to/bakta_container.img"
    LOCAL_DB_DIR="/path/to/cloned/repository"

    singularity exec \
        -B ${LOCAL_DB_DIR}:/data \
        ${CONTAINER_IMG} \
        amrfinder_update \
        --force_update \
        --database /data/amrfinderplus-db

The expected route for the bakta database is: KAPEc-AMR(repo name)/db/bakta_db/db-light. Inside this directory should be the database files for bakta and the internal amrfinderplus database directory (also for Bakta).

..................................................................................................

Illumina pipeline summary:

    1. Quality control of reads: Raw read QC is assessed with FastQC. Low quality bases, adapters and sequencing artifacts (such as Poly-Gs) are removed with FastP. Then trimmed reads QC is assessed. Reports are summarised with MultiQC. 

    2. Taxonomic identification: Trimmed reads are analysed with Kraken2 -> only the .report file is generated, to manually check the genus/species (Horrific screw-ups can happen sometimes :P)

    3. De novo assembly: For now, only de novo assembly will be supported and done with SPAdes. However, we are considering a --reference mode option with variant calling (i.e mutant analysis) in a future release.

    4. Quality check, completeness and contamination levels of assemblies: Quality metrics are obtained using QUAST and the overall metrics are condensed in a simplified report using MultiQC, while completeness and contamination levels are assessed with CheckM2. 

    5. Multi Locus Sequence Typing (MLST): MLST is determined using MLST tool. 

    6. Gene annotation: Gene annotation is obtained using BAKTA (since Prokka does not have updates anymore :/ )

    7. Prediction of Antimicrobial resistance genes: Antimicrobial resistance determinants are predicted using AMRfinderplus (which uses a curated NCBI database, nice!). REMEMBER THAT THESE TOOLS ARE GOOD AS THEIR DATABASES, and some additional analysis must be made. The --organism option in the AMRfinderplus script is automated, derived from the MLST result (If no MLST is derived or is a species outside the list by MLST tool such as Stenotrophomonas maltophilia, it will run without --organism option). 


OPTIONS

    -profile    You can state whether the run would be in a single computer (-profile docker) or on 
                a HPC compatible with Singularity (-profile singularity), in both cases local executor is used. A third option is included for SLURM scheluder (-profile singularity_slurm) but have not been tested yet.




Nanopore pipeline summary: Work in progress... :P



