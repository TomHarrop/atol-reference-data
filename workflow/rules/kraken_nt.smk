#!/usr/bin/env python3


kraken_core_nt_filename = subpath(kraken_core_nt_db_url, basename=True)


rule upload_kraken_nt_db:
    input:
        "results/k2_core_nt",
    output:
        to_storage("k2_core_nt", bucket_name="kraken"),
    resources:
        runtime="1d",
        storage_uploads=check_concurrent_storage_uploads,
    container:
        "docker://debian:stable-20250113"
    shell:
        "cp -r {input} {output} "


rule expand_kraken_nt_db:
    input:
        tarfile="results/k2_core_nt.tar.gz",
    output:
        database_directory=temp(directory("results/k2_core_nt")),
    log:
        "logs/expand_kraken_nt_db.log",
    threads: 2
    resources:
        runtime="12h",
    shadow:
        "minimal"
    container:
        "docker://quay.io/biocontainers/kraken2:2.1.6--pl5321h077b44d_0"
    shell:
        "mkdir -p {output.database_directory} && "
        "gzip -dc {input.tarfile} | tar -xv -C {output.database_directory} "
        "2> {log} && "
        "printf $(date -Iseconds) > {output.database_directory}/TIMESTAMP && "
        "printf '%s\\n' {kraken_core_nt_db_url} > {output.database_directory}/URL && "
        "k2 inspect "
        "{output.database_directory} "
        "--output {output.database_directory}/INSPECT.txt "
        "2>> {log} "


rule download_kraken_nt_db:
    output:
        tarfile=temp("results/k2_core_nt.tar.gz"),
    params:
        url=kraken_core_nt_db_url,
        checksum=kraken_core_nt_db_checksum,
    log:
        "logs/download_kraken_nt_db.log",
    resources:
        runtime="1d",
        # partitionFlag="--partition long",
    shadow:
        "minimal"
    container:
        "docker://quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10"
    shell:
        "wget {params.url} -O {kraken_core_nt_filename} &> {log} && "
        "wget {params.checksum} -O {kraken_core_nt_filename}.md5 &>> {log} && "
        'grep "{kraken_core_nt_filename}" {kraken_core_nt_filename}.md5 '
        "| md5sum -c - &>> {log} && "
        "mv {kraken_core_nt_filename} {output.tarfile}"
