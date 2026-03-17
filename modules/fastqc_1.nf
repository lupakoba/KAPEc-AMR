#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// ------------------------
// Proceso FastQC reusable
// ------------------------
process fastqc_analysis_1 {

    container 'biocontainers/fastqc:v0.11.9_cv8'

    // Publicar resultados
    publishDir "results/fastqc", mode: 'copy'

    input:
    path reads

    output:
    path "*.html", emit: fastqc_html
    path "*.zip", emit: fastqc_zip

    script:
    """
    fastqc $reads
    """
}