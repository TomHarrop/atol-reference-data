#!/usr/bin/env python3

def taxdump_urls(wildcards):
    file_url = config["taxdump_url"]
    return (file_url, Path(file_url).name)


rule ncbi_taxdump:
    input:
        taxdump="results/taxdump_files/new_taxdump.tar.gz"
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


rule download_taxdump_file:
    output:
        taxdump=temp(
            "results/taxdump_files/new_taxdump.tar.gz"
        ),
    params:
        params=taxdump_urls 
    resources:
        runtime=60,
    log:
        "logs/download_taxdump_file.log",
    shadow:
        "minimal"
    container:
        "docker://quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10"
    shell:
        "wget {params.params[0]} -O {params.params[1]} &> {log} && "
        "wget {params.params[0]}.md5 -O {params.params[1]}.md5 &>> {log} && "
        "md5sum -c {params.params[1]}.md5 &>> {log} && "
        "mv {params.params[1]} {output.taxdump}"
