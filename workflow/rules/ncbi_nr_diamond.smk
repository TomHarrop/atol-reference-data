#!/usr/bin/env python3


# Note, the docs say "build the database similarly to the Uniprot Diamond
# database", but nr doesn't include a taxid map. Not sure if this is required.


# to_storage("folder", bucket_name="nr_diamond")


rule diamond_nr_makedb:
    input:
        sequences="results/diamond_nr_database/nr.fasta",
        taxid_map="results/diamond_nr_database/nr.taxid_map",
        nodes=to_storage("taxdump/nodes.dmp", bucket_name="ncbi"),
    output:
        dmnd=to_storage("diamond/nr.dmnd", bucket_name="nr_diamond"),
        timestamp=to_storage("diamond/TIMESTAMP"),
    log:
        "logs/diamond_makedb.log",
    threads: 24
    resources:
        storage_uploads=check_concurrent_storage_uploads,
        runtime="1d",
        mem="256GB",
        partitionFlag="--partition highmem",
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
        "&& "
        "printf $(date -Iseconds) > {output.timestamp}"


# FORMAT
# accession	accession.version	taxid	gi
# A0A395GHB9	A0A395GHB9	1448316	0
# A0A395GHC3	A0A395GHC3	1448316	0
# A0A395GHC5	A0A395GHC5	1448316	0
# rule diamond_nr_taxid_map:
#     input:
#         p2a="results/downloads/prot.accession2taxid.FULL.gz",
#     output:
#         taxid_map="results/diamond_nr_database/nr.taxid_map",
#     log:
#         "logs/diamond_nr_taxid_map.log",
#     resources:
#         runtime="1d",
#     shadow:
#         "minimal"
#     container:
#         "docker://quay.io/biocontainers/diamond:2.1.13--h13889ed_0"
#     shell:
#         'echo -e "accession\\taccession.version\\ttaxid\\tgi" > {output.taxid_map} '
#         "&& "
#         "zcat {input.p2a} "
#         "2>> {log} "
#         "| "
#         "tail -n +2 "
#         "| "
#         'awk \'{{print $1 "\\t" $1 "\\t" $2 "\\t" 0}}\' '
#         ">> {output.taxid_map} "
#         "2>> {log} "


# Mung the taxid map with R. The streaming approach with bash and awk uses
# basically no memory but takes days to run. This is the opposite.
rule diamond_nr_taxid_map:
    input:
        p2a="results/downloads/prot.accession2taxid.FULL.gz",
        # p2a="prot.accession2taxid1000.gz",
    output:
        taxid_map="results/diamond_nr_database/nr.taxid_map",
        # taxid_map="nr.taxid_map",
    log:
        "logs/diamond_nr_taxid_map.log",
    benchmark:
        "logs/benchmarks/diamond_nr_taxid_map.txt"
    threads: 12
    resources:
        runtime="4h",
        mem="256GB",
        partitionFlag="--partition highmem",
    shadow:
        "minimal"
    container:
        "docker://ghcr.io/tomharrop/r-containers:r2u_24.04_cv1"
    shell:
        "export R_DATATABLE_NUM_THREADS=${{SLURM_CPUS_ON_NODE:-{threads}}} && "
        "gzip -dc {input.p2a} > in.tsv && "
        'Rscript -e "'
        "library(data.table); "
        "getDTthreads(verbose=TRUE); "
        "fwrite(fread('in.tsv')[,.(accession=accession.version,accession.version=accession.version,taxid=taxid,gi=0)], '{output.taxid_map}', sep='\\t')"
        '" '
        "&> {log}"


rule expand_nr_file:
    input:
        gzfile="results/downloads/nr.gz",
    output:
        database=temp("results/diamond_nr_database/nr.fasta"),
    threads: 2
    resources:
        runtime="1d",
    shadow:
        "minimal"
    log:
        "logs/expand_nr_file.log",
    container:
        "docker://quay.io/biocontainers/pigz:2.8"
    shell:
        "pigz -p {threads} -dc {input.gzfile} > {output.database} 2> {log}"


rule download_ncbi:
    output:
        filename=temp("results/downloads/{filename}"),
    params:
        urls=ncbiurls,
    log:
        "logs/download_generic/{filename}.log",
    resources:
        runtime=lambda wildcards, attempt: int(attempt * 30),  # TODO check filename
    shadow:
        "minimal"
    container:
        # gnu wget container doesn't like the md5 file that comes with the
        # accession2taxid file.
        "docker://quay.io/biocontainers/gnu-wget:1.18--hb829ee6_10"
    shell:
        "wget {params[urls][url]} -O {params[urls][filename]} 2> {log} && "
        "wget {params[urls][url]}.md5 -O {params[urls][filename]}.md5 2>> {log} && "
        "sed 's/^[[:space:]]*//' {params[urls][filename]}.md5 | md5sum -c - 2>> {log} && "
        "mv {params[urls][filename]} {output.filename}"
