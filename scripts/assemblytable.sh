#!/bin/bash

# ------------------ Usage ------------------------------------------------

usage(){
cat << EOF

Usage: $(basename "$0") -a <annotation.gtf> -b <busco_table.txt> -r <repeatmasker_table.tbl> -s <species_name> [-h]

OPTIONS:
	-a				Path to annotation file.
	-b				Path to BUSCO summary table file.
	-r				Path to RepeatMasker full table file.
	-s				Species name. Spaces, ' ', must be replaced with underscore, '_'.
	-h				Show this message.

EOF
}

# ------------------ Functions --------------------------------------------

markdownformat() {
cat << EOF

| Genome Assembly |  |
| --- | :---: |
| Specimen | *$species_name* |
| Isolate | $isolate |
| Sequence coverage | $seq_coverage |
| Genome size ($unit_gs) | $genome_size |
| Gaps | $gaps |
| Number of contigs | $ncontigs |
| Contig N50 ($unit_n50) | $n50 |
| Number of chromosomes | $nchrom |
| Number of protein-coding genes | $ngenes |
| Mean exon length ($unit_mel) | $meanexon |
| Total exon length ($unit_tel) | $totalexon ($exonpctoftotal%) |
| Number of exons |  $nexon |
| Mean intron length ($unit_mit) | $meanintron |
| Total intron length ($unit_til) | $totalintron ($intronpctoftotal%) |
| Number of introns | $nintron |
| Number of exons per gene | $exonpergene |
| GC content | $gc |
| Repeat content | $repeattotal |
| &nbsp; &nbsp; &nbsp; &nbsp; Unclassified | $repeatunclass |
| BUSCO* genome score | $busco |

*BUSCO scores based on the $buscoset BUSCO set using $buscoversion C=complete  [S=single copy, D=duplicated], F=fragmented, M=missing, n=number of orthologues in comparison.

RepeatMasker results: $repeatmaskfulltable

BUSCO result: $buscotable

Annotation result: $annotationgtf

EOF
}

tsvformat() {
cat << EOF

Genome assembly
Specimen\t$species_name
Isolate\t$isolate
Sequence coverage\t$seq_coverage
Genome size ($unit_gs)\t$genome_size
Gaps\t$gaps
Number of contigs\t$ncontigs
Contig N50 ($unit_n50)\t$n50
Number of chromosomes\t$nchrom
Number of protein-coding genes\t$ngenes
Mean exon length ($unit_mel)\t$meanexon
Total exon length ($unit_tel)\t$totalexon ($exonpctoftotal%)
Number of exons\t$nexon
Mean intron length ($unit_mit)\t$meanintron
Total intron length ($unit_til)\t$totalintron ($intronpctoftotal%)
Number of introns\t$nintron
Number of exons per gene\t$exonpergene
GC content\t$gc
Repeat content\t$repeattotal
Unclassified\t$repeatunclass
BUSCO* genome score\t$busco

*BUSCO scores based on the $buscoset BUSCO set using v5.5.0 C=complete  [S=single copy, D=duplicated], F=fragmented, M=missing, n=number of orthologues in comparison.

RepeatMasker results:\t$repeatmaskfulltable
BUSCO result:\t$buscotable
Annotation result:\t$annotationgtf

EOF
}

# ------------------ Flag Processing --------------------------------------

if [ -z "$1" ]; then
	usage
	exit 1
fi

while getopts 'a:b:r:s:h' OPTION; do
	case "$OPTION" in
		a)
			if [ -e "$(readlink -f "$OPTARG")" ]; then
				if [[ "$OPTARG" ==  *.gtf ]]; then
					annotationgtf="$(readlink -f "$OPTARG")"
				else
					echo -e 1>&2 "\nThe file supplied to '-$OPTION' should have the '.gtf' extension\n"
					exit 4
				fi
			else
				echo -e 1>&2 "\nCannot locate '$OPTARG'... '-$OPTION' must be supplied with a working filepath\n"
				exit 3
			fi
			;;
		b)
			if [ -e "$(readlink -f "$OPTARG")" ]; then
				if [[ "$OPTARG" ==  *.txt ]]; then
					buscotable="$(readlink -f "$OPTARG")"
				else
					echo -e 1>&2 "\nThe file supplied to '-$OPTION' should have the '.txt' extension\n"
					exit 4
				fi
			else
				echo -e 1>&2 "\nCannot locate '$OPTARG'... '-$OPTION' must be supplied with a working filepath\n"
				exit 3
			fi
			;;
		r)
			if [ -e "$(readlink -f "$OPTARG")" ]; then
				if [[ "$OPTARG" ==  *.tbl ]]; then
					repeatmaskfulltable="$(readlink -f "$OPTARG")"
				else
					echo -e 1>&2 "\nThe file supplied to '-$OPTION' should have the '.tbl' extension\n"
					exit 4
				fi
			else
				echo -e 1>&2 "\nCannot locate '$OPTARG'... '-$OPTION' must be supplied with a working filepath\n"
				exit 3
			fi
			;;
		s)
			species_name="${OPTARG//_/ }"
			;;
		h)
			usage
			exit 0
			;;
		?)
			usage
			exit 2
			;;
	esac
done

if [ -z "$annotationgtf" ]; then
	echo -e 1>&2 "\nYou must supply an argument to '-a'\n"
	exit 5
fi
if [ -z "$buscotable" ]; then
	echo -e 1>&2 "\nYou must supply an argument to '-b'\n"
	exit 5
fi
if [ -z "$repeatmaskfulltable" ]; then
	echo -e 1>&2 "\nYou must supply an argument to '-r'\n"
	exit 5
fi
if [ -z "$species_name" ]; then
	echo -e 1>&2 "\nYou must supply an argument to '-s'\n"
	exit 5
fi

# ------------------ Main -------------------------------------------------

buscotablevalues=$(
	awk \
	'BEGIN{
	FS = "\t"
	OFS = "|"
	}
	{
	if (NR == 2)
		{split($0, line2v1, ":")
		split(line2v1[2], line2v2, " ")
		buscoset = line2v2[1]}
	if ($2 ~ /^C:.*\[S:.*,D:.*\],F:.*,M:.*,n:[0-9]*/)
		{busco = $2}
	if ($3 == "Number of scaffolds")
		{nchrom = $2}
	if ($3 == "Number of contigs")
		{ncontigs = $2}
	if ($3 == "Total length")
		{genome_size = $2
		if (length(genome_size) > 3 && length(genome_size) <= 6)
			{unit_gs = "KB"
			genome_size_rounded = int(genome_size / 1000 * 10 + 0.5) / 10}
		if (length(genome_size) > 6 && length(genome_size) <= 9)
			{unit_gs = "MB"
			genome_size_rounded = int(genome_size / 1000000 * 10 + 0.5) / 10}
		if (length(genome_size) > 9)
			{unit_gs = "GB"
			genome_size_rounded = int(genome_size / 1000000000 * 10 + 0.5) / 10}
		}
	if ($3 == "Percent gaps")
		{gaps = $2}
	if ($3 == "Contigs N50")
		{split($2, n50info, " ")
		n50 = n50info[1]
		unit_n50 = n50info[2]}
	if ($2 ~ /^busco:/)
		{split($2, buscoversioninfo, " ")
		buscoversion = "v"buscoversioninfo[2]}
	}
	END{
	print unit_gs, genome_size_rounded, gaps, ncontigs, unit_n50, n50, nchrom, busco, buscoset, buscoversion, genome_size
	}' \
	"$buscotable"
)

readarray -d "|" -t buscoarray <<< "$buscotablevalues"
unit_gs=${buscoarray[0]}
genome_size=${buscoarray[1]}
gaps=${buscoarray[2]}
ncontigs=${buscoarray[3]}
unit_n50=${buscoarray[4]}
n50=${buscoarray[5]}
nchrom=${buscoarray[6]}
busco=${buscoarray[7]}
buscoset=${buscoarray[8]}
buscoversion=${buscoarray[9]}
genome_size_raw=${buscoarray[10]//$'\n'/}

annotationgtfvalues=$(
	awk \
	'function unit(size) {
		len = length(size)
		if (len > 0 && len <= 3)
			{return "BP"}
		if (len > 3 && len <= 6)
			{return "KB"}
		if (len > 6 && len <= 9)
			{return "MB"}
		if (len > 9)
			{return "GB"}
		}
	function roundnodecimal(num) {
		if (num - int(num) >= 0.5)
			{return int(num) + 1}
		else
			{return int(num)}
		}
	function round1decimalunit(num, unit) {
		if (unit == "KB")
			{return int(num / 1000 * 10 + 0.5) / 10}
		if (unit == "MB")
			{return int(num / 1000000 * 10 + 0.5) / 10}
		if (unit == "GB")
			{return int(num / 1000000000 * 10 + 0.5) / 10}
		}
	function round1decimal(num) {
		return int(num * 10 + 0.5) / 10
		}
	BEGIN{
	FS = "\t"
	OFS = "|"
	}
	{
	if ($3 == "gene")
		{gene_sum += 1}
	if ($9 ~ /.t1/)
		{if ($3 == "exon")
			{exon_length += $5 - $4 + 1
			exon_sum += 1}
		if ($3 == "intron")
			{intron_length += $5 - $4 + 1
			intron_sum += 1}
		}
	}
	END{
	print gene_sum, unit(roundnodecimal(exon_length / exon_sum)), roundnodecimal(exon_length / exon_sum), unit(exon_length), round1decimalunit(exon_length, unit(exon_length)), exon_sum, unit(roundnodecimal(intron_length / intron_sum)), roundnodecimal(intron_length / intron_sum), unit(intron_length), round1decimalunit(intron_length, unit(intron_length)), intron_sum, round1decimal(exon_sum / gene_sum), exon_length, intron_length
	}' \
	"$annotationgtf"
)

readarray -d "|" -t annotationgtfarray <<< "$annotationgtfvalues"
ngenes=${annotationgtfarray[0]}
unit_mel=${annotationgtfarray[1]}
meanexon=${annotationgtfarray[2]}
unit_tel=${annotationgtfarray[3]}
totalexon=${annotationgtfarray[4]}
nexon=${annotationgtfarray[5]}
unit_mit=${annotationgtfarray[6]}
meanintron=${annotationgtfarray[7]}
unit_til=${annotationgtfarray[8]}
totalintron=${annotationgtfarray[9]}
nintron=${annotationgtfarray[10]}
exonpergene=${annotationgtfarray[11]}
totalexonraw=${annotationgtfarray[12]}
totalintronraw=${annotationgtfarray[13]//$'\n'/}

repeatmaskfulltablevalues=$(
	awk \
	'BEGIN{
	FS = " "
	OFS = "|"
	}
	{
	if ($0 ~ /bases masked:/)
		{gsub(/\s/, "")
		split($0, masked, "(")
		repeattotal = substr(masked[2], 1, length(masked[2]) - 1)}
	if ($0 ~ /Unclassified:/)
		{gsub(/\s/, "")
		split($0, unclass, "bp")
		repeatunclass = unclass[2]}
	}
	END{
	print repeattotal, repeatunclass
	}' \
	"$repeatmaskfulltable"
)

readarray -d "|" -t repeatmaskfulltablearray <<< "$repeatmaskfulltablevalues"
repeattotal=${repeatmaskfulltablearray[0]}
repeatunclass=${repeatmaskfulltablearray[1]//$'\n'/}

exonpctoftotal=$(
	awk \
	-v totalsize="$genome_size_raw" \
	-v totalexon="$totalexonraw" \
	'function round2decimal(num) {
		return int(num * 100 + 0.5) / 100
		}
	BEGIN{
	print round2decimal(totalexon / totalsize * 100)
	exit}'
)

intronpctoftotal=$(
	awk \
	-v totalsize="$genome_size_raw" \
	-v totalexon="$totalintronraw" \
	'function round2decimal(num) {
		return int(num * 100 + 0.5) / 100
		}
	BEGIN{
	print round2decimal(totalexon / totalsize * 100)
	exit}'
)

markdownformat

tsvformat
