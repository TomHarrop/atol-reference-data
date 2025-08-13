
rule fcsgx_download_db:
    input:
        manifest=to_storage("manifest.txt", bucket_name="fcsgx"),
    output:
        to_storage("fcsgx/all.README.txt", bucket_name="fcsgx"),
        to_storage("fcsgx/all.assemblies.tsv", bucket_name="fcsgx"),
        to_storage("fcsgx/all.blast_div.tsv.gz", bucket_name="fcsgx"),
        to_storage("fcsgx/all.gxi", bucket_name="fcsgx"),
        to_storage("fcsgx/all.gxs", bucket_name="fcsgx"),
        to_storage("fcsgx/all.manifest", bucket_name="fcsgx"),
        to_storage("fcsgx/all.meta.jsonl", bucket_name="fcsgx"),
        to_storage("fcsgx/all.seq_info.tsv.gz", bucket_name="fcsgx"),
        to_storage("fcsgx/all.taxa.tsv", bucket_name="fcsgx"),
    params:
        outdir=subpath(subpath(output[0], parent=True), basename=True),
    log:
        "logs/fcsgx_download_db.log",
    resources:
        runtime=60,
    shadow:
        "minimal"
    container:
        "https://ftp.ncbi.nlm.nih.gov/genomes/TOOLS/FCS/releases/0.5.5/fcs-gx.sif"
    shell:
        "cp {input.manifest} ./manifest.txt && "
        "mkdir {params.outdir} && "
        "sync_files "
        "--mft $( readlink -f manifest.txt ) "
        "--dir $( readlink -f {params.outdir} ) "
        "get "
        "&> {log} "


rule fcsgx_get_manifest:
    output:
        manifest=to_storage("manifest.txt", bucket_name="fcsgx"),
    params:
        url=fcsgx_manifest,
    log:
        "logs/fcsgx_get_manifest.log",
    resources:
        runtime=1,
    shadow:
        "minimal"
    container:
        "docker://quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10"
    shell:
        "wget {params.url} -O {output.manifest} &> {log}"
