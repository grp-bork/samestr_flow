include { run_samestr_convert; run_samestr_merge; run_samestr_filter; run_samestr_stats; run_samestr_compare; run_samestr_summarize; collate_samestr_stats } from "../modules/profilers/samestr"

include { failure_guard as convert_failure_guard; failure_guard as filter_failure_guard } from "../modules/profilers/samestr"


workflow samestr_post_merge {
	take:
		ss_merged
		tax_profiles
	main:
		run_samestr_filter(ss_merged, params.samestr_marker_db)

		ss_merged
			.join(run_samestr_filter.out.sentinel, by: 0, remainder: true)
			.branch { 
				failure: it[2] == null
				success: true 
			}
			.set { filter_status_ch }

		filter_failure_guard(filter_status_ch.failure.map { sample, data, sentinel -> sample.id }, "filter")

		filtered_ch = run_samestr_filter.out.sstr_npy
			.join(filter_status_ch.success, by: 0)
			.map { species, data, input_data, sentinel -> [ species, data ] }

		// run_samestr_stats(run_samestr_filter.out.sstr_npy, params.samestr_marker_db)
		run_samestr_stats(filtered_ch, params.samestr_marker_db)
		collate_samestr_stats(run_samestr_stats.out.sstr_stats.collect())

		// run_samestr_compare(run_samestr_filter.out.sstr_npy, params.samestr_marker_db)
		run_samestr_compare(filtered_ch, params.samestr_marker_db)

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
			.join(run_samestr_convert.out.sentinel, by: 0, remainder: true)
			.branch { 
				failure: it[2] == null
				success: true 
			}
			.set { convert_status_ch }

		convert_failure_guard(convert_status_ch.failure.map { sample, data, sentinel -> sample.id }, "convert")

		grouped_npy_ch = run_samestr_convert.out.sstr_npy
			.join(convert_status_ch.success, by: 0)
			.map { sample, data, tax_profiles, sentinel -> data }
			.flatten()
			.map { file ->
				def species = file.name.replaceAll(/[.].*/, "")
				return [species, file]
			}
			.groupTuple(sort: true)

		// convert_failure_guard(tax_profiles
		// 	.join(
		// 		run_samestr_convert.out.sentinel, by: 0, remainder: true
		// 	)
		// 	.filter { sample, data, sentinel -> sentinel == null }
		// 	.map { sample, data, sentinel -> sample.id }
		// 	// .collect()
		// )

		// grouped_npy_ch = run_samestr_convert.out.sstr_npy
		// 	.join(run_samestr_convert.out.sentinel, by: 0)
		// 	.map { sample, data, sentinel -> return data }
		// 	.flatten()
		// 	.map { file ->
		// 			def species = file.name.replaceAll(/[.].*/, "")
		// 			return tuple(species, file)
		// 	}
		// 	.groupTuple(sort: true)

		if (!params.stop_after_convert) {
			samestr_post_convert(grouped_npy_ch, tax_profiles)
		}
}
