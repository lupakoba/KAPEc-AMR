process PASTY {

    tag "Serotyping for genome ${sample_id}"

    container "${params.pasty_container}"
    publishDir "${params.outdir}/pasty", mode: 'copy'

    input:
    tuple val(sample_id), path(assembly), path(mlst_tsv)

    output:
    tuple val(sample_id), path("${sample_id}_pasty.tsv"), emit: pasty
    path "${sample_id}_species_not_supported.txt", optional: true

    script:
    """
    set -euo pipefail

    species_raw=\$(head -n1 ${mlst_tsv} | cut -f2 | tr '[:upper:]' '[:lower:]')
    species_clean=\$(echo "\$species_raw" | sed 's/[^a-z]//g')

    if [[ "\$species_clean" == *"pseudomonas"* || "\$species_clean" == *"aeruginosa"* ]]; then
        echo "Running Pasty for Pseudomonas aeruginosa..."

        pasty \\
            --input ${assembly} \\
            --outdir pasty_out

        # 🔹 buscar TSV generado
        TSV_FILE=\$(find pasty_out -name "*.tsv" | head -n1)

        if [[ -f "\$TSV_FILE" ]]; then
            cp "\$TSV_FILE" "${sample_id}_pasty.tsv"
        else
            echo "No TSV output found from Pasty" > "${sample_id}_pasty.tsv"
        fi

    else
        echo "Species \$species_raw not supported by Pasty (only P. aeruginosa)." > ${sample_id}_species_not_supported.txt
        touch "${sample_id}_pasty.tsv"
    fi
    """
}