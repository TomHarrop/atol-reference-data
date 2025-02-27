configfile: "config/config.yaml"


include: "common.smk"


rule kraken2_db:
    input:
        taxonomy="results/kraken2_db/taxonomy",
        library="results/kraken2_db/library",
    output:
        to_storage("kraken2_db"),
    params:
        db=subpath(input.library, parent=True),
    resources:
        mem="256GiB",
        storage_uploads=check_concurrent_storage_uploads,
    threads: 24
    shadow:
        "minimal"
    container:
        "docker://quay.io/biocontainers/kraken2:2.14--pl5321h077b44d_0"
    shell:
        "ls -lhrt {params.db} "
        "&&"
        "kraken2-build "
        "--build "
        "--threads {threads} "
        "--db {params.db} "
        "&& "
        "ls -lhrt {params.db} "


rule kraken2_download_library:
    output:
        library=directory("results/kraken2_db/library"),
    params:
        db=subpath(output.library, parent=True),
    resources:
        mem="256GiB",
    threads: 24
    container:
        "docker://quay.io/biocontainers/kraken2:2.14--pl5321h077b44d_0"
    shell:
        "kraken2-build "
        "--threads {threads} "
        "--download-library nt "
        "--db {params.db}"


rule kraken2_download_taxonomy:
    output:
        taxonomy=directory("results/kraken2_db/taxonomy"),
    params:
        db=subpath(output.taxonomy, parent=True),
    resources:
        mem="256GiB",
    threads: 24
    container:
        "docker://quay.io/biocontainers/kraken2:2.14--pl5321h077b44d_0"
    shell:
        "kraken2-build "
        "--threads {threads} "
        "--download-taxonomy "
        "--db {params.db}"
