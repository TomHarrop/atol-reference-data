#!/usr/bin/env python3

from humanfriendly import parse_size


def get_mem(wildcards, resources):
    return int(0.95 * parse_size(resources.mem))


rule kraken2_build_db:
    input:
        taxonomy="results/kraken2_db/taxonomy",
        library="results/kraken2_db/library",
    output:
        flagfile="results/kraken2_db/flagfile",
    log:
        "logs/kraken2_build_db.log",
    params:
        mem_bytes=get_mem,
        db=subpath(input.library, parent=True),
    resources:
        mem="256GB",
        storage_uploads=check_concurrent_storage_uploads,
        runtime=lambda wildcards, attempt: f"{int(attempt*24)}H",
        partitionFlag="--partition highmem",
    threads: 24
    shadow:
        "minimal"
    container:
        "docker://quay.io/biocontainers/kraken2:2.14--pl5321h077b44d_0"
    shell:
        "ls -lhrt {params.db}/ && "
        "k2 build "
        "--threads {threads} "
        "--max-db-size {params.mem_bytes} "
        "--db {params.db} "
        "&> {log}"
        "&& touch {output.flagfile} "
        "&& ls -lhrt {params.db}/"


# Taking ages, can we do it with add-to-library?
# https://github.com/DerrickWood/kraken2/blob/master/docs/MANUAL.markdown#add-to-library
# First, try switching to k2: https://github.com/DerrickWood/kraken2/wiki/Manual#build
rule kraken2_download_library:
    output:
        library=directory("results/kraken2_db/library"),
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
        "docker://quay.io/biocontainers/kraken2:2.14--pl5321h077b44d_0"
    shell:
        "k2 download-library "
        "--threads {threads} "
        "--library nt "
        "--db {params.db} "
        "&> {log}"


rule kraken2_download_taxonomy:
    output:
        taxonomy=directory("results/kraken2_db/taxonomy"),
    params:
        db=subpath(output.taxonomy, parent=True),
    log:
        "logs/kraken2_download_taxonomy.log",
    threads: 2
    resources:
        runtime=lambda wildcards, attempt: int(attempt * 60),
    container:
        "docker://quay.io/biocontainers/kraken2:2.14--pl5321h077b44d_0"
    shell:
        "k2 download-taxonomy "
        "--db {params.db} "
        "&> {log}"
