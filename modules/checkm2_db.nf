#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process CHECKM2_DB {
    tag "Downloading CheckM2 DB"
    container "${params.checkm2_container}"
    
    output:
    path "CheckM2_database", emit: db_dir

    script:
    """
    checkm2 database --download --path .
    """
}