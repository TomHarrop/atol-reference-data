
rule fcsgx_download_db:
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
        manifest_url=fcsgx_manifest,
    log:
        "logs/fcsgx_download_db.log",
    resources:
        runtime="12h",
    shadow:
        "minimal"
    container:
        "https://ftp.ncbi.nlm.nih.gov/genomes/TOOLS/FCS/releases/0.5.5/fcs-gx.sif"
    shell:
        "mkdir {params.outdir} && "
        "sync_files "
        "--mft {params.manifest_url} "
        "--dir $( readlink -f {params.outdir} ) "
        "get "
        "&> {log} "

