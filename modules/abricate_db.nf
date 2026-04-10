#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process ABRICATE_DB {

    tag "Preparing ABRICATE database"

    container "${params.abricate_container}"

    cpus 4
    memory '16 GB'

    output:
    path "abricate_db", emit: db

    script:
    """
    export ABRICATE_DB=\$PWD/abricate_db

    mkdir -p \$ABRICATE_DB

    # Solo descarga si no existe VFDB
    if [ ! -d "\$ABRICATE_DB/vfdb" ]; then
        abricate --setupdb
    fi
    """
}