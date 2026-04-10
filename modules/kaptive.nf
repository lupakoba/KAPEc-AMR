process KAPTIVE {
    tag "Capsular Loci inference for genome ${sample_id}"
    
    // Asegúrate de que esta imagen sea la que tiene el comando 'kaptive'
    container "${params.kaptive_container}"
    publishDir "${params.outdir}/kaptive", mode: 'copy'

    input:
    tuple val(sample_id), path(assembly), path(mlst_tsv)
    path(gbk_files)

    output:
    tuple val(sample_id), path("${sample_id}_kaptive_kl.tsv"),  emit: kaptive_kl
    tuple val(sample_id), path("${sample_id}_kaptive_ocl.tsv"), emit: kaptive_ocl
    path "${sample_id}_species_not_supported.txt", optional: true

    script:
    """
    set -euo pipefail

    # 1. Extraer especie y limpiar (ej: "K. pneumoniae" -> "klebsiellapneumoniae")
    species_raw=\$(head -n1 ${mlst_tsv} | cut -f2 | tr '[:upper:]' '[:lower:]')
    species_clean=\$(echo "\$species_raw" | sed 's/[^a-z]//g')

    # 2. Lógica de ejecución por especie
    if [[ "\$species_clean" == *"acinetobacter"* || "\$species_clean" == *"abaumannii"* ]]; then
        echo "Running Kaptive for Acinetobacter..."
        
        # Grep específico para Acinetobacter
        K_DB=\$(ls *.gbk | grep -i "Acinetobacter" | grep -i "k_locus" | head -n1)
        OC_DB=\$(ls *.gbk | grep -i "Acinetobacter" | grep -i "OC_locus" | head -n1)

        kaptive assembly "\$K_DB" "${assembly}" -o "${sample_id}_kaptive_kl.tsv"
        kaptive assembly "\$OC_DB" "${assembly}" -o "${sample_id}_kaptive_ocl.tsv"

    elif [[ "\$species_clean" == *"klebsiella"* || "\$species_clean" == *"pneumoniae"* ]]; then
        echo "Running Kaptive for Klebsiella..."
        
        # Grep específico para Klebsiella
        K_DB=\$(ls *.gbk | grep -i "Klebsiella" | grep -i "k_locus" | head -n1)
        # Usamos grep -v para evitar el k_locus y agarrar el o_locus/v_locus
        O_DB=\$(ls *.gbk | grep -i "Klebsiella" | grep -v -i "k_locus" | head -n1)

        kaptive assembly "\$K_DB" "${assembly}" -o "${sample_id}_kaptive_kl.tsv"
        kaptive assembly "\$O_DB" "${assembly}" -o "${sample_id}_kaptive_ocl.tsv"

    else
        echo "Species \$species_raw not supported by Kaptive (only Acinetobacter and Klebsiella)." > ${sample_id}_species_not_supported.txt
        touch "${sample_id}_kaptive_kl.tsv"
        touch "${sample_id}_kaptive_ocl.tsv"
    fi
    """
}