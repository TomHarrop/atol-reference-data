#!/usr/bin/env python3

busco_bucket = "busco"


def check_concurrent_busco_downloads(wildcards):
    """
    The BUSCO server returns 503 if you hit it with a lot of parallel
    downloads. This arbitrary resource limits the number of concurrent
    downloads. Set the maximum in the profile, e.g.

    resources:
     - concurrent_busco_downloads=5

    """

    if "concurrent_busco_downloads" not in workflow.resource_settings.resources:
        logger.error(workflow.resource_settings.resources)
        raise ValueError(
            "You must set the number of concurrent_busco_downloads in the profile or on the command line"
        )

    return 1


def get_list_of_datasets(busco_dataset_names):
    with open(busco_dataset_names, "rt") as f:
        return list(x.strip() for x in f)


def get_busco_databases_target(wildcards):
    dataset_names = get_list_of_datasets(busco_dataset_names)
    return list(
        to_storage(
            f"busco/lineages/{x}_{busco_dataset_version}", bucket_name=busco_bucket
        )
        for x in dataset_names
    )


def get_busco_manifest_url(wildcards):
    return f"{config['busco_directory_url']}/{config['busco_manifest_path']}"


def get_lineage_hash(wildcards):
    manifest = get_my_manifest(wildcards)
    return manifest["hash"]


def get_lineage_url(wildcards):
    # e.g.
    # https://busco-data.ezlab.org/v5/data/lineages/vertebrata_odb10.2024-01-08.tar.gz
    manifest = get_my_manifest(wildcards)
    return f"{config['busco_directory_url']}/lineages/{wildcards.lineage}.{manifest['date']}.tar.gz"


@cache
def get_my_manifest(wildcards):
    my_lineage = wildcards.lineage
    manifest = read_manifest(wildcards)
    return manifest[my_lineage]


@cache
def read_manifest(wildcards):
    manifest = rules.download_busco_manifest.output[0]
    lineage_to_hash = {}
    with open(manifest) as f:
        for line in f:
            line_split = line.strip().split("\t")
            if line_split[4] == "lineages":
                lineage_to_hash[line_split[0]] = {
                    "date": line_split[1],
                    "hash": line_split[2],
                }
    return lineage_to_hash


rule busco_databases_target:
    input:
        get_busco_databases_target,


rule upload_busco_databases:
    input:
        "results/busco_databases/{lineage}",
    output:
        to_storage("busco/lineages/{lineage}", bucket_name=busco_bucket),
    priority: 50
    group:
        "busco"
    resources:
        runtime=lambda wildcards, attempt: int(attempt * 60),
        storage_uploads=check_concurrent_storage_uploads,
    shadow:
        "minimal"
    container:
        "docker://debian:stable-20250113"
    shell:
        "cp -r {input} {output}"


rule expand_busco_lineage_files:
    input:
        "results/busco_lineage_files/{lineage}.tar.gz",
    output:
        temp(directory("results/busco_databases/{lineage}")),
    log:
        "logs/expand_busco_lineage_files/{lineage}.log",
    group:
        "busco"
    resources:
        runtime=lambda wildcards, attempt: int(attempt * 10),
        concurrent_busco_downloads=check_concurrent_busco_downloads,
    shadow:
        "minimal"
    container:
        "docker://debian:stable-20250113"
    shell:
        "mkdir -p {output} && "
        "tar -zxf {input} -C {output} --strip-components 1 &> {log} && "
        "printf $(date -Iseconds) > {output}/TIMESTAMP"


rule download_busco_lineage_files:
    input:
        "results/busco_lineage_files/file_versions.tsv",
    output:
        temp("results/busco_lineage_files/{lineage}.tar.gz"),
    params:
        lineage_url=get_lineage_url,
        lineage_hash=get_lineage_hash,
    log:
        "logs/download_busco_lineage_files/{lineage}.log",
    resources:
        concurrent_busco_downloads=check_concurrent_busco_downloads,
        runtime=lambda wildcards, attempt: int(attempt * 10),
    retries: 3
    shadow:
        "minimal"
    container:
        "docker://quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10"
    shell:
        "wget -O {output} {params.lineage_url} &> {log} && "
        "printf '%s %s' {params.lineage_hash}  {output} | md5sum -c - &>> {log}"


rule download_busco_manifest:
    output:
        "results/busco_lineage_files/file_versions.tsv",
    params:
        busco_manifest_url=get_busco_manifest_url,
    log:
        "logs/download_busco_manifest.log",
    container:
        "docker://quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10"
    shell:
        "wget {params.busco_manifest_url} -O {output} &> {log}"
