
rule ncbi_taxdump:
    input:
        taxdump=storage.ftp(config["taxdump_url"]),
    output:
        add_bucket_to_path("results/taxdump/citations.dmp"),
        add_bucket_to_path("results/taxdump/delnodes.dmp"),
        add_bucket_to_path("results/taxdump/division.dmp"),
        add_bucket_to_path("results/taxdump/excludedfromtype.dmp"),
        add_bucket_to_path("results/taxdump/fullnamelineage.dmp"),
        add_bucket_to_path("results/taxdump/gencode.dmp"),
        add_bucket_to_path("results/taxdump/host.dmp"),
        add_bucket_to_path("results/taxdump/images.dmp"),
        add_bucket_to_path("results/taxdump/merged.dmp"),
        add_bucket_to_path("results/taxdump/names.dmp"),
        add_bucket_to_path("results/taxdump/nodes.dmp"),
        add_bucket_to_path("results/taxdump/rankedlineage.dmp"),
        add_bucket_to_path("results/taxdump/taxidlineage.dmp"),
        add_bucket_to_path("results/taxdump/typematerial.dmp"),
        add_bucket_to_path("results/taxdump/typeoftype.dmp"),
        timestamp=add_bucket_to_path("results/taxdump/TIMESTAMP"),
    params:
        outdir=lambda wildcards, output: Path(output[0]).parent,
    container:
        "docker://debian:stable-20250113"
    shell:
        "mkdir -p {params.outdir} && "
        "tar -xzf {input.taxdump} -C {params.outdir} && "
        "printf $(date -Iseconds) > {output.timestamp}"
