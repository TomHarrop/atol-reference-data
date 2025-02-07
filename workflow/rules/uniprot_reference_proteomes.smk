#!/usr/bin/env python3


def get_uniprot_url(wildcards, input):
    uniprot_directory_url = config["uniprot_directory_url"]
    filename_pattern = re.compile("^" + config["uniprot_filename_pattern"] + "$")
    listing_file = input.listing
    files = get_files_from_listing_file(listing_file, filename_pattern)
    if len(files) != 1:
        logger.error(files)
        raise ValueError(
            f"Only expecting one file matching {filename_pattern} in {uniprot_directory_url}"
        )
    return f"{uniprot_directory_url}/{files[0]}.tar.gz"


# rule upload_uniprot_files:
#     input:
#         "results/uniprot_reference_proteomes",
#     output:
#         to_storage("uniprot_reference_proteomes"),
#     resources:
#         runtime=40,
#     container:
#         "docker://debian:stable-20250113"
#     shell:
#         "cp -r {input} {output}"


rule expand_uniprot_file:
    input:
        tarfile="results/uniprot_reference_proteome_files/reference_proteomes.tar.gz",
    output:
        database_directory=to_storage(directory("uniprot_reference_proteomes")),
    threads: 2
    resources:
        runtime=60,
    shadow:
        "minimal"
    container:
        "docker://quay.io/biocontainers/pigz:2.8"
    shell:
        "mkdir -p {output.database_directory} && "
        "pigz -p {threads} -dc {input.tarfile} | tar -xv -C {output.database_directory} && "
        "printf $(date -Iseconds) > {output.database_directory}/TIMESTAMP"


rule download_uniprot_file:
    input:
        listing="results/uniprot_reference_proteome_files/listing.txt",
    output:
        tarfile=temp(
            "results/uniprot_reference_proteome_files/reference_proteomes.tar.gz"
        ),
    params:
        file_url=get_uniprot_url,
    resources:
        runtime=400,
    log:
        "logs/download_uniprot_file.log",
    shadow:
        "minimal"
    container:
        "docker://quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10"
    shell:
        "wget {params.file_url} -O {output.tarfile} &> {log}"


rule list_uniprot_directory:
    params:
        uniprot_directory_url=config["uniprot_directory_url"],
    output:
        listing="results/uniprot_reference_proteome_files/listing.txt",
    log:
        "logs/list_uniprot_directory.log",
    shadow:
        "minimal"
    container:
        "docker://quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10"
    shell:
        "wget --no-remove-listing {params.uniprot_directory_url}/ &> {log} && "
        "mv .listing {output.listing}"
