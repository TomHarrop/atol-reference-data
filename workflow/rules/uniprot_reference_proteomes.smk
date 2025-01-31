#!/usr/bin/env python3


def get_uniprot_url(wildcards):
    uniprot_directory_url = config["uniprot_directory_url"]
    filename_pattern = re.compile("^" + config["uniprot_filename_pattern"] + "$")
    listing_file = checkpoints.list_uniprot_directory.get().output.listing
    files = get_files_from_listing_file(listing_file, filename_pattern)
    if len(files) != 1:
        logger.error(files)
        raise ValueError(
            f"Only expecting one file mathcing {filename_pattern} in {uniprot_directory_url}"
        )
    return f"{uniprot_directory_url}/{files[0]}.tar.gz"


rule download_uniprot_file:
    input:
        listing=local("results/uniprot_referece_proteomes/listing.txt"),
    output:
        tarfile=add_bucket_to_path(
            "uniprot_referece_proteomes/reference_proteomes.tar.gz"
        ),
    params:
        file_url=get_uniprot_url,
    container:
        "docker://quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10"
    shadow:
        "minimal"
    shell:
        "wget {params.file_url} -O {output.tarfile}"


checkpoint list_uniprot_directory:
    params:
        uniprot_directory_url=config["uniprot_directory_url"],
    output:
        listing=local("results/uniprot_referece_proteomes/listing.txt"),
    shadow:
        "minimal"
    container:
        "docker://quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10"
    shell:
        "wget --no-remove-listing {params.uniprot_directory_url}/ && "
        "mv .listing {output.listing}"
