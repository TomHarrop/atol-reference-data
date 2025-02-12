# atol-reference-data

## Notes

`boto3` is currently pinned to version `1.35.95` in requirements.txt, because
later versions cause `MissingContentLength` errors

## To Do:

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