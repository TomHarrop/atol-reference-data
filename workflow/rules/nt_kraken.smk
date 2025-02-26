rule kraken2_db:
    input:
        to_storage("ncbi_nucleotide_blast"),
    output:
        to_storage("kraken2_db"),
    resources:
        mem="256GiB"
    threads:
        24
    container:
        "docker://quay.io/biocontainers/kraken2:2.14--pl5321h077b44d_0"
    shell:
        "kraken2-build "
        "--build "
        "--threads {threads} "
        "--db {input}"