#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process SPADES_ASSEMBLY {

    tag "De novo assembly for sample ${sample_id}"

    publishDir "${params.outdir}/spades", mode: 'copy'

    container "staphb/spades:3.15.5"

    cpus 8
    memory '64 GB' 

    input:
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path("${sample_id}.fasta")

    script:
    """
    set -euo pipefail

    # Ejecutar SPAdes
    spades.py \\
        --pe1-1 ${reads[0]} \\
        --pe1-2 ${reads[1]} \\
        -o spades_${sample_id} \\
        --threads ${task.cpus} \\
        --memory ${task.memory.toGiga()} \\
        --isolate \\
        -k auto

    # Filtrar contigs >= 200 bp
    if [ -f spades_${sample_id}/contigs.fasta ]; then
        awk '
        /^>/ {
            if (seqlen >= 200) {
                print header
                print seq
            }
            header = \$0
            seq = ""
            seqlen = 0
            next
        }
        {
            seq = seq \$0
            seqlen += length(\$0)
        }
        END {
            if (seqlen >= 200) {
                print header
                print seq
            }
        }' spades_${sample_id}/contigs.fasta > ${sample_id}.fasta
    else
        echo "Error: contigs.fasta not found for ${sample_id}" >&2
        exit 1
    fi
    """
}