import json


@cache
def fcgsx_read_manifest(manifest_file):
    with open(manifest_file) as f:
        return {x["fileName"]: x for x in json.load(f)["fileDetails"]}


def fcgsx_get_hash(wildcards, input):
    manifest = fcgsx_read_manifest(input.manifest)
    return manifest[f"all.{wildcards.fcsgx_file}"]["hashValue"]


def fcgsx_build_url(wildcards):
    manifest_url = urlparse(fcsgx_manifest)
    file_path = Path(
        Path(manifest_url.path).parent, f"all.{wildcards.fcsgx_file}"
    ).as_posix()
    return manifest_url._replace(path=file_path).geturl()


fcsgx_files = [
    "assemblies.tsv",
    "blast_div.tsv.gz",
    "gxi",
    "gxs",
    "manifest",
    "meta.jsonl",
    "README.txt",
    "seq_info.tsv.gz",
    "taxa.tsv",
]


wildcard_constraints:
    fcsgx_file="|".join(fcsgx_files),


rule fcsgx_target:
    input:
        [to_storage(f"fcsgx/all.{x}", bucket_name="fcsgx") for x in fcsgx_files],


rule upload_fcsgx_component:
    input:
        flagfile="results/fcsgx/all.OK",
        fcsgx_file="results/fcsgx/all.{fcsgx_file}",
    output:
        to_storage("fcsgx/all.{fcsgx_file}", bucket_name="fcsgx"),
    resources:
        runtime="2h",
        storage_uploads=check_concurrent_storage_uploads,
    container:
        "docker://debian:stable-20250113"
    shell:
        "cp -r {input.fcsgx_file} {output} "


# FIXME. This call should check the downloaded file's hashes (again)
rule fcsgx_verify_downloads:
    input:
        expand("results/fcsgx/all.{fcsgx_file}", fcsgx_file=fcsgx_files),
    output:
        touch("results/fcsgx/all.OK"),
    log:
        "logs/fcsgx_download_file/fcsgx_verify_downloads.log",
    params:
        outdir=subpath(output[0], parent=True),
        manifest_url=fcsgx_manifest,
    resources:
        runtime=60,
    shadow:
        "minimal"
    container:
        "https://ftp.ncbi.nlm.nih.gov/genomes/TOOLS/FCS/releases/0.5.5/fcs-gx.sif"
    shell:
        "while ! "
        "sync_files "
        "--mft {params.manifest_url} "
        "--dir {params.outdir} "
        "get "
        "&>> {log} "
        "; "
        "do "
        "printf 'Retrying at %s\\n' $(date) ; "
        "done"


rule fcsgx_download_file:
    input:
        manifest="results/fcsgx/all.manifest",
    output:
        fcsgx_file="results/fcsgx/all.{fcsgx_file}",
    params:
        outdir=subpath(output[0], parent=True),
        hash_value=fcgsx_get_hash,
        url=fcgsx_build_url,
    log:
        "logs/fcsgx_download_file/{fcsgx_file}.log",
    resources:
        runtime=lambda wildcards: (
            "1d" if wildcards.fcsgx_file in ["gxi", "gxs"] else 10
        ),
        # partitionFlag="--partition long",
    shadow:
        "minimal"
    container:
        "docker://quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10"
    shell:
        "wget -O {output.fcsgx_file} {params.url} &> {log} && "
        "printf '%s %s' {params.hash_value}  {output.fcsgx_file} | md5sum -c - &>> {log}"


rule fcsgx_download_manifest:
    output:
        manifest="results/fcsgx/all.manifest",
    params:
        manifest_url=fcsgx_manifest,
    log:
        "logs/fcsgx_download_manifest.log",
    resources:
        runtime=1,
    shadow:
        "minimal"
    container:
        "docker://quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10"
    shell:
        "wget {params.manifest_url} -O {output.manifest} &> {log} "
