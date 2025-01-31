
rule ncbi_taxdump:
    input:
        taxdump=storage.ftp(config["taxdump_url"]),
    output:
        add_bucket_to_path("taxdump/citations.dmp"),
        add_bucket_to_path("taxdump/delnodes.dmp"),
        add_bucket_to_path("taxdump/division.dmp"),
        add_bucket_to_path("taxdump/excludedfromtype.dmp"),
        add_bucket_to_path("taxdump/fullnamelineage.dmp"),
        add_bucket_to_path("taxdump/gencode.dmp"),
        add_bucket_to_path("taxdump/host.dmp"),
        add_bucket_to_path("taxdump/images.dmp"),
        add_bucket_to_path("taxdump/merged.dmp"),
        add_bucket_to_path("taxdump/names.dmp"),
        add_bucket_to_path("taxdump/nodes.dmp"),
        add_bucket_to_path("taxdump/rankedlineage.dmp"),
        add_bucket_to_path("taxdump/taxidlineage.dmp"),
        add_bucket_to_path("taxdump/typematerial.dmp"),
        add_bucket_to_path("taxdump/typeoftype.dmp"),
        timestamp=add_bucket_to_path("taxdump/TIMESTAMP"),
    params:
        outdir=lambda wildcards, output: Path(output[0]).parent,
    container:
        "docker://debian:stable-20250113"
    shell:
        "mkdir -p {params.outdir} && "
        "tar -xzf {input.taxdump} -C {params.outdir} && "
        "printf $(date -Iseconds) > {output.timestamp}"
