#!/bin/bash

#SBATCH --job-name=atol_refdata
#SBATCH --partition=long
#SBATCH --time=0-23
#SBATCH --cpus-per-task=2
#SBATCH --ntasks=1
#SBATCH --mem=8g
#SBATCH --output=sm.slurm.out
#SBATCH --error=sm.slurm.err

# Dependencies
module load python/3.11.6
module load singularity/4.1.0-nohost

unset SBATCH_EXPORT

# Application specific commands:
set -eux

source /software/projects/pawsey1132/tharrop/atol-reference-data/venv/bin/activate

printf "TMPDIR: %s\n" "${TMPDIR}"
printf "SLURM_CPUS_ON_NODE: %s\n" "${SLURM_CPUS_ON_NODE}"

if [ -z "${SINGULARITY_CACHEDIR}" ]; then
    export SINGULARITY_CACHEDIR=/software/projects/pawsey1132/tharrop/.singularity
    export APPTAINER_CACHEDIR="${SINGULARITY_CACHEDIR}"
fi

# what's up with the network?
# ping -W 1 -c 5 8.8.8.8
# curl -Iv ftp.ncbi.nih.gov

# run the pipeline with notemp to avoid re-downloading the data
snakemake \
    --profile profiles/pawsey_v8 \
    --retries 0 \
    --cores 12 \
    --notemp \
    --local-cores "${SLURM_CPUS_ON_NODE}" \
    diamond_makedb upload_kraken_nt_db expand_nr_file

exit 0

# delete if everything is there, disabled for now
if [ $? -eq 0 ]; then
    printf "Deleting temp files"
    snakemake \
        --profile profiles/pawsey_v8 \
        --delete-temp-output \
        --cleanup-shadow \
        --local-cores "${SLURM_CPUS_ON_NODE}" \
        diamond_makedb upload_kraken_nt_db expand_nr_file
fi

