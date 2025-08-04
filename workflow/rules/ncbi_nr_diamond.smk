#!/usr/bin/env python3


# Note, the docs say "build the database similarly to the Uniprot Diamond
# database", but nr doesn't include a taxid map. Not sure if this is required.


# to_storage("folder", bucket_name="nr_diamond")


rule diamond_nr_makedb:
    input:
        sequences="results/diamond/reference_proteomes.fasta.gz",
        nodes=to_storage("taxdump/nodes.dmp", bucket_name="ncbi"),
    output:
        dmnd=to_storage(
            "diamond/reference_proteomes.dmnd", bucket_name="uniprot_diamond"
        ),
    log:
        "logs/diamond_makedb.log",
    threads: 24
    resources:
        storage_uploads=check_concurrent_storage_uploads,
        runtime=lambda wildcards, attempt: int(attempt * 60),
        mem=lambda wildcards, attempt: f"{int(128)* attempt}GB",
    shadow:
        "minimal"
    container:
        "docker://quay.io/biocontainers/diamond:2.1.13--h13889ed_0"
    shell:
        "diamond makedb "
        "-p {threads} "
        "--in {input.sequences} "
        "--taxonmap {input.taxid_map} "
        "--taxonnodes {input.nodes} "
        "-d {output.dmnd} "
        "2>> {log} "


# FORMAT
# accession	accession.version	taxid	gi
# A0A395GHB9	A0A395GHB9	1448316	0
# A0A395GHC3	A0A395GHC3	1448316	0
# A0A395GHC5	A0A395GHC5	1448316	0
rule diamond_nr_taxid_map:
    input:
        p2a="results/diamond_nr_database_files/prot.accession2taxid.FULL.gz",
    output:
        taxid_map="results/diamond_nr_database_files/nr.taxid_map",
    log:
        "logs/diamond_nr_taxid_map.log",
    resources:
        runtime=lambda wildcards, attempt: int(attempt * 120),
    shadow:
        "minimal"
    container:
        "docker://quay.io/biocontainers/diamond:2.1.13--h13889ed_0"
    shell:
        'echo -e "accession\\taccession.version\\ttaxid\\tgi" > {output.taxid_map} '
        "&& "
        "zcat {input.p2a} "
        "2>> {log} "
        "| "
        "tail -n +1 "
        "| "
        'awk \'{{print $1 "\\t" $1 "\\t" $2 "\\t" 0}}\' '
        ">> {output.taxid_map} "
        "2>> {log} "


rule expand_nr_file:
    input:
        gzfile="results/diamond_nr_database_files/nr.gz",
    output:
        database=temp("results/diamond_nr_database_files/nr.fasta"),
        timestamp=temp("results/diamond_nr_database/TIMESTAMP"),
    threads: 2
    resources:
        runtime=lambda wildcards, attempt: int(attempt * 60),
    shadow:
        "minimal"
    log:
        "logs/expand_nr_file.log",
    container:
        "docker://quay.io/biocontainers/pigz:2.8"
    shell:
        "pigz -p {threads} -dc {input.gzfile} > {output.database} 2> {log} && "
        "printf $(date -Iseconds) > {output.timestamp}"


rule download_ncbi:
    output:
        filename=temp("results/diamond_nr_database_files/{filename}"),
    params:
        urls=ncbiurls,
    log:
        "logs/download_generic/{filename}.log",
    resources:
        runtime=lambda wildcards, attempt: int(attempt * 30),  # TODO check filename
    shadow:
        "minimal"
    container:
        "docker://quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10"
    shell:
        "wget {params[urls][url]} -O {params[urls][filename]} 2> {log} && "
        "wget {params[urls][url]}.md5 -O {params[urls][filename]}.md5 2>> {log} && "
        "md5sum -c {params[urls][filename]}.md5 2>> {log} && "
        "mv {params[urls][filename]} {output.filename}"
