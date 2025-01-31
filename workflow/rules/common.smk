import re
from functools import cache
from snakemake.logging import logger
from pathlib import Path


configfile: "config/config.yaml"


globals().update(config)


def add_bucket_to_path(path_string):
    try:
        return storage.s3(f"{output_bucket}/{path_string}")
    except NameError as e:
        logger.error("ERROR: output_bucket is not defined in config.yaml")
        raise e


def get_files_from_listing_file(listing_file, filename_pattern):
    files = []
    with open(listing_file) as f:
        for line in f:
            splitline = line.split()[-1]
            if re.search(filename_pattern, splitline):
                files.append(splitline.rstrip(".tar.gz"))
    if len(files) == 0:
        logger.error(listing_file)
        raise ValueError(
            f"No files found in {listing_file} matching {filename_pattern}"
        )
    return files
