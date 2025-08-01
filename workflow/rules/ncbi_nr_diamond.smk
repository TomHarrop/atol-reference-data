#!/usr/bin/env python3


def ncbi_nr_urls(wildcards):
    file_url = config["nr_database_path"]
    return (file_url, Path(file_url).name)


# to_storage("folder", bucket_name="nr_diamond")

# rule expand_nr_file:
#     input:
#         gzfile="results/diamond_nr_database_files/nr.gz",
#     output:
#         database_directory=temp(directory("results/uniprot_reference_proteomes")),
#     threads: 2
#     resources:
#         runtime=60,
#     shadow:
#         "minimal"
#     container:
#         "docker://quay.io/biocontainers/pigz:2.8"
#     shell:
#         "mkdir -p {output.database_directory} && "
#         "pigz -p {threads} -dc {input.gzfile} && "
#         "printf $(date -Iseconds) > {output.database_directory}/TIMESTAMP"


rule download_nr_file:
    output:
        gzfile=temp("results/diamond_nr_database_files/nr.gz"),
    params:
        params=ncbi_nr_urls 
    resources:
        runtime=600,
    log:
        "logs/download_nr_file.log",
    shadow:
        "minimal"
    container:
        "docker://quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10"
    shell:
        "wget {params.params[0]} -O {params.params[1]} &> {log} && "
        "wget {params.params[0]}.md5 -O {params.params[1]}.md5 &>> {log} && "
        "md5sum -c {params.params[1]}.md5 &>> {log} && "
        "mv {params.params[1]} {output.gzfile}"
