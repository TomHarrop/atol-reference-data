rule test_env:
    container: "docker://ubuntu:latest"
    shell:
        "echo 'USER in container:' $TEST_VAR"

rule test_r_env:
    container: "docker://ghcr.io/tomharrop/r-containers:r2u_24.04_cv1"
    threads: 4
    shell:
        "export R_DATATABLE_NUM_THREADS=${{TEST_VAR:-{threads}}} && "
        "echo 'R_DATATABLE_NUM_THREADS set to:' $R_DATATABLE_NUM_THREADS && "
        'Rscript -e "library(data.table); getDTthreads(verbose=TRUE); setDTthreads(0); getDTthreads(verbose=TRUE)"'

rule test_timestamp:
    container: "docker://ubuntu:latest"
    shell:
        "echo 'Timestamp inside container:' $TEST_TIMESTAMP"

rule test_slurm_env:
    output:
        "test_slurm_env.log"
    threads: 1
    resources:
        mem_mb=100,
        runtime=2
    container:
        "docker://debian:stable-20250113"
    shell:
        "echo 'SLURM_CPUS_ON_NODE inside container is:' $SLURM_CPUS_ON_NODE > {output}"