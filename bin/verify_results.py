#!/usr/bin/env python3

import argparse
import csv
import os
import pathlib
import re


def check_convert(pname, phash, workdir):

	try:
		workdir = next(workdir.glob(f"{phash}*"))
	except StopIteration:
		# raise ValueError(f"{pname} has no workdir.")
		return False, f"{pname} has no workdir."

	
	if not (workdir / "samestr_convert_DONE").is_file():
		return False, f"{pname} did not finish."
	
	logfile = workdir / ".command.err"	
	if not logfile.is_file():
		return False, f"{pname} does not have a .command.err."
	
	expected_clades = None
	log_complete = False
	with open(logfile, "rt") as _in:
		for line in _in:
			if log_complete:
				return False, ValueError(f"{pname}: found additional lines after log Done marker.")
			if expected_clades is None:
				p = line.find("Detected clades:")
				if p != -1:
					expected_clades = set(line.rstrip()[p:].split(":")[1].replace(" ", "").split(","))
					# print("Clades expected:", expected_clades)
			if line.rstrip().endswith("Done."):
				log_complete = True


	
	clade_files = list((workdir / "sstr_convert" / pname).glob("*.npz"))

	clades_present = {os.path.basename(f).split(".")[0] for f in clade_files}
	# print(f"Clade files found: {clades_present}.")
	clade_diff = expected_clades.difference(clades_present)
	if clade_diff:
		return False, f"{pname}: Missing clades = {clade_diff}"


	return True, f"{pname} looks good."



def main():
	ap = argparse.ArgumentParser()
	ap.add_argument("tracefile", type=str,)
	ap.add_argument("workdir", type=str, default="./work")
	args = ap.parse_args()

	workdir = pathlib.Path(args.workdir)
	

	with open(args.tracefile, "rt") as _in:
		for row in csv.DictReader(_in, delimiter="\t"):
			if row["status"] == "COMPLETED" and row["exit"] == "0":
				if "run_samestr_convert" in row["name"] and row["status"]:
					status, msg = check_convert(re.search(r'\((.+)\)', row["name"]).group(1), row["hash"], workdir)
					print(msg)



if __name__ == "__main__":
	main()