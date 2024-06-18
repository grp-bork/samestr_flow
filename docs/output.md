Output
======


MetaPhlan4
----------

`samestr_flow` produces individual sample-specific metaphlan4 profiles as well as a collated file across all samples.

SameStr
-------

The various components of the SameStr subworkflow produce the following outputs:


* `merge` merges nucleotide variant profiles obtained from metagenomic samples
  - 2 files `t__SGB<SGB>.names.txt` and `t__SGB<SGB>.npz` per SGB  + group files?
* `stats` generates statistics related to coverage and nucleotide diversity in nucleotide variant profiles of the merged and filtered results.
  - 1 file `t__SGB<SGB>.aln_stats.txt` per SGB + group files?
* `compare` performs pairwise clade-specific alignment comparison
  - 3 files `t__SGB<SGB>.closest.txt` (), `t__SGB<SGB>.fraction.txt` (), `t_SGB<SGB>.overlap.txt` () per SGB + group files?
* `summarize` calls and summarises shared strains based on defined criteria. It also generates taxonomic co-occurrence tables at the kingdom, phylum, class, order, family, genus, species, and strain-level.
  - `sstr_cooccurrences.tsv`
  - `sstr_strain_events.tsv`
  - `taxon_counts.tsv`
