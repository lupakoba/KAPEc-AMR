#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// ------------------------
// Parámetros de entrada
// ------------------------
params.input       = params.input ?: 'data/*_{R1,R2}.fastq.gz'
params.kraken2_db  = params.kraken2_db ?: '/PROJECTES/MICROBIOLOGIA/luciano/KAPEc-AMR/db/kraken_db'
params.outdir      = params.outdir ?: 'results'

// ------------------------
// Incluir módulos
// ------------------------
include { FASTQC_RAW }      from './modules/fastqc_raw.nf'
include { FASTQC_TRIMMED }  from './modules/fastqc_trimmed.nf'
include { FASTP }           from './modules/fastp.nf'
include { MULTIQC_FASTQC }  from './modules/multiqc.nf'
include { KRAKEN2 }         from './modules/kraken2.nf'
include { SPADES_ASSEMBLY } from './modules/spades.nf'
include { MLST }            from './modules/mlst.nf'
include { QUAST }           from './modules/quast.nf'
include { MULTIQC_QUAST }   from './modules/multiqc_quast.nf'
include { CHECKM2 }         from './modules/checkm2.nf'
include { BAKTA }           from './modules/bakta.nf'
include { AMRFINDERPLUS }   from './modules/amrfinder.nf'
include { ABRICATE_DB }     from './modules/abricate_db.nf'
include { ABRICATE_VF }     from './modules/virulence.nf'
include { MOB_RECON }       from './modules/mobrecon.nf'  
include { KAPTIVE_DB }      from './modules/kaptive_db.nf'
include { KAPTIVE }         from './modules/kaptive.nf'
include { ECTYPER }         from './modules/ectyper.nf'
include { PASTY }           from './modules/pasty.nf'


workflow {

    log.info """
\033[1;36m
 ▄    ▄   ▄▄   ▄▄▄▄▄  ▄▄▄▄▄▄                 ▄▄   ▄    ▄ ▄▄▄▄▄ 
 █  ▄▀    ██   █   ▀█ █       ▄▄▄            ██   ██  ██ █   ▀█
 █▄█     █  █  █▄▄▄█▀ █▄▄▄▄▄ █▀  ▀          █  █  █ ██ █ █▄▄▄▄▀
 █  █▄   █▄▄█  █      █      █       ▀▀▀    █▄▄█  █ ▀▀ █ █   ▀▄
 █   ▀▄ █    █ █      █▄▄▄▄▄ ▀█▄▄▀         █    █ █    █ █    ▀
                                                               
╔════════════════════════════════════════════════════════════════╗
║    Pipeline for WGS analysis of Gram-negative AMR Bacteria     ║
║    (Klebsiella, Acinetobacter, Pseudomonas, Escherichia)       ║
╚════════════════════════════════════════════════════════════════╝
\033[0m

Input    :  ${params.input}
Kraken2 DB: ${params.kraken2_db}
Profile  :  ${workflow.profile}
Run name :  ${workflow.runName}
Started  :  ${workflow.start}
"""

    // ------------------------
    // Read (R1 + R2) channel
    // ------------------------
    read_ch = channel.fromFilePairs(params.input, size: 2)

    // ------------------------
    // Channel for KRAKEN2 DB
    // ------------------------
    kraken2_db_ch = Channel.fromPath(params.kraken2_db)   // <- path real como canal

    // ------------------------
    // FastQC raw reads
    // ------------------------
    fastqc_raw_result = FASTQC_RAW(read_ch)

    // ------------------------
    // Read trimming with fastp
    // ------------------------
    fastp_result = FASTP(read_ch)

    // ------------------------
    // FastQC post-trim
    // ------------------------
    fastqc_trimmed_result = FASTQC_TRIMMED(fastp_result.trimmed_reads)

    // ------------------------
    // Preparing FastQC files for MultiQC 
    // ------------------------
    multiqc_input = fastqc_raw_result.fastqc_zip
        .mix(fastqc_trimmed_result.fastqc_zip)
        .collect()

    // ------------------------
    // MultiQC for FastQC results
    // ------------------------
    MULTIQC_FASTQC(multiqc_input)

    // ------------------------
    // Preparing inputs for Kraken2
    // ------------------------
    kraken2_input_ch = fastp_result.trimmed_reads
        .combine(kraken2_db_ch)         // <- combina cada muestra con la DB
        .map { sample_id, reads, db_file -> tuple(sample_id, reads, db_file) }

    // ------------------------
    // Kraken2
    // ------------------------
    kraken2_result = kraken2_input_ch | KRAKEN2

    // ------------------------
    // SPAdes (de novo assembly)
    // ------------------------
    spades_result = fastp_result.trimmed_reads | SPADES_ASSEMBLY

    // ------------------------
    // QUAST per sample
    // ------------------------
    quast_result = spades_result | QUAST

    // ------------------------
    // Prepare QUAST directories for MultiQC
    // ------------------------
    quast_dirs = quast_result
        .map { sample_id, dir -> dir }

    // Grouping all QUAST directories into a single list for MultiQC
    quast_dirs_collected = quast_dirs.collect()

    // ------------------------
    // MultiQC for QUAST results
    // ------------------------
    MULTIQC_QUAST(quast_dirs_collected)

    // ------------------------
    // MLST typing
    // ------------------------
    mlst_result = spades_result | MLST

    // ----------------------------------------------------------------
    // Channel for CheckM2 DB
    // ----------------------------------------------------------------
    checkm2_db_ch = Channel
        .fromPath(params.checkm2_db_file, checkIfExists: true)
        .collect()

    // ----------------------------------------------------------------
    // Preparing inputs for CheckM2 and executing CheckM2
    // ----------------------------------------------------------------
    checkm2_input = spades_result.combine(checkm2_db_ch)
    checkm2_results = CHECKM2(checkm2_input)

    // ----------------------------------------------------------------
    // Channel for BAKTA DB
    // ----------------------------------------------------------------
    ch_bakta_db = Channel.value(true) 

    // ----------------------------------------------------------------
    // Preparing inputs for BAKTA 
    // ----------------------------------------------------------------
    ch_for_bakta = spades_result.map { tuple ->
        def (sample_id, fasta) = tuple
        return [sample_id, fasta]
    }

    // ----------------------------------------------------------------
    // Executing BAKTA
    // ----------------------------------------------------------------
    BAKTA(ch_for_bakta)

    // ----------------------------------------------------------------
    // Preparing inputs for AMRFINDERPLUS 
    // ----------------------------------------------------------------
    amrfinder_input = spades_result.join(mlst_result)

    // ----------------------------------------------------------------
    // Executing AMRFINDERPLUS
    // ----------------------------------------------------------------
    amrfinder_result = amrfinder_input | AMRFINDERPLUS

    // ----------------------------------------------------------------
    // Channel for ABRICATE DATABASE
    // ----------------------------------------------------------------
    abricate_db_ch = ABRICATE_DB()

    // ----------------------------------------------------------------
    // Preparing inputs for ABRICATE
    // ----------------------------------------------------------------
        abricate_input = spades_result
        .combine(abricate_db_ch)
        .map { sample_id, assembly, db ->
            tuple(sample_id, assembly, db)
        }
    // ----------------------------------------------------------------
    // Executing ABRICATE
    // ----------------------------------------------------------------
    abricate_results = abricate_input | ABRICATE_VF

    // ----------------------------------------------------------------
    // Executing MOB_RECON
    // ----------------------------------------------------------------
    mob_result = spades_result | MOB_RECON

    // ----------------------------------------------------------------
    // Database for KAPTIVE
    // ----------------------------------------------------------------
    KAPTIVE_DB()

    // ----------------------------------------------------------------
    // Preparing inputs for KAPTIVE
    // ----------------------------------------------------------------
    kaptive_sample_ch = spades_result.join(mlst_result)
    
    // ----------------------------------------------------------------
    // Executing KAPTIVE: Two separate arguments, one for the 
    // sample channel and one for the DB channel
    // ----------------------------------------------------------------
    KAPTIVE(
        kaptive_sample_ch, 
        KAPTIVE_DB.out.db_files.collect()
    )
    
    // ----------------------------------------------------------------
    // Preparing inputs for Ectyper
    // ----------------------------------------------------------------
    ectyper_input = spades_result
    .join(mlst_result)

    // ----------------------------------------------------------------
    // Executing ECTYPER
    // ----------------------------------------------------------------
    ECTYPER(ectyper_input)

    // ----------------------------------------------------------------
    // Preparing inputs for PASTY
    // ----------------------------------------------------------------
    pasty_input = spades_result
    .join(mlst_result)

    // ----------------------------------------------------------------
    // Executing PASTY
    // ----------------------------------------------------------------
    PASTY(pasty_input)

    
}