#!/usr/bin/env python3


rule upload_vecscreen_files:
    input:
        "results/vecscreen",
    output:
        to_storage("vecscreen", bucket_name="vecscreen"),
    resources:
        runtime="10",
        storage_uploads=check_concurrent_storage_uploads,
    container:
        "docker://debian:stable-20250113"
    shell:
        "cp -r {input} {output} "


rule vecscreen_makedb:
    input:
        vecscreen="results/vecscreen_files/vecscreen_adaptors_for_screening_euks.fa",
    output:
        directory("results/vecscreen"),
    params:
        wd=lambda wildcards, input: subpath(input.vecscreen, parent=True),
    resources:
        runtime=10,
    log:
        "logs/download_vecscreen_file.log",
    shadow:
        "minimal"
    container:
        "docker://quay.io/biocontainers/blast:2.16.0--h66d330f_5"
    shell:
        "makeblastdb "
        "-in {input.vecscreen} "
        "-parse_seqids "
        "-blastdb_version 4 "
        "-dbtype nucl "
        "&> {log} && "
        "cp -r {params.wd} {output} && "
        "printf $(date -Iseconds) > {output}/TIMESTAMP"


rule download_vecscreen_file:
    output:
        vecscreen=temp(
            "results/vecscreen_files/vecscreen_adaptors_for_screening_euks.fa"
        ),
    params:
        url=config["vecscreen_url"],
    resources:
        runtime=10,
    log:
        "logs/download_vecscreen_file.log",
    shadow:
        "minimal"
    container:
        "docker://quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10"
    shell:
        "wget {params.url} -O {output.vecscreen} &> {log} "
