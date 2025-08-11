#!/bin/bash

echo -e "accession\\taccession.version\\ttaxid\\tgi" > "${snakemake_output[taxid_map]}"
cat ${snakemake_input} >> "${snakemake_output[taxid_map]}"
