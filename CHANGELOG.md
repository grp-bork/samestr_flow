VERSION 0.14.0

- improved fastq loading
- updated EMBL container depository URLs
- updated samestr from v1.2024.09 to v1.2025.102
- outputs from samestr stats will be collated
- added samestr_post_merge workflow
- disabled sortbyname.sh assertions in merge_single_fastqs
- fixed kraken2 decontamination
- metaphlan4 is now running in --offline mode to prevent unwanted database update attempts and consequent workflow failures
- improved routing of unpaired reads
- changed remove_host parameters from bool to ["kraken2", "off"]


VERSION 0.13.0

- updated metaphlow to 0.16.0
- allow to summarize motus-based profiles

- updated nevermore to 0.14.12_1.0
- deactivate kraken2-based host decontamination in favour of a hostile-based process
- updated hostile to version 2.0
- explicitly call -t rel_ab in metaphlan4 profiling
- updated motus process to ensure compatibility with samestr
- added explicit qin=33 call to bbduk integrated orphan processing