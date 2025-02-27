#!/usr/bin/env python3


rule ncbi_taxdump:
    input:
        taxdump=storage.ftp(config["taxdump_url"]),
    output:
        to_storage("taxdump/citations.dmp"),
        to_storage("taxdump/delnodes.dmp"),
        to_storage("taxdump/division.dmp"),
        to_storage("taxdump/excludedfromtype.dmp"),
        to_storage("taxdump/fullnamelineage.dmp"),
        to_storage("taxdump/gencode.dmp"),
        to_storage("taxdump/host.dmp"),
        to_storage("taxdump/images.dmp"),
        to_storage("taxdump/merged.dmp"),
        to_storage("taxdump/names.dmp"),
        to_storage("taxdump/nodes.dmp"),
        to_storage("taxdump/rankedlineage.dmp"),
        to_storage("taxdump/taxidlineage.dmp"),
        to_storage("taxdump/typematerial.dmp"),
        to_storage("taxdump/typeoftype.dmp"),
        timestamp=to_storage("taxdump/TIMESTAMP"),
    params:
        outdir=lambda wildcards, output: Path(output[0]).parent,
    resources:
        storage_uploads=check_concurrent_storage_uploads,
    container:
        "docker://debian:stable-20250113"
    shell:
        "mkdir -p {params.outdir} && "
        "tar -xzf {input.taxdump} -C {params.outdir} && "
        "printf $(date -Iseconds) > {output.timestamp}"
