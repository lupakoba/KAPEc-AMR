#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process MOB_RECON {

    tag "Plasmid inference for genome ${sample_id}"

    container 'docker://quay.io/biocontainers/mob_suite:3.1.9--pyhdfd78af_1'

    publishDir "${params.outdir}/mob_recon", mode: 'copy'

    cpus 4
    memory '16 GB'

    input:
    tuple val(sample_id), path(assembly)

    output:
    tuple val(sample_id), path("${sample_id}_mob_recon")

    script:
    """
    mob_recon -i ${assembly} -o ${sample_id}_mob_recon -n ${task.cpus}
    """
}