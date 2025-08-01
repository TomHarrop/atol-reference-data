#!/usr/bin/env python3


def get_list_of_blast_nt_files(wildcards):
    listing_file = checkpoints.list_blast_db_directory.get(**wildcards).output.listing
    logger.warning(f"listing_file: {listing_file}")
    filename_pattern = re.compile("^" + config["nt_filename_pattern"] + "$")
    files = get_files_from_listing_file(listing_file, filename_pattern)
    file_list = expand(
        "results/ncbi_nucleotide_blast_files/{filename}.tar.gz",
        filename=files,
    )
    return file_list


rule upload_blast_db_files:
    input:
        "results/ncbi_nucleotide_blast",
    output:
        to_storage("ncbi_nucleotide_blast", bucket_name="ncbi"),
    resources:
        runtime="12h",
        storage_uploads=check_concurrent_storage_uploads,
    container:
        "docker://debian:stable-20250113"
    shell:
        "cp -r {input} {output}"


rule expand_blast_db_files:
    input:
        tarfiles=get_list_of_blast_nt_files,
    output:
        database_directory=temp(directory("results/ncbi_nucleotide_blast")),
    threads: 12
    resources:
        runtime=60,
    shadow:
        "minimal"
    container:
        "docker://debian:stable-20250113"
    shell:
        "mkdir -p {output.database_directory} && "
        "find {input.tarfiles} | "
        "xargs --max-procs={threads} "
        "-I{{}} tar zxf {{}} -C {output.database_directory} && "
        "printf $(date -Iseconds) > {output.database_directory}/TIMESTAMP"


rule download_blast_db_file:
    input:
        listing="results/ncbi_nucleotide_blast_files/listing.txt",
    output:
        tarfile=temp("results/ncbi_nucleotide_blast_files/{filename}.tar.gz"),
    params:
        file_url=lambda wildcards: f"{config['blast_db_directory_url']}/{wildcards.filename}.tar.gz",
        md5_url=lambda wildcards: f"{config['blast_db_directory_url']}/{wildcards.filename}.tar.gz.md5",
    log:
        "logs/download_blast_db_file/{filename}.log",
    resources:
        runtime=lambda wildcards, attempt: (
            int(attempt * 30) if wildcards.filename == "nt.000" else int(attempt * 10)
        ),
    shadow:
        "minimal"
    container:
        "docker://quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10"
    shell:
        "wget {params.file_url} -O {wildcards.filename}.tar.gz &> {log} && "
        "wget {params.md5_url} -O {wildcards.filename}.tar.gz.md5 &>> {log} && "
        "cat {wildcards.filename}.tar.gz.md5 &>> {log} && "
        "md5sum -c {wildcards.filename}.tar.gz.md5 &>> {log} && "
        "mv {wildcards.filename}.tar.gz {output.tarfile}"


checkpoint list_blast_db_directory:
    params:
        blast_db_directory_url=config["blast_db_directory_url"],
    output:
        listing="results/ncbi_nucleotide_blast_files/listing.txt",
    log:
        "logs/list_blast_db_directory.log",
    shadow:
        "minimal"
    container:
        "docker://quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10"
    shell:
        "wget --no-remove-listing {params.blast_db_directory_url}/ &> {log} && "
        "mv .listing {output.listing}"
