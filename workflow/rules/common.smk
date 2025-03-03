#!/usr/bin/env python3

from urllib.parse import urlparse

import re
from functools import cache
from snakemake.logging import logger
from pathlib import Path


configfile: "config/config.yaml"


globals().update(config)


def check_concurrent_storage_uploads(wildcards):
    """
    This workflow generates a huge number of temporary files particularly while
    waiting to upload them to the storage location. This dummy resource is used
    to limit the number of concurrent upload jobs.

    resources:
     - concurrent_storage_uploads=1

    """

    if "concurrent_storage_uploads" in workflow.resource_settings.resources:
        return 1
    else:
        return None


def get_storage_prefix(output_prefix):
    output_prefix_url = urlparse(output_prefix)
    netloc = output_prefix_url.netloc.lstrip("/")
    path = output_prefix_url.path.lstrip("/")
    return (output_prefix_url.scheme, Path(netloc, path).as_posix())


def to_storage(path_string, storage_prefix=None, registered_storage=storage.output):
    if storage_prefix is None:
        scheme, storage_prefix = get_storage_prefix(output_prefix)
    if scheme == "s3":
        return registered_storage(f"{scheme}://{storage_prefix}/{path_string}")
    elif scheme == "fs":
        return registered_storage(f"{storage_prefix}/{path_string}")
    else:
        raise NotImplementedError(f"Unknown storage scheme {scheme}")


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
try:
    storage output:
        provider = urlparse(output_prefix).scheme
except NameError as e:
    logger.error(
        """
Specify the output_prefix in config/config.yaml. Use snakemake prefixes, e.g.
s3://bucket.name/path for s3, or fs://path/to/directory for local folders. The
endpoint is currently configured in the profile.

For s3 configure the endpoint
and credentials via the profile or command line.
        """
    )
    raise e
