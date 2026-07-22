#!/usr/bin/env python3
import glob
import os
import sys

#!/usr/bin/env python3

import re
import argparse
from pathlib import Path

import pandas as pd


def parse_bbduk_log(logfile):
    """
    Parse a BBDuk log file.

    Returns
    -------
    dict
        sample_id -> metric dictionary
    """

    with open(logfile) as f:
        lines = f.readlines()

    results = {}

    current_sample = None
    in_metrics = False

    sample_pattern = re.compile(r"out1=.*?/([^/\s]+)_R1\.fastq\.gz")

    # Matches lines like:
    # Input:                   20468790 reads ...
    # QTrimmed:                11633067 reads ...
    # Low quality discards:    0 reads ...
    # Total Removed:           4101326 reads ...
    # Result:                  16367464 reads ...
    metric_pattern = re.compile(
        r"^([A-Za-z0-9][A-Za-z0-9 \-]*):\s+([\d,]+)\s+reads"
    )

    for line in lines:

        # Beginning of a new BBDuk run
        m = sample_pattern.search(line)
        if m:
            current_sample = m.group(1)
            results[current_sample] = {}
            in_metrics = False
            continue

        if current_sample is None:
            continue

        m = metric_pattern.match(line)
        if not m:
            continue

        label, value = m.groups()

        # Start collecting at "Input"
        if label == "Input":
            in_metrics = True

        if not in_metrics:
            continue

        # Convert label into a dataframe-friendly column name
        column = (
            label.lower()
            .replace(" ", "_")
            .replace("-", "_")
        )

        results[current_sample][column] = int(value.replace(",", ""))

        # Stop after "Result"
        if label == "Result":
            in_metrics = False

    return results


def main():
    parser = argparse.ArgumentParser(
        description="Summarize BBDuk log files."
    )
    parser.add_argument(
        "-i",
        "--input_dir",
    )
    parser.add_argument(
        "-o",
        "--output",
        default="bbduk_summary.tsv",
        help="Output summary table (TSV)"
    )

    args = parser.parse_args()

    summary = {}

    try:
        _, _, files = next(os.walk(args.input_dir))
    except StopIteration:
        raise ValueError(f"Cannot traverse {args.input_dir}.")

    for logfile in (f for f in files if f.endswith(".command.log")):
        summary.update(parse_bbduk_log(logfile))

    for logfile in (f for f in files if f.endswith(".kraken2.txt")):
        with open(logfile) as _in:
            sample, keep, drop = _in.read().strip().split("\t")

        summary.setdefault(sample, {}).update({"host_reads": int(drop), "non_host_reads": int(keep)})

    df = (
        pd.DataFrame.from_dict(summary, orient="index")
        .rename_axis("sample")
        .reset_index()
    )

    cols = ["sample"] + [c for c in df.columns if c != "sample"]
    df = df[cols]

    df.to_csv(args.output, sep="\t", index=False)

    print(df)
    print(f"\nSummary written to {args.output}")


if __name__ == "__main__":
    main()