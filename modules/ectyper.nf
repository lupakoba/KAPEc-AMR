process ECTYPER {

    tag "Serotyping for genome ${sample_id}"

    container "${params.ectyper_container}"
    publishDir "${params.outdir}/ectyper", mode: 'copy'

    input:
    tuple val(sample_id), path(assembly), path(mlst_tsv)

    output:
    tuple val(sample_id), path("${sample_id}_ectyper.tsv"), emit: ectyper
    path "${sample_id}_species_not_supported.txt", optional: true

    script:
    """
    set -euo pipefail

    # 1. Extraer especie y limpiar
    species_raw=\$(head -n1 ${mlst_tsv} | cut -f2 | tr '[:upper:]' '[:lower:]')
    species_clean=\$(echo "\$species_raw" | sed 's/[^a-z]//g')

    # 2. Lógica de ejecución
    if [[ "\$species_clean" == *"escherichia"* || "\$species_clean" == *"ecoli"* ]]; then
        echo "Running ECTyper for Escherichia coli..."

        ectyper \\
            -i ${assembly} \\
            -o ${sample_id}_ectyper.tsv

    else
        echo "Species \$species_raw not supported by ECTyper (only E. coli)." > ${sample_id}_species_not_supported.txt
        
        # Crear output vacío para mantener consistencia del canal
        touch "${sample_id}_ectyper.tsv"
    fi
    """
}