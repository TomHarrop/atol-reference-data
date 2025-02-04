#!/usr/bin/env python3

from urllib.parse import urlparse

import re
from functools import cache
from snakemake.logging import logger
from pathlib import Path


configfile: "config/config.yaml"


globals().update(config)


def get_storage_prefix(output_prefix):
    output_prefix_url = urlparse(output_prefix)
    netloc = output_prefix_url.netloc.lstrip("/")
    path = output_prefix_url.path.lstrip("/")
    return Path(netloc, path).as_posix()


def to_storage(path_string, storage_prefix=None, registered_storage=storage.output):
    if storage_prefix is None:
        storage_prefix = get_storage_prefix(output_prefix)
    return storage(f"{storage_prefix}/{path_string}")


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


# register storage for the workflow
storage output:
    provider=urlparse(output_prefix).scheme
