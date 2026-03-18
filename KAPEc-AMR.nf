#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// ------------------------
// Incluir módulos
// ------------------------
include { fastqc_raw } from './modules/fastqc_raw.nf'
include { fastqc_trimmed } from './modules/fastqc_trimmed.nf'
include { fastp_trim } from './modules/fastp.nf'
include { multiqc } from './modules/multiqc.nf'

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

Input    : ${params.input}
Profile  : ${workflow.profile}
Run name : ${workflow.runName}
Started  : ${workflow.start}
"""

    // Canal por muestra (R1 + R2)
    read_ch = channel.fromFilePairs(params.input ?: 'data/*_{R1,R2}.fastq.gz', size: 2)

    // FastQC raw
    fastqc_raw_result = fastqc_raw(read_ch)

    // Trimming con fastp
    fastp_result = fastp_trim(read_ch)

    // FastQC post-trim
    fastqc_trimmed_result = fastqc_trimmed(fastp_result.trimmed_reads)

    // Preparar archivos para MultiQC
    multiqc_input = fastqc_raw_result.fastqc_zip
        .mix(fastqc_trimmed_result.fastqc_zip)
        .collect()   // <-- agrupa todo en un solo canal

    // Ejecutar MultiQC
    multiqc(multiqc_input)
}