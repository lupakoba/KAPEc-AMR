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
include { fastqc_raw }      from './modules/fastqc_raw.nf'
include { fastqc_trimmed }  from './modules/fastqc_trimmed.nf'
include { fastp_trim }      from './modules/fastp.nf'
include { MULTIQC_FASTQC }  from './modules/multiqc.nf'
include { KRAKEN2 }         from './modules/kraken2.nf'
include { SPADES_ASSEMBLY } from './modules/spades.nf'
include { MLST }            from './modules/mlst.nf'
include { QUAST }           from './modules/quast.nf'
include { MULTIQC_QUAST }   from './modules/multiqc_quast.nf'
include { CHECKM2 }         from './modules/checkm2.nf'
include { BAKTA }           from './modules/bakta.nf'
include { AMRFINDERPLUS }   from './modules/amrfinder.nf'

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
    MULTIQC_FASTQC(multiqc_input)

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
    // QUAST por muestra
    // ------------------------
    quast_result = spades_result | QUAST

    // ------------------------
    // Preparar inputs para MultiQC (QUAST)
    // ------------------------
    quast_dirs = quast_result
        .map { sample_id, dir -> dir }

    // Agrupar todos los resultados
    quast_dirs_collected = quast_dirs.collect()

    // ------------------------
    // MultiQC de ensamblaje
    // ------------------------
    MULTIQC_QUAST(quast_dirs_collected)


    // ------------------------
    // Ejecutar MLST (a partir de los ensamblados)
    // ------------------------
    mlst_result = spades_result | MLST

    
    // ----------------------------------------------------------------
    // Definición del canal para la base de datos de CheckM2
    // ----------------------------------------------------------------
    checkm2_db_ch = Channel
        .fromPath(params.checkm2_db_file, checkIfExists: true)
        .collect()

    // El resto sigue igual...
    checkm2_input = spades_result.combine(checkm2_db_ch)
    checkm2_results = CHECKM2(checkm2_input)




    // Canal de la DB de Bakta
    ch_bakta_db = Channel.value(true) 

    // Preparar inputs para Bakta
    ch_for_bakta = spades_result.map { tuple ->
        def (sample_id, fasta) = tuple
        return [sample_id, fasta]
    }

    // Ejecutar Bakta
    BAKTA(ch_for_bakta)


    //  JOIN correcto por sample_id
    amrfinder_input = spades_result.join(mlst_result)

    // Ejecutar
    amrfinder_result = amrfinder_input | AMRFINDERPLUS






}