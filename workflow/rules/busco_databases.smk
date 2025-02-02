rule download_busco_lineage_files:
    params:
        busco_directory_url=config["busco_directory_url"],
    output:
        outdir=temp(directory("results/busco_lineage_files")),
    log:
        "logs/download_busco_lineage_files.log",
    container:
        "docker://quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10"
    shadow:
        "minimal"
    shell:
        "wget -r -nH "
        "{params.busco_directory_url} "
        "&> {log} "
        "&& mv v5/ {output.outdir}"
