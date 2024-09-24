#!/usr/bin/env nextflow

nextflow.enable.dsl=2

include { nevermore_main } from "./nevermore/workflows/nevermore"
include { fastq_input } from "./nevermore/workflows/input"
include { run_metaphlan4; combine_metaphlan4; collate_metaphlan4_tables } from "./nevermore/modules/profilers/metaphlan4"
include { samestr } from "./metaphlow/workflows/samestr"


workflow {

	fastq_input(
		Channel.fromPath(input_dir + "/**[._]{fastq.gz,fq.gz,fastq.bz2,fq.bz2}"),
		Channel.of(null)
	)

	fastq_input_ch = fastq_input.out.fastqs

	if (params.ignore_samples) {
		ignore_samples = params.ignore_samples.split(",")
		print ignore_samples
		fastq_input_ch = fastq_input_ch
			.filter { !ignore_samples.contains(it[0].id) }
	}
	
	fastq_input_ch.dump(pretty: true, tag: "fastq_input_ch")
	nevermore_main(fastq_input_ch)

	fastq_ch = nevermore_main.out.fastqs
	
	fastq_ch = fastq_ch
		.map { sample, fastqs ->
			sample_id = sample.id.replaceAll(/\.singles$/, "")
			return tuple(sample_id, fastqs)
		}
		.groupTuple()
		.map { sample_id, fastqs ->
			def meta = [:]
			meta.id = sample_id				
			return tuple(meta, [fastqs].flatten())
		}

	run_metaphlan4(fastq_ch, params.mp4_db)
		
	collate_metaphlan4_tables(
		run_metaphlan4.out.mp4_table
			.map { sample, table -> return table }
			.collect()
	)

	samestr(
		run_metaphlan4.out.mp4_sam,
		run_metaphlan4.out.mp4_table
	)

}


