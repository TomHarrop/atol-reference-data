#!/usr/bin/env python3


def get_uniprot_url(wildcards):
    uniprot_directory_url = config["uniprot_directory_url"]
    filename_pattern = re.compile("^" + config["uniprot_filename_pattern"] + "$")
    listing_file = checkpoints.list_uniprot_directory.get().output.listing
    files = get_files_from_listing_file(listing_file, filename_pattern)
    if len(files) != 1:
        logger.error(files)
        raise ValueError(
            f"Only expecting one file matching {filename_pattern} in {uniprot_directory_url}"
        )
    return f"{uniprot_directory_url}/{files[0]}.tar.gz"


rule download_uniprot_file:
    input:
        listing="results/uniprot_referece_proteomes/listing.txt",
    output:
        tarfile=to_storage("uniprot_referece_proteomes/reference_proteomes.tar.gz"),
    params:
        file_url=get_uniprot_url,
    resources:
        runtime=60,
    log:
        "logs/download_uniprot_file.log",
    shadow:
        "minimal"
    container:
        "docker://quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10"
    shell:
        "wget {params.file_url} -O {output.tarfile} &> {log}"


checkpoint list_uniprot_directory:
    params:
        uniprot_directory_url=config["uniprot_directory_url"],
    output:
        listing="results/uniprot_referece_proteomes/listing.txt",
    log:
        "logs/list_uniprot_directory.log",
    shadow:
        "minimal"
    container:
        "docker://quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10"
    shell:
        "wget --no-remove-listing {params.uniprot_directory_url}/ &> {log} && "
        "mv .listing {output.listing}"
