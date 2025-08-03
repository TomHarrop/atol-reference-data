#!/usr/bin/env python3

from humanfriendly import parse_size


def get_mem(wildcards, resources):
    return int(0.95 * parse_size(resources.mem))


rule kraken2_build_db:
    input:
        taxonomy="results/kraken2_db/taxonomy",
        library="results/kraken2_db/library",
    output:
        to_storage("kraken2_nt/prelim_map.txt", bucket_name="kraken"),
        to_storage("kraken2_nt/unmapped_accessions.txt", bucket_name="kraken"),
        to_storage("kraken2_nt/seqid2taxid.map", bucket_name="kraken"),
        to_storage("kraken2_nt/estimated_capacity", bucket_name="kraken"),
        to_storage("kraken2_nt/taxo.k2d", bucket_name="kraken"),
        to_storage("kraken2_nt/opts.k2d", bucket_name="kraken"),
        to_storage("kraken2_nt/hash.k2d", bucket_name="kraken"),
    log:
        "logs/kraken2_build_db.log",
    params:
        mem_bytes=get_mem,
        db=subpath(output[0], parent=True),
    resources:
        mem="256GB",
        storage_uploads=check_concurrent_storage_uploads,
        runtime=lambda wildcards, attempt: f"{int(attempt*24)}H",
        partitionFlag="--partition highmem",
    threads: 24
    shadow:
        "minimal"
    container:
        "docker://quay.io/biocontainers/kraken2:2.1.6--pl5321h077b44d_0"
    shell:
        "ln -s $(readlink -f {input.taxonomy}) {params.db}/ && "
        "ln -s $(readlink -f {input.library}) {params.db}/ && "
        "k2 build "
        "--threads {threads} "
        "--max-db-size {params.mem_bytes} "
        "--db {params.db} "
        "&> {log} "


# Taking ages, can we do it with add-to-library?
# https://github.com/DerrickWood/kraken2/blob/master/docs/MANUAL.markdown#add-to-library
# First, try switching to k2: https://github.com/DerrickWood/kraken2/wiki/Manual#build
rule kraken2_download_library:
    output:
        library=temp(directory("results/kraken2_db/library")),
    params:
        db=subpath(output.library, parent=True),
    log:
        "logs/kraken2_download_library.log",
    threads: 4
    resources:
        runtime=lambda wildcards, attempt: f"{int(attempt*48)}H",
        partitionFlag="--partition long",
    shadow:
        "minimal"
    container:
        "docker://quay.io/biocontainers/kraken2:2.1.6--pl5321h077b44d_0"
    shell:
        "k2 download-library "
        "--threads {threads} "
        "--library nt "
        "--db {params.db} "
        "&> {log}"


rule kraken2_download_taxonomy:
    output:
        taxonomy=temp(directory("results/kraken2_db/taxonomy")),
    params:
        db=subpath(output.taxonomy, parent=True),
    log:
        "logs/kraken2_download_taxonomy.log",
    threads: 2
    resources:
        runtime=lambda wildcards, attempt: int(attempt * 60),
    container:
        "docker://quay.io/biocontainers/kraken2:2.1.6--pl5321h077b44d_0"
    shell:
        "k2 download-taxonomy "
        "--db {params.db} "
        "&> {log}"
