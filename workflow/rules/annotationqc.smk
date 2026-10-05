
rule annotationqc:
    input:
        "results/annotationqc",
    output:
        to_storage("annotationqc", bucket_name="annotationqc"),
    container:
        "docker://debian:stable-20250113"
    resources:
        runtime="23h",
        storage_uploads=check_concurrent_storage_uploads,
    shell:
        "cp -r {input} {output} "


rule collect_annotationqc_files:
    input:
        omark_db="results/annotationqc_files/LUCA.h5",
        taxa_sqlite="results/annotationqc_files/taxa.sqlite",
    output:
        outdir=temp(directory("results/annotationqc")),
    container:
        "docker://quay.io/biocontainers/pigz:2.8"
    shell:
        "mkdir -p {output.outdir} "
        "&& "
        "cp {input} {output.outdir}/ "
        "&& "
        "printf $(date -Iseconds) > {output.outdir}/TIMESTAMP"


rule ete_db:
    output:
        taxa_sqlite="results/annotationqc_files/taxa.sqlite",
    log:
        "logs/ete_db.log",
    shadow:
        "minimal"
    container:
        # has ete4
        "docker://quay.io/biocontainers/orthofinder:3.1.5--hdfd78af_0"
    resources:
        runtime="10m",
    shell:
        "HOME=$PWD "
        "python3 -c "
        "'from ete4 import NCBITaxa; ncbi=NCBITaxa()' "
        "&> {log} "
        "&& "
        "mv $PWD/.local/share/ete/taxa.sqlite {output.taxa_sqlite}"


# Note, the file at https://omabrowser.org/All/LUCA.h5 redirects to a Zenodo
# record with versioned DBs (https://zenodo.org/records/20814376). The current
# version is https://zenodo.org/records/20814376/files/LUCA.h5, but this seems
# to be incompatible with omark 0.3.1. We can't upgrade omark because it
# requires an old version of libsqlite, which is incompatible with the version
# of python used by BUSCO v6.
rule download_omark_db:
    output:
        omark_db=temp("results/annotationqc_files/LUCA.h5"),
    log:
        "logs/download_omark_db.log",
    shadow:
        "minimal"
    container:
        "docker://quay.io/biocontainers/wget:1.25.0"
    resources:
        runtime="10h",
    params:
        file_url="https://zenodo.org/records/17826591/files/LUCA.h5",
        md5sum="0a437cdd37b20149da5ec79a73fa6ca4",
    shell:
        "wget {params.file_url} -O {output.omark_db} &> {log} && "
        "md5sum -cw <( echo {params.md5sum} {output.omark_db} ) &>> {log}"
