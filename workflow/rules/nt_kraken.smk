#!/usr/bin/env python3


rule kraken2_db:
    input:
        taxonomy="results/kraken2_db/taxonomy",
        library="results/kraken2_db/library",
    output:
        to_storage("kraken2_db"),
    params:
        db=subpath(input.library, parent=True),
    resources:
        mem="128GB",
        storage_uploads=check_concurrent_storage_uploads,
        runtime=lambda wildcards, attempt: int(attempt * 120),
    threads: 24
    shadow:
        "minimal"
    container:
        "docker://quay.io/biocontainers/kraken2:2.14--pl5321h077b44d_0"
    shell:
        "ls -lhrt {params.db} "
        "&&"
        "k2 build "
        "--threads {threads} "
        "--db {params.db} "
        "&& "
        "ls -lhrt {params.db} "


# Taking ages, can we do it with add-to-library?
# https://github.com/DerrickWood/kraken2/blob/master/docs/MANUAL.markdown#add-to-library
# First, try switching to k2: https://github.com/DerrickWood/kraken2/wiki/Manual#build
rule kraken2_download_library:
    output:
        library=directory("results/kraken2_db/library"),
    params:
        db=subpath(output.library, parent=True),
    threads: 4
    resources:
        runtime=lambda wildcards, attempt: f"{int(attempt*10)}H",
    container:
        "docker://quay.io/biocontainers/kraken2:2.14--pl5321h077b44d_0"
    shell:
        "k2 download-library "
        "--threads {threads} "
        "--library nt "
        "--db {params.db}"


rule kraken2_download_taxonomy:
    output:
        taxonomy=directory("results/kraken2_db/taxonomy"),
    params:
        db=subpath(output.taxonomy, parent=True),
    threads: 2
    resources:
        runtime=lambda wildcards, attempt: int(attempt * 60),
    container:
        "docker://quay.io/biocontainers/kraken2:2.14--pl5321h077b44d_0"
    shell:
        "k2 download-taxonomy "
        "--db {params.db}"
