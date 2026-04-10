#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process ABRICATE_VF {

    tag "Prediction of virulence factors for genome ${sample_id}"

    container "${params.abricate_container}"

    publishDir "${params.outdir}/abricate_vfdb", mode: 'copy'

    cpus 4
    memory '16 GB'

    input:
    tuple val(sample_id), path(assembly), path(db)

    output:
    tuple val(sample_id), path("${sample_id}_vfdb.tab"), emit: vfdb_hits
    tuple val(sample_id), path("${sample_id}_vfdb.summary.txt"), emit: summary
    path "versions.yml", emit: versions

    script:
    """
    export ABRICATE_DB=${db}

    abricate \
        --db vfdb \
        --minid 90 \
        --mincov 70 \
        --threads ${task.cpus} \
        ${assembly} > ${sample_id}_vfdb.tab

    abricate --summary ${sample_id}_vfdb.tab > ${sample_id}_vfdb.summary.txt

    cat <<-END_VERSIONS > versions.yml
    "ABRICATE":
        abricate: \$(abricate --version 2>&1)
    END_VERSIONS
    """
}