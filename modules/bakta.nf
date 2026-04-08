#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process BAKTA {
    tag "$sample_id"
    container "${params.bakta_container}"
    publishDir "${params.outdir}/bakta", mode: 'copy'

    // Mantengo tus recursos, 64GB es excelente para evitar cuellos de botella por RAM
    cpus 4
    memory '64 GB'

    input:
    tuple val(sample_id), path(fasta)

    output:
    // He ajustado el glob de salida para que sea más robusto
    tuple val(sample_id), path("${sample_id}/"), emit: results
    tuple val(sample_id), path("${sample_id}/${sample_id}.gff3"), emit: gff
    path "versions.yml", emit: versions

    script:
    """
    # 1. Crear un directorio temporal local al proceso
    mkdir -p tmp_bakta

    # 2. Exportar variables para forzar a Bakta y tRNAscan-SE a usar este espacio
    export TMPDIR=\$PWD/tmp_bakta
    export TMP=\$PWD/tmp_bakta
    export TEMP=\$PWD/tmp_bakta
    export MPLCONFIGDIR=.

    # 3. Ejecución de Bakta
    bakta \\
        --db /db \\
        --output $sample_id \\
        --prefix $sample_id \\
        --threads $task.cpus \\
        --tmp-dir \$PWD/tmp_bakta \\
        --skip-plot \\
        $fasta

    # 4. Registro de versiones
    cat <<-END_VERSIONS > versions.yml
    "BAKTA":
        bakta: \$(bakta --version 2>&1 | sed 's/^bakta //')
    END_VERSIONS
    """
}