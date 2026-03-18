#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process multiqc {

    container 'quay.io/biocontainers/multiqc:1.33--pyhdfd78af_0'

    publishDir "results/multiqc", mode: 'copy'

    input:
    path qc_files

    output:
    path "multiqc_report.html"

    script:
    """
    multiqc ${qc_files.join(' ')} -o .
    """
}