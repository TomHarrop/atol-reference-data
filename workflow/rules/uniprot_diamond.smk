#!/usr/bin/env python3


rule diamond_makedb:
    input:
        taxid_map="results/diamond/reference_proteomes.taxid_map",
        sequences="results/diamond/reference_proteomes.fasta.gz",
        nodes=to_storage("taxdump/nodes.dmp", bucket_name="ncbi"),
        names=to_storage("taxdump/names.dmp", bucket_name="ncbi"),
    output:
        dmnd=to_storage(
            "diamond/reference_proteomes.dmnd", bucket_name="uniprot_diamond"
        ),
    log:
        "logs/diamond_makedb.log",
    threads: 24
    resources:
        storage_uploads=check_concurrent_storage_uploads,
        runtime=lambda wildcards, attempt: int(attempt * 60),
        mem=lambda wildcards, attempt: f"{int(128)* attempt}GB",
    shadow:
        "minimal"
    container:
        "docker://quay.io/biocontainers/diamond:2.1.13--h13889ed_0"
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
    resources:
        runtime=lambda wildcards, attempt: int(attempt * 120),
    shadow:
        "minimal"
    container:
        "docker://quay.io/biocontainers/diamond:2.1.13--h13889ed_0"
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
    resources:
        runtime=lambda wildcards, attempt: int(attempt * 60),
    shadow:
        "minimal"
    container:
        "docker://quay.io/biocontainers/diamond:2.1.13--h13889ed_0"
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
