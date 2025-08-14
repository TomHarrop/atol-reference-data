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


rule fcsgx_target:
    input:
        [to_storage(f"fcsgx/all.{x}", bucket_name="fcsgx") for x in fcsgx_files],


rule upload_fcsgx_component:
    input:
        "results/fcsgx/all.{fcsgx_file}",
    output:
        to_storage("fcsgx/all.{fcsgx_file}", bucket_name="fcsgx"),
    resources:
        runtime="6h",
        storage_uploads=check_concurrent_storage_uploads,
    container:
        "docker://debian:stable-20250113"
    shell:
        "cp -r {input} {output} "


rule fcsgx_download_db:
    output:
        # "results/fcsgx/all.README.txt",
        # "results/fcsgx/all.assemblies.tsv",
        # "results/fcsgx/all.blast_div.tsv.gz",
        # "results/fcsgx/all.gxi",
        # "results/fcsgx/all.gxs",
        # "results/fcsgx/all.manifest",
        # "results/fcsgx/all.meta.jsonl",
        # "results/fcsgx/all.seq_info.tsv.gz",
        # "results/fcsgx/all.taxa.tsv",
        expand("results/fcsgx/all.{fcsgx_file}", fcsgx_file=fcsgx_files),
    params:
        outdir=subpath(output[0], parent=True),
        manifest_url=fcsgx_manifest,
    log:
        "logs/fcsgx_download_db.log",
    resources:
        runtime="6h",
    shadow:
        "minimal"
    container:
        "https://ftp.ncbi.nlm.nih.gov/genomes/TOOLS/FCS/releases/0.5.5/fcs-gx.sif"
    shell:
        "sync_files "
        "--mft {params.manifest_url} "
        "--dir {params.outdir} "
        "get "
        "&> {log} "
