#!/usr/bin/env nextflow

nextflow.enable.dsl=2

include { nevermore_simple_preprocessing } from "./prep"
include { fastqc } from "../modules/qc/fastqc"
include { multiqc } from "../modules/qc/multiqc"
include { collate_stats } from "../modules/stats"
include { nevermore_align } from "./align"
include { nevermore_pack_reads } from "./pack"
include { nevermore_qa } from "./qa"
include { nevermore_decon } from "./decon"


params.run_preprocessing = params.run_qc
def do_preprocessing = (!params.skip_preprocessing || params.run_preprocessing)
def do_alignment = params.run_gffquant || !params.skip_alignment
def do_stream = params.gq_stream

process collate_prep_and_decon {
	container "quay.io/biocontainers/pandas:2.2.1"

	input:
	path(files)

	script:
	"""
	collate_prep_and_decon.py -o table.txt ${files}
	"""
}



workflow nevermore_main {

	take:
		fastq_ch

	main:
		stats_ch = Channel.empty()

		if (do_preprocessing) {
	
			nevermore_simple_preprocessing(fastq_ch)
	
			preprocessed_ch = nevermore_simple_preprocessing.out.main_reads_out
			if (!params.drop_orphans) {
				preprocessed_ch = preprocessed_ch.mix(nevermore_simple_preprocessing.out.orphan_reads_out)
			}
			stats_ch = stats_ch.mix(nevermore_simple_preprocessing.out.stats)

			nevermore_decon(preprocessed_ch)
			preprocessed_ch = nevermore_decon.out.reads
			stats_ch = stats_ch.mix(nevermore_decon.out.stats)

		} else {
	
			preprocessed_ch = fastq_ch
	
		}
	
		nevermore_pack_reads(preprocessed_ch)

		collate_ch = Channel.empty()
		if (params.run_qa) {

			raw_counts_ch = (do_preprocessing) ? nevermore_simple_preprocessing.out.raw_counts : Channel.empty()

			nevermore_qa(
				nevermore_pack_reads.out.qa_fastqs,
				raw_counts_ch
			)

			collate_ch = nevermore_qa.out.readcounts_ch

		}

		collate_stats(collate_ch.collect())

		collate_prep_and_decon(stats_ch.map {sample, file -> file}.collect())


	emit:
		fastqs = nevermore_pack_reads.out.fastqs
		readcounts = collate_ch
		stats = stats_ch

}
