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

    Returns a dictionary:
        sample_id -> metrics
    """

    with open(logfile) as f:
        lines = f.readlines()

    results = {}

    current_sample = None

    patterns = {
        "input_reads": re.compile(r"Input:\s+([\d,]+)\s+reads"),
        "qtrimmed_reads": re.compile(r"QTrimmed:\s+([\d,]+)\s+reads"),
        "ktrimmed_reads": re.compile(r"KTrimmed:\s+([\d,]+)\s+reads"),
        "low_quality_discards": re.compile(r"Low quality discards:\s+([\d,]+)\s+reads"),
        "low_entropy_discards": re.compile(r"Low entropy discards:\s+([\d,]+)\s+reads"),
        "remaining_reads": re.compile(r"Result:\s+([\d,]+)\s+reads"),
    }

    sample_pattern = re.compile(r"out1=.*?/([^/\s]+)_R1\.fastq\.gz")

    for line in lines:

        # Start of a new BBDuk run
        m = sample_pattern.search(line)
        if m:
            current_sample = m.group(1)
            results[current_sample] = {}
            continue

        if current_sample is None:
            continue

        for key, pat in patterns.items():
            m = pat.search(line)
            if m:
                results[current_sample][key] = int(m.group(1).replace(",", ""))

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
        _, dirs, files = next(os.walk(args.input_dir))
    except StopIteration:
        raise ValueError(f"Cannot traverse {args.input_dir}.")

    for logfile in (f for f in files if f.endswith(".command.log")):
        summary.update(parse_bbduk_log(logfile))

    df = (
        pd.DataFrame.from_dict(summary, orient="index")
        .rename_axis("sample")
        .reset_index()
    )

    # Ensure column order
    cols = [
        "sample",
        "input_reads",
        "qtrimmed_reads",
        "ktrimmed_reads",
        "low_quality_discards",
        "low_entropy_discards",
        "remaining_reads",
    ]

    df = df[cols]

    df.to_csv(args.output, sep="\t", index=False)

    print(df)
    print(f"\nSummary written to {args.output}")


if __name__ == "__main__":
    main()