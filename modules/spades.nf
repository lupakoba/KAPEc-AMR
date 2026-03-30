process SPADES_ASSEMBLY {

    tag "${sample_id}"

    // Directorio de resultados
    publishDir "${params.outdir}/spades", mode: 'copy'

    container "staphb/spades:3.15.5"

    input:
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path("${sample_id}.fasta")

    script:
    """
    spades.py \\
        --pe1-1 ${reads[0]} \\
        --pe1-2 ${reads[1]} \\
        -o spades_${sample_id} \\
        --threads ${task.cpus} \\
        --memory 64 \\
        --isolate \\
        -k auto

    # Renombrar contigs para downstream
    cp spades_${sample_id}/contigs.fasta ${sample_id}.fasta
    """
}