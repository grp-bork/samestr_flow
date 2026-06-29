include { run_samestr_convert; run_samestr_merge; run_samestr_filter; run_samestr_stats; run_samestr_compare; run_samestr_summarize; collate_samestr_stats } from "../modules/profilers/samestr"


workflow samestr_post_merge {
	take:
		ss_merged
		tax_profiles
	main:
		run_samestr_filter(ss_merged, params.samestr_marker_db)

		run_samestr_stats(run_samestr_filter.out.sstr_npy, params.samestr_marker_db)
		collate_samestr_stats(run_samestr_stats.out.sstr_stats.collect())

		run_samestr_compare(run_samestr_filter.out.sstr_npy, params.samestr_marker_db)

		run_samestr_summarize(
			run_samestr_compare.out.sstr_compare.collect(),
			tax_profiles.map { sample, table -> return table }.collect(),
			params.samestr_marker_db
		)


}


workflow samestr_post_convert {
	take:
		ss_converted
		tax_profiles
	main:
		run_samestr_merge(ss_converted, params.samestr_marker_db)

		samestr_post_merge(run_samestr_merge.out.sstr_npy, tax_profiles)
}

process convert_failure_guard {
	errorStrategy "terminate"
	label "guard"
	executor "local"
	maxRetries 0

	input:
	val(sample_id)

	script:
	"""
	set -e -o pipefail

	printf "Failed convert step detected."

	printf "At least one sample failed: ${sample_id}"
		
	printf "Terminating pipeline."

	exit 1
	"""

}


workflow samestr_full {

	take:
		alignments
		tax_profiles

	main:
		run_samestr_convert(
			alignments.join(tax_profiles),
			params.samestr_marker_db
		)

		tax_profiles
			.join(run_samestr_convert.out.sstr_npy, by: 0, remainder: true)
			.branch { 
				failure: it[2] == null
				success: true 
			}
			.set { convert_status_ch }

		convert_failure_guard(convert_status_ch.failure.map { sample, data, sentinel -> sample.id })

		grouped_npy_ch = convert_status_ch.success
			.map { sample, data, sentinel -> data }
			.flatten()
			.map { file ->
					def species = file.name.replaceAll(/[.].*/, "")
					return tuple(species, file)
			}
			.groupTuple(sort: true)


		// convert_failure_guard(tax_profiles
		// 	.join(
		// 		run_samestr_convert.out.convert_sentinel, by: 0, remainder: true
		// 	)
		// 	.filter { sample, data, sentinel -> sentinel == null }
		// 	.map { sample, data, sentinel -> sample.id }
		// 	// .collect()
		// )

		grouped_npy_ch = run_samestr_convert.out.sstr_npy
			.join(run_samestr_convert.out.convert_sentinel, by: 0)
			.map { sample, data, sentinel -> return data }
			.flatten()
			.map { file ->
					def species = file.name.replaceAll(/[.].*/, "")
					return tuple(species, file)
			}
			.groupTuple(sort: true)

		if (!params.stop_after_convert) {
			samestr_post_convert(grouped_npy_ch, tax_profiles)
		}
}
