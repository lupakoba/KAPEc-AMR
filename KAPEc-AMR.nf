#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// ------------------------
// Parámetros de entrada
// ------------------------
params.input       = params.input ?: 'data/*_{R1,R2}.fastq.gz'
params.kraken2_db  = params.kraken2_db ?: '/PROJECTES/MICROBIOLOGIA/luciano/KAPEc-AMR/db/kraken_db'

// ------------------------
// Incluir módulos
// ------------------------
include { fastqc_raw }      from './modules/fastqc_raw.nf'
include { fastqc_trimmed }  from './modules/fastqc_trimmed.nf'
include { fastp_trim }      from './modules/fastp.nf'
include { multiqc }         from './modules/multiqc.nf'
include { KRAKEN2 }         from './modules/kraken2.nf'
include { SPADES_ASSEMBLY } from './modules/spades.nf'
include { MLST }            from './modules/mlst.nf'

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
    // Canal por muestra (R1 + R2)
    // ------------------------
    read_ch = channel.fromFilePairs(params.input, size: 2)

    // ------------------------
    // Canal global con la DB de Kraken2
    // ------------------------
    kraken2_db_ch = Channel.fromPath(params.kraken2_db)   // <- path real como canal

    // ------------------------
    // FastQC raw
    // ------------------------
    fastqc_raw_result = fastqc_raw(read_ch)

    // ------------------------
    // Trimming con fastp
    // ------------------------
    fastp_result = fastp_trim(read_ch)

    // ------------------------
    // FastQC post-trim
    // ------------------------
    fastqc_trimmed_result = fastqc_trimmed(fastp_result.trimmed_reads)

    // ------------------------
    // Preparar archivos para MultiQC
    // ------------------------
    multiqc_input = fastqc_raw_result.fastqc_zip
        .mix(fastqc_trimmed_result.fastqc_zip)
        .collect()

    // ------------------------
    // Ejecutar MultiQC
    // ------------------------
    multiqc(multiqc_input)

    // ------------------------
    // Preparar input para Kraken2
    // ------------------------
    kraken2_input_ch = fastp_result.trimmed_reads
        .combine(kraken2_db_ch)         // <- combina cada muestra con la DB
        .map { sample_id, reads, db_file -> tuple(sample_id, reads, db_file) }

    // DEBUG: ver qué llega al proceso Kraken2
    // kraken2_input_ch.view()

    // ------------------------
    // Ejecutar Kraken2
    // ------------------------
    kraken2_result = kraken2_input_ch | KRAKEN2


    // ------------------------
    // Ejecutar SPAdes (ensamblaje)
    // ------------------------
    spades_result = fastp_result.trimmed_reads | SPADES_ASSEMBLY

    // ------------------------
    // Ejecutar MLST (a partir de los ensamblados)
    // ------------------------
    mlst_result = spades_result | MLST


}