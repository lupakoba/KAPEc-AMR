#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process MULTIQC_FASTQC {

    tag "Joining FastQC reports"

    publishDir "${params.outdir}/multiqc/reads", mode: 'copy'

    container 'quay.io/biocontainers/multiqc:1.33--pyhdfd78af_0'

    cpus 2
    memory '4 GB'

    input:
    path qc_files

    output:
    path "multiqc_report_reads.html"

    script:
    """
    set -euo pipefail

    multiqc . \\
        --outdir . \\
        --filename multiqc_report_reads.html \\
        --force
    """
}