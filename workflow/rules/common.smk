#!/usr/bin/env python3

from functools import cache
from pathlib import Path
from snakemake.logging import logger
from urllib.parse import urlparse
import re
import tempfile


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


def get_storage_path(path_string):
    logger.debug(f"path_string: {path_string}")
    path_string_url = urlparse(path_string)
    netloc = path_string_url.netloc.lstrip("/")
    path = path_string_url.path.lstrip("/")
    return (path_string_url.scheme, Path(netloc, path).as_posix())


def ncbiurls(wildcards, output):
    """
    Works for NCBI files, because they always have an md5sum file in the same place.
    """
    file_url = config[wildcards.filename]
    return {"url": file_url, "filename": Path(file_url).name}


def to_storage(path_string, bucket_name=None):
    scheme, storage_path = get_storage_path(path_string)
    logger.debug(f"scheme: {scheme}")
    logger.debug(f"storage_path: {storage_path}")
    if scheme == "":
        # If scheme was not given, we will try to store the output on S3
        scheme = "s3"
    if scheme == "s3":
        if bucket_name is None:
            bucket_name = "default"
        logger.debug(f"bucket_name: {bucket_name}")
        storage_prefix = buckets[bucket_name]
        logger.debug(f"storage_prefix: {storage_prefix}")
        registered_storage = eval(f"storage.{bucket_name}")
        return registered_storage(f"{storage_prefix}/{storage_path}")

    if scheme == "fs":
        raise NotImplementedError(f"TODO: implement {scheme}")

    raise NotImplementedError(f"Unknown storage scheme {scheme}")


for bucket_name, bucket_url in buckets.items():
    smkfile = tempfile.mkstemp(suffix=f"{bucket_name}.smk")[1]
    scheme = urlparse(bucket_url).scheme
    with open(smkfile, "wt") as f:
        f.write(f'storage {bucket_name}:\n  provider="{scheme}"\n')

    include: smkfile
