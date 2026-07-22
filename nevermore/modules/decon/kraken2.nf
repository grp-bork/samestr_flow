params.kraken2_min_hit_groups = 10
params.fix_read_ids = true

process remove_host_kraken2_individual {
	container "registry.git.embl.org/schudoma/kraken2-docker:latest"
	label 'kraken2'
	label "large"
	tag "${sample.id}"

	input:
	tuple val(sample), path(fastqs)
	path(kraken_db)

	output:
	tuple val(sample), path("no_host/${sample.id}/${sample.id}_R*.fastq.gz"), emit: reads, optional: true
	tuple val(sample), path("no_host/${sample.id}/${sample.id}.chimeras_R1.fastq.gz"), emit: chimera_orphans, optional:true
	tuple val(sample), path("stats/decon/${sample.id}*.txt"), emit: stats, optional: true
	tuple val(sample), path("no_host/${sample.id}/KRAKEN_FINISHED"), emit: sentinel
	tuple val(sample), path("${sample.id}.kraken2.txt"), emit: readcounts

	script:
	def kraken2_call = "kraken2 --threads ${task.cpus} --db ${kraken_db} --report-minimizer-data --minimum-hit-groups ${params.kraken2_min_hit_groups}"

	def r1_files = fastqs.findAll( { it.name.endsWith("_R1.fastq.gz") } )
	def r2_files = fastqs.findAll( { it.name.endsWith("_R2.fastq.gz") } )

	def fix_read_id_str = ""
	if (params.fix_read_ids) {
		// original code had:
		// seqtk rename <fastq> read | cut -f 1 -d ' ' > <output_fastq>
		// this strips the comment fields from the fastq header lines -- not sure if that could be useful for edge cases?

		if (r1_files.size() != 0 ) {
			fix_read_id_str += "zcat ${r1_files[0]} | seqtk rename - read > reads_R1.fastq\n"
		}
		if (r2_files.size() != 0) {
			fix_read_id_str += "zcat ${r2_files[0]} | seqtk rename - read > reads_R2.fastq\n"
		}
	} else {
		if (r1_files.size() != 0 ) {
			fix_read_id_str += "zcat ${r1_files[0]} > reads_R1.fastq\n"
		}
		if (r2_files.size() != 0 ) {
			fix_read_id_str += "zcat ${r2_files[0]} > reads_R2.fastq\n"
		}
	}


	def kraken_cmd = ""
	def postprocessing = ""

	if (r1_files.size() != 0) {		
		kraken_cmd += "${kraken2_call} --unclassified-out reads_decon_1.fastq --output stats/decon/${sample.id}.kraken_read_report_1.txt --report stats/decon/${sample.id}.kraken_report_1.txt reads_R1.fastq\n"
		
		if (r2_files.size() != 0) {
			kraken_cmd += "${kraken2_call} --unclassified-out reads_decon_2.fastq --output stats/decon/${sample.id}.kraken_read_report_2.txt --report stats/decon/${sample.id}.kraken_report_2.txt reads_R2.fastq\n"
			
			postprocessing += """
			if [[ -f reads_decon_1.fastq || -f reads_decon_2.fastq ]]; then

				paste <(cut -f 1,2 stats/decon/${sample.id}.kraken_read_report_1.txt) <(cut -f 1,2 stats/decon/${sample.id}.kraken_read_report_2.txt) | \
					awk -v sample=${sample.id} 'BEGIN { keep=0; drop=0; } /^U/ && \$1==\$3 { printf("%s\\t%s\\n", \$2, \$4); keep++; next; } { drop++;} END { printf("%s\\t%s\\t%s\\n", sample, keep, drop) > "${sample.id}.kraken2.txt" }' \
					> keep.txt

				cut -f 1 keep.txt > keep1.txt
				cut -f 2 keep.txt > keep2.txt

				seqtk subseq reads_decon_1.fastq keep1.txt > no_host/${sample.id}/${sample.id}_R1.fastq
				if [[ ! -s no_host/${sample.id}/${sample.id}_R1.fastq ]]; then
					seqtk subseq reads_decon_1.fastq <(sed "s:\$:/1:" keep1.txt) > no_host/${sample.id}/${sample.id}_R1.fastq
				fi

				seqtk subseq reads_decon_2.fastq keep2.txt > no_host/${sample.id}/${sample.id}_R2.fastq
				if [[ ! -s no_host/${sample.id}/${sample.id}_R2.fastq ]]; then
					seqtk subseq reads_decon_2.fastq <(sed "s:\$:/2:" keep2.txt) > no_host/${sample.id}/${sample.id}_R2.fastq
				fi

				if [[ -s no_host/${sample.id}/${sample.id}_R1.fastq ]]; then gzip -v no_host/${sample.id}/${sample.id}_R1.fastq; fi &
				if [[ -s no_host/${sample.id}/${sample.id}_R2.fastq ]]; then gzip -v no_host/${sample.id}/${sample.id}_R2.fastq; fi &
				wait
			
			fi
			"""

		} else {

			postprocessing += """
			if [[ -f reads_decon_1.fastq ]]; then
				mv reads_decon_1.fastq no_host/${sample.id}/${sample.id}_R1.fastq
				gzip -v no_host/${sample.id}/*.fastq

				awk -v sample=${sample.id} 'BEGIN { keep=0; drop=0; } /^U/ { keep++; next; } { drop++;} END { printf("%s\\t%s\\t%s\\n", sample, keep, drop) > "${sample.id}.kraken2.txt" }' stats/decon/${sample.id}.kraken_read_report_1.txt
			fi				"""

		}

	}

	"""
	set -e -o pipefail

	mkdir -p no_host/${sample.id} stats/decon/ 

	${fix_read_id_str}
	${kraken_cmd}
	${postprocessing}

	touch no_host/${sample.id}/KRAKEN_FINISHED
	"""
}


process remove_host_kraken2 {
	container "registry.git.embl.org/schudoma/kraken2-docker:latest"
	label 'kraken2'

    input:
    tuple val(sample), path(fq)
	path(kraken_db)

    output:
    tuple val(sample), path("no_host/${sample.id}/${sample.id}_R*.fastq.gz"), emit: reads

    script:
    def out_options = (sample.is_paired) ? "--paired --unclassified-out ${sample.id}#.fastq" : "--unclassified-out ${sample.id}_1.fastq"
    def move_r2 = (sample.is_paired) ? "gzip -c ${sample.id}_2.fastq > no_host/${sample.id}/${sample.id}_R2.fastq.gz" : ""

	def kraken2_call = "kraken2 --threads $task.cpus --db ${kraken_db} --report-minimizer-data --gzip-compressed --minimum-hit-groups ${params.kraken2_min_hit_groups}"

    """
    mkdir -p no_host/${sample.id}
	mkdir -p stats/decon/

    ${kraken2_call} ${out_options} --output stats/decon/${sample.id}.kraken_read_report.txt --report stats/decon/${sample.id}.kraken_report.txt $fq

    gzip -c ${sample.id}_1.fastq > no_host/${sample.id}/${sample.id}_R1.fastq.gz
    ${move_r2}
    """
}
