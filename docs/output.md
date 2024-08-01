# Output

## MetaPhlAn4
* `<sample>.mp4.txt`: Taxonomic profile (sample-specific)
* `metaphlan4_abundance_table.txt`: (collated)
* `<sample>.mp4.sam.bz2`: Marker alignment files

## SameStr
SameStr converts (`samestr convert`) MetaPhlAn marker alignment files into Single Nucleotide Variant (SNV) profiles per clade and sample. These are further processed and analyzed, producing the outputs below.

merge
* `sstr_merge/<clade>.npz`: clade-wise merged SNV profiles across samples
* `sstr_merge/<clade>.names.txt`: sample list in the same order

stats 
* `sstr_stats/<clade>.aln_stats.txt`: statistics related to coverage and nucleotide diversity of the merged and filtered SNV profiles.

compare
* `sstr_compare/<clade>.closest.txt`: number of alignment sites with the same variant in both samples of each sample-pair
* `sstr_compare/<clade>.overlap.txt`: number of alignment sites with coverage in both samples of each sample-pair
* `sstr_compare/<clade>.fraction.txt`: fraction of `closest` divided by `overlap`

summarize
* `sstr_summarize/sstr_cooccurrences.tsv`: taxonomic co-occurrence at the kingdom, phylum, class, order, family, genus, species, and strain-level
* `sstr_summarize/sstr_strain_events.tsv`: shared strain calls based on thresholds for minimum coverage overlap (default: 5kbp) and SNV profile similarity (default: 99.9%, `fraction` value).
* `sstr_summarize/taxon_counts.tsv`: number of taxa detected at each taxonomic level
