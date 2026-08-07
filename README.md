# KAPEc-AMR
INTRODUCTION

This repository is for antimicrobial resistance analysis of Illumina sequenced isolates, focused on KAPEc bacteria (Klebsiella, Acinetobacter, Pseudomonas and Escherichia) and built on nextflow. Compatible with docker (usage in standalone computers) or Singularity (High Performance Cluster), see -profile for these options. 

Illumina pipeline summary: It uses NAME_R1.fastq.gz and NAME_R2.fastq.gz files on /data folder, you do not need to put R1/R2 files in separate directories, just all the read files in /data folder. Please ensure that the R1/R2 files have the same isolate/strain name, otherwise it will not recognise them:

1. Quality control of reads: Raw read QC is assessed with FastQC. Low quality bases, adapters and sequencing artifacts (such as Poly-Gs) are removed with FastP. Then trimmed reads QC is assessed. Reports are summarised with MultiQC. 

2. Taxonomic identification: Trimmed reads are analysed with Kraken2 -> only the .report file is generated, to manually check the genus/species (Horrific screw-ups can happen sometimes :P)

3. De novo assembly: For now, only de novo assembly will be supported and done with SPAdes. However, we are considering a --reference mode option with variant calling (i.e mutant analysis) in a future release.

4. Quality check, completeness and contamination levels of assemblies: Quality metrics are obtained using QUAST and the overall metrics are condensed in a simplified report using MultiQC, while completeness and contamination levels are assessed with CheckM2. 

5. Multi Locus Sequence Typing (MLST): MLST is determined using MLST tool. 

6. Gene annotation: Gene annotation is obtained using BAKTA (since Prokka does not have updates anymore :/ )

7. Prediction of Antimicrobial resistance genes: Antimicrobial resistance determinants are predicted using AMRfinderplus (which uses a curated NCBI database, nice!). REMEMBER THAT THESE TOOLS ARE GOOD AS THEIR DATABASES, and some additional analysis must be made. The --organism option in the AMRfinderplus script is automated, derived from the MLST result (If no MLST is derived or is a species outside the list by MLST tool such as Stenotrophomonas maltophilia, it will run without --organism option). 

8. Prediction of virulence factors: Virulence factors are predicted using ABRicate, with the VFDB database. The abricate_db module will manage the download and setup of its database. 

9. Scan for plasmids/plasmid replicons: For Replicon identification and plasmid typing, this pipeline uses MOB RECON. 

10. Capsular locus and O-antigen of Klebsiella/Acinetobacter: Kaptive is used for K/O typing in Klebsiella and Acinetobacter. If another species is used (E.coli/Pseudomonas sp., etc) it will print empty files and a .txt file saying that the species is unsupported by Kaptive.

11. Serotyping for E. coli and Pseudomonas: Ectyper and Pasty are used for E. coli and Pseudomonas sp. serotyping respectively. Those modules use the same species logic as Kaptive. 

..................................................................................................................

Installation and requirements

    Pipeline pre-requisites:

        Nextflow (v. 25.10.0) or higher, since pipeline is written in DSL2.
        Docker/Singularity as container support
        Java 17 or higher.
        Databases for Kraken2, Checkm2, Bakta and Kaptive (see below)

Kraken2 database: You must provide a database, either by downloading and extracting a pre-built database from AWS repository (https://benlangmead.github.io/aws-indexes/k2) or build it with kraken2 commands if pre-installed. When cloning the repository, you should make an empty KAPEc-AMR(repo name)/db/kraken_db directory, where the database must be downloaded/compiled. Remember that the bare minimum files are hash.k2d, opts.k2d and taxo.k2d !!!

Checkm2 database: You must provide a Checkm2 database. You can download it from Zenodo database (https://zenodo.org/records/14897628) or built it with Checkm2 commands if pre-installed. It is expected to be inside db/checkm2. The route should be KAPEc-AMR(repo name)/db/checkm2_db/CheckM2_database/uniref100.KO.1.dmnd (database file).

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

Kaptive Database: You must provide the .gbk files for K/O loci of both Klebsiella and Acinetobacter for Kaptive. You can find them on github (https://github.com/klebgenomics/Kaptive/tree/master/src/kaptive/data), and download them to /db/kaptive_db. The Kaptive_db module will print an error if the files with exact names as expected are not found. 

....................................................................................................................


OPTIONS

    -profile    You can state whether the run would be in a single computer (-profile docker)
                or on a HPC compatible with Singularity (-profile singularity), in both cases 
                local executor is used. A third option is included for SLURM schelduler 
                (-profile singularity_slurm) but have not been tested yet.


## Acknowledgments

This pipeline is built with [Nextflow](https://www.nextflow.io/) (DSL2) and relies on the following open-source tools. If you use KAPEc-AMR in your work, please cite this repository together with the underlying tools listed below.

| Step | Tool | Repository |
|---|---|---|
| Workflow engine | Nextflow | https://github.com/nextflow-io/nextflow |
| Raw read QC | FastQC | https://github.com/s-andrews/FastQC |
| Read trimming/filtering | fastp | https://github.com/OpenGene/fastp |
| Report aggregation | MultiQC | https://github.com/MultiQC/MultiQC |
| Taxonomic identification | Kraken2 | https://github.com/DerrickWood/kraken2 |
| De novo assembly | SPAdes | https://github.com/ablab/spades |
| Assembly quality metrics | QUAST | https://github.com/ablab/quast |
| Completeness/contamination | CheckM2 | https://github.com/chklovski/CheckM2 |
| MLST | mlst | https://github.com/tseemann/mlst |
| Gene annotation | Bakta | https://github.com/oschwengers/bakta |
| AMR gene prediction | AMRFinderPlus | https://github.com/ncbi/amr |
| Virulence factor prediction | ABRicate + VFDB | https://github.com/tseemann/abricate |
| Plasmid reconstruction/typing | MOB-suite (MOB-recon) | https://github.com/phac-nml/mob-suite |
| Capsule/O-antigen typing | Kaptive | https://github.com/klebgenomics/Kaptive |
| *E. coli* serotyping | ECTyper | https://github.com/phac-nml/ecoli_serotyping |
| *Pseudomonas* serotyping | pasty | https://github.com/rpetit3/pasty |

### References

1. Di Tommaso, P., Chatzou, M., Floden, E. W., Barja, P. P., Palumbo, E., & Notredame, C. (2017). Nextflow enables reproducible computational workflows. *Nature Biotechnology*, 35(4), 316–319. https://doi.org/10.1038/nbt.3820

2. Andrews, S. (2010). *FastQC: A Quality Control Tool for High Throughput Sequence Data* [Software]. Babraham Bioinformatics. http://www.bioinformatics.babraham.ac.uk/projects/fastqc/

3. Chen, S., Zhou, Y., Chen, Y., & Gu, J. (2018). fastp: an ultra-fast all-in-one FASTQ preprocessor. *Bioinformatics*, 34(17), i884–i890. https://doi.org/10.1093/bioinformatics/bty560

4. Ewels, P., Magnusson, M., Lundin, S., & Käller, M. (2016). MultiQC: summarize analysis results for multiple tools and samples in a single report. *Bioinformatics*, 32(19), 3047–3048. https://doi.org/10.1093/bioinformatics/btw354

5. Wood, D. E., Lu, J., & Langmead, B. (2019). Improved metagenomic analysis with Kraken 2. *Genome Biology*, 20, 257. https://doi.org/10.1186/s13059-019-1891-0

6. Bankevich, A., Nurk, S., Antipov, D., Gurevich, A. A., Dvorkin, M., Kulikov, A. S., Lesin, V. M., Nikolenko, S. I., Pham, S., Prjibelski, A. D., Pyshkin, A. V., Sirotkin, A. V., Vyahhi, N., Tesler, G., Alekseyev, M. A., & Pevzner, P. A. (2012). SPAdes: a new genome assembly algorithm and its applications to single-cell sequencing. *Journal of Computational Biology*, 19(5), 455–477. https://doi.org/10.1089/cmb.2012.0021

7. Gurevich, A., Saveliev, V., Vyahhi, N., & Tesler, G. (2013). QUAST: quality assessment tool for genome assemblies. *Bioinformatics*, 29(8), 1072–1075. https://doi.org/10.1093/bioinformatics/btt086

8. Chklovski, A., Parks, D. H., Woodcroft, B. J., & Tyson, G. W. (2023). CheckM2: a rapid, scalable and accurate tool for assessing microbial genome quality using machine learning. *Nature Methods*, 20(8), 1203–1212. https://doi.org/10.1038/s41592-023-01940-w

9. Seemann, T. *mlst: Scan contig files against PubMLST typing schemes* [Software]. https://github.com/tseemann/mlst (uses the PubMLST database, Jolley, K. A., Bray, J. E., & Maiden, M. C. J. (2018). Open-access bacterial population genomics: BIGSdb software, the PubMLST.org website and their applications. *Wellcome Open Research*, 3, 124.)

10. Schwengers, O., Jelonek, L., Dieckmann, M. A., Beyvers, S., Blom, J., & Goesmann, A. (2021). Bakta: rapid and standardized annotation of bacterial genomes via alignment-free sequence identification. *Microbial Genomics*, 7(11), 000685. https://doi.org/10.1099/mgen.0.000685

11. Feldgarden, M., Brover, V., Gonzalez-Escalona, N., Frye, J. G., Haendiges, J., Haft, D. H., Hoffmann, M., Pettengill, J. B., Prasad, A. B., Tillman, G. E., Tyson, G. H., & Klimke, W. (2021). AMRFinderPlus and the Reference Gene Catalog facilitate examination of the genomic links among antimicrobial resistance, stress response, and virulence. *Scientific Reports*, 11, 12728. https://doi.org/10.1038/s41598-021-91456-0

12. Seemann, T. *ABRicate: Mass screening of contigs for antimicrobial and virulence genes* [Software]. https://github.com/tseemann/abricate — virulence database: Chen, L. et al. (2016). VFDB 2016: hierarchical and refined dataset for big data analysis—10 years on. *Nucleic Acids Research*, 44(D1), D694–D697. https://doi.org/10.1093/nar/gkv1239

13. Robertson, J., & Nash, J. H. E. (2018). MOB-suite: software tools for clustering, reconstruction and typing of plasmids from draft assemblies. *Microbial Genomics*, 4(8), e000206. https://doi.org/10.1099/mgen.0.000206

14. Lam, M. M. C., Wick, R. R., Judd, L. M., Holt, K. E., & Wyres, K. L. (2022). Kaptive 2.0: updated capsule and lipopolysaccharide locus typing for the *Klebsiella pneumoniae* species complex. *Microbial Genomics*, 8(3), 000800. https://doi.org/10.1099/mgen.0.000800

15. Bessonov, K., Laing, C., Robertson, J., Yong, I., Ziebell, K., Gannon, V. P. J., Nash, J. H. E., Christianson, S., Bekal, S., Reimer, A., Taboada, E., Domselaar, G. V., & Graham, M. (2021). ECTyper: in silico *Escherichia coli* serotype and species prediction from raw and assembled whole-genome sequence data. *Microbial Genomics*, 7(12), 000728. https://doi.org/10.1099/mgen.0.000728

16. Petit III, R. A. *pasty: In silico serogrouping of Pseudomonas aeruginosa isolates* [Software]. https://github.com/rpetit3/pasty (based on the original PAst method: Thrane, S. W. et al. (2016). *Pseudomonas aeruginosa* Typer (PAst): a web tool for rapid and accurate in silico serotyping of *Pseudomonas aeruginosa* isolates. *Journal of Clinical Microbiology*, 54(6), 1782–1788.)

*Container execution is provided via [Docker](https://www.docker.com/) or [Singularity/Apptainer](https://apptainer.org/), depending on the `-profile` selected.*





