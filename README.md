# atol-reference-data

## Notes

`boto3` is currently pinned to version `1.35.95` in requirements.txt, because
later versions cause `MissingContentLength` errors

## To Do:

The BUSCO datasets use up >1M files, so they will have to go into separate S3 buckets. OMG.

Probably best to write a workflow for downloading this reference data.

e.g.:

```python3
from pathlib import Path

# quick to download, but only one sample
accession = "PRJEB67460"


outdir = Path("test-output", "bpdownload", accession)


# Call the module.
bpdownload_snakefile = "../modules/bpdownload/Snakefile"


module bpdownload:
    snakefile:
        bpdownload_snakefile
    config:
        {
            "accession": accession,
            "outdir": outdir,
            "run_tmpdir": Path(outdir, "tmp"),
        }


use rule * from bpdownload as bpdownload_*
```