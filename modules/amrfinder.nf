#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process AMRFINDERPLUS {

    tag "AMRFinderPlus: ${sample_id}"

    container "${params.amrfinder_container}"

    publishDir "${params.outdir}/amrfinderplus", mode: 'copy'

    cpus 4
    memory '32 GB'

    input:
    tuple val(sample_id), path(assembly), path(mlst_result)

    output:
    tuple val(sample_id), path("${sample_id}_amrfinder.tsv")

    script:
    """
    set -euo pipefail

    # Extraer organismo desde MLST
    organism=\$(head -n1 ${mlst_result} | cut -f2 | sed 's/_/ /g' | tr '[:upper:]' '[:lower:]')

    echo "Detected organism: \$organism"

    # 🔥 Normalización robusta MLST → AMRFinder
    case "\$organism" in
        *ecoli*)
            genus="Escherichia"
            ;;
        *klebsiella*|*kpneumoniae*)
            genus="Klebsiella_pneumoniae"
            ;;
        *abaumannii*|*acinetobacter*)
            genus="Acinetobacter_baumannii"
            ;;
        *pseudomonas*|*paeruginosa*)
            genus="Pseudomonas_aeruginosa"
            ;;
        *)
            # fallback seguro: tomar la primera palabra
            genus=\$(echo "\$organism" | cut -d ' ' -f1)
            ;;
    esac

    # Validar que el género sea reconocido por AMRFinder
    case "\$genus" in
        Escherichia|Klebsiella_pneumoniae|Acinetobacter_baumannii|Pseudomonas_aeruginosa)
            org_flag="--organism \$genus"
            ;;
        *)
            echo "WARNING: Unknown genus '\$genus' → running without --organism flag"
            org_flag=""
            ;;
    esac

    echo "Normalized genus: \$genus"
    echo "Using org_flag: \$org_flag"

    # Ejecutar AMRFinderPlus
    amrfinder \\
        --nucleotide ${assembly} \\
        \$org_flag \\
        --threads ${task.cpus} \\
        --output ${sample_id}_amrfinder.tsv
    """
}