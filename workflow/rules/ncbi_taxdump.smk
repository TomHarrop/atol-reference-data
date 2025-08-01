#!/usr/bin/env python3


rule ncbi_taxdump:
    input:
        taxdump=storage.ftp(config["taxdump_url"]),
    output:
        to_storage("taxdump/citations.dmp", bucket_name="ncbi"),
        to_storage("taxdump/delnodes.dmp", bucket_name="ncbi"),
        to_storage("taxdump/division.dmp", bucket_name="ncbi"),
        to_storage("taxdump/excludedfromtype.dmp", bucket_name="ncbi"),
        to_storage("taxdump/fullnamelineage.dmp", bucket_name="ncbi"),
        to_storage("taxdump/gencode.dmp", bucket_name="ncbi"),
        to_storage("taxdump/host.dmp", bucket_name="ncbi"),
        to_storage("taxdump/images.dmp", bucket_name="ncbi"),
        to_storage("taxdump/merged.dmp", bucket_name="ncbi"),
        to_storage("taxdump/names.dmp", bucket_name="ncbi"),
        to_storage("taxdump/nodes.dmp", bucket_name="ncbi"),
        to_storage("taxdump/rankedlineage.dmp", bucket_name="ncbi"),
        to_storage("taxdump/taxidlineage.dmp", bucket_name="ncbi"),
        to_storage("taxdump/typematerial.dmp", bucket_name="ncbi"),
        to_storage("taxdump/typeoftype.dmp", bucket_name="ncbi"),
        timestamp=to_storage("taxdump/TIMESTAMP", bucket_name="ncbi"),
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
