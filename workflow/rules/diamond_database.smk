#!/usr/bin/env python3

# TODO delete the head commands which make this run on a subset


rule diamond_makedb:
    input:
        taxid_map="results/diamond/reference_proteomes.taxid_map",
        sequences="results/diamond/reference_proteomes.fasta.gz",
        nodes=to_storage("taxdump/nodes.dmp"),
    output:
        dmnd=to_storage("diamond/reference_proteomes.dmnd"),
    log:
        "logs/diamond_get_taxid_map.log",
    threads: 24
    resources:
        storage_uploads=check_concurrent_storage_uploads,
    shadow:
        "minimal"
    container:
        "docker://quay.io/biocontainers/diamond:2.1.11--h5ca1c30_1"
    shell:
        "diamond makedb "
        "-p {threads} "
        "--in {input.sequences} "
        "--taxonmap {input.taxid_map} "
        "--taxonnodes {input.nodes} "
        "-d {output.dmnd} "
        "2>> {log} "


rule diamond_get_taxid_map:
    input:
        database_directory="results/uniprot_reference_proteomes",
    output:
        taxid_map="results/diamond/reference_proteomes.taxid_map",
    log:
        "logs/diamond_get_taxid_map.log",
    shadow:
        "minimal"
    container:
        "docker://quay.io/biocontainers/diamond:2.1.11--h5ca1c30_1"
    shell:
        'echo -e "accession\\taccession.version\\ttaxid\\tgi" > {output.taxid_map} '
        "&& "
        "find {input.database_directory}/ "
        "-name '*.idmapping.gz' "
        "2>> {log} "
        "| "
        "xargs zcat "
        "2>> {log} "
        "| "
        'grep "NCBI_TaxID" '
        "2>> {log} "
        "| "
        'awk \'{{print $1 "\\t" $1 "\\t" $3 "\\t" 0}}\' '
        ">> {output.taxid_map} "
        "2>> {log} "


rule diamond_get_sequences:
    input:
        database_directory="results/uniprot_reference_proteomes",
    output:
        sequences="results/diamond/reference_proteomes.fasta.gz",
    log:
        "logs/diamond_get_sequences.log",
    shadow:
        "minimal"
    container:
        "docker://quay.io/biocontainers/diamond:2.1.11--h5ca1c30_1"
    shell:
        "touch {output.sequences} "
        "&& "
        "find {input.database_directory}/ "
        "-mindepth 2  "
        "-name '*.fasta.gz*' "
        "2>> {log} "
        "| "
        'grep -v "DNA" '
        "2>> {log} "
        "| "
        'grep -v "additional" '
        "2>> {log} "
        "|  xargs cat "
        ">> {output.sequences} "
        "2>> {log} "
