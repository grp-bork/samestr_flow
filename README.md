<table>
  <tr width="100%">
    <td width="150px">
      <a href="https://www.bork.embl.de/"><img src="https://www.bork.embl.de/assets/img/normal_version.png" alt="Bork Group Logo" width="150px" height="auto"></a>
    </td>
    <td width="425px" align="center">
      <b>Developed by the <a href="https://www.bork.embl.de/">Bork Group</a></b><br>
      Raise an <a href="https://github.com/grp-bork/samestr_flow/issues">issue</a> or <a href="mailto:N4M@embl.de">contact us</a><br><br>
      See our <a href="https://www.bork.embl.de/services.html">other Software & Services</a>
    </td>
    <td width="500px">
      Contributors:<br>
      <ul>
        <li>
          <a href="https://github.com/cschu/">Christian Schudoma</a> <a href="https://orcid.org/0000-0003-1157-1354"><img src="https://orcid.org/assets/vectors/orcid.logo.icon.svg" alt="ORCID icon" width="20px" height="20px"></a><br>
        </li>
        <li>
          <a href="https://github.com/danielpodlesny/">Daniel Podlesny</a> <a href="https://orcid.org/0000-0002-5685-0915"><img src="https://orcid.org/assets/vectors/orcid.logo.icon.svg" alt="ORCID icon" width="20px" height="20px"></a><br>
        </li>
      </ul>
    </td>
  </tr>
  <tr>
    <td colspan="3" align="center">The development of this workflow was supported by <a href="https://www.nfdi4microbiota.de/">NFDI4Microbiota <img src="https://github.com/user-attachments/assets/1e78f65e-9828-46c0-834c-0ed12ca9d5ed" alt="NFDI4Microbiota icon" width="20px" height="20px"></a> 
</td>
  </tr>
</table>


---
# Overview

The `SameStr workflow` is a nextflow workflow for running the strain-identification tool [SameStr](https://github.com/danielpodlesny/samestr) based on `Metaphlan4` profiles. The workflow includes optional read preprocessing and host/human decontamination steps provided by the [nevermore](https://github.com/cschu/nevermore) workflow library.

![Nevermore_workflow](docs/nevermore.svg)

![SameStr_subworkflow](docs/samestr_subworkflow.svg)

---
# Requirements

The easiest way to handle `samestr_flow`'s dependencies is via Singularity/Docker containers. Alternatively, conda environments, software module systems or native installations can be used.

## Preprocessing

Preprocessing and QA is done with bbmap, fastqc, and multiqc.

## Decontamination/Host removal

Decontamination is done with kraken2 and additionally requires seqtk. 

### Kraken2 database

Host removal requires a kraken2 host database.

## Metaphlan Profiling

The default supported Metaphlan version is 4.

### CHOCOPhlAn database for Metaphlan4

Get an SGB-based CHOCOPhlAn database from the [official Biobakery site](http://cmprod1.cibio.unitn.it/biobakery4/metaphlan_databases/). At the time of writing, the following databases are available:

* `mpa_vJan21_CHOCOPhlAnSGB_202103` (has SameStr db)
* `mpa_vOct22_CHOCOPhlAnSGB_202212` (has SameStr db)
* `mpa_vJun23_CHOCOPhlAnSGB_202307` (has SameStr db)
* `mpa_vOct22_CHOCOPhlAnSGB_202403` (not tested)
* `mpa_vJun23_CHOCOPhlAnSGB_202403` (not tested)

To install the database, unpack the tarball and point the `--mp4_db` parameter to the database's root directory.

In `params.yml`:

```
mp4_db: "/path/to/mpa_vOct22_CHOCOPhlAnSGB_202212/"
```

On the command line:

```
--mp4_db "/path/to/mpa_vOct22_CHOCOPhlAnSGB_202212/"
```
## SameStr Profiling
Shared strains are detected with SameStr.

### SameStr databases

Obtain the SameStr database corresponding to your CHOCOPhlAn database from the [Zenodo repository](https://zenodo.org/records/10640239).

---
# Usage

The workflow run is controlled by environment-specific parameters (s. [run.config](config/run.config)) and studiy-specific parameters (s. [params.yml](config/params.yml)). The parameters in the `params.yml` can be specified on the command line as well.

You can either clone this repository from GitHub and run it as follows
```
git clone https://github.com/grp-bork/samestr_flow.git
nextflow run /path/to/samestr_flow [-resume] -c /path/to/run.config -params-file /path/to/params.yml
```

Or, you can have nextflow pull it from github and run it from the `$HOME/.nextflow` directory.
```
nextflow run grp-bork/samestr_flow [-resume] -c /path/to/run.config -params-file /path/to/params.yml
```

### Input files

samestr_flow supports fastq files. These can be uncompressed (but shouldn't be!) or compressed with gzip or bzip2. Sample data must be arranged in one directory per sample.

#### Per-sample input directories

All files in a sample directory will be associated with name of the sample folder. Paired-end mate files need to have matching prefixes. Mates 1 and 2 can be specified with suffixes `_[12]`, `_R[12]`, `.[12]`, `.R[12]`. Lane IDs or other read id modifiers have to precede the mate identifier. Files with names not containing either of those patterns will be assigned to be single-ended. Metaphlow assumes samples that consist of both single and paired end files to be paired end with all single end files being orphans (quality control survivors). 










