#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// ------------------------
// Incluir el módulo FastQC
// ------------------------
include { fastqc_analysis_1 } from './modules/fastqc_1.nf'

// ------------------------
// Workflow principal
// ------------------------
workflow {

    // Canal de todos los FASTQ
    reads_ch = channel.fromPath(params.input ?: 'data/*.fastq.gz')

    // Llamar al proceso FastQC
    fastqc_result = fastqc_analysis_1(reads_ch)

    // Si quieres usar los outputs
    fastqc_html_files = fastqc_result.fastqc_html
    fastqc_zip_files  = fastqc_result.fastqc_zip
}