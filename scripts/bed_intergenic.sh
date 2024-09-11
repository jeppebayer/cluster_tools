#!/bin/bash

# ------------------ Usage ------------------------------------------------

usage(){
cat << EOF

Usage: $(basename "$0") -g <genes.bed> -r <reference.fa|reference.fa.gz> -o <output/directory>

Create a BED file containing intergenic intervals.

OPTIONS:
	-g	FILE			Gene BED file.
	-r	FILE			Reference genome file. Can be gzipped.
	-o	DIR 			Output directory.
	-h	    			Show this message.

EOF
}

# ------------------ Flag Processing --------------------------------------

if [ -z "$1" ]; then
	usage
	exit 1
fi

while getopts 'g:r:o:h' OPTION; do
	case "$OPTION" in
		
		g)
			if [ -e "$(readlink -f "$OPTARG")" ] && [[ "$(readlink -f "$OPTARG")" == *.bed ]]; then
				gene="$(readlink -f "$OPTARG")"
			else
				echo -e 1>&2 "Argument passed to '-$OPTION' must be a .bed file"
				exit 3
			fi
			;;
		r)
			if [ -e "$(readlink -f "$OPTARG")" ]; then
				ref="$(readlink -f "$OPTARG")"
			else
				echo -e 1>&2 "Argument passed to '-$OPTION' must be a file"
				exit 3
			fi
			;;
		o)
			if [ -d "$(readlink -f "$OPTARG")" ]; then
				out="$(readlink -f "$OPTARG")"
			else
				echo -e 1>&2 "Argument passed to '-$OPTION' must be a directory"
				exit 3
			fi
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

# ------------------ Main -------------------------------------------------

# Sources necessary environment
if [ "$USER" == "jepe" ]; then
	# shellcheck disable=1090
	source /home/"$USER"/.bashrc
	#shellcheck disable=1091
	source activate popgen
fi

bedtools complement \
	-i "$gene" \
	-g <(awk \
			'BEGIN{
				RS = ">"
				ORS = "\n"
				FS = "\n"
				OFS = "\t"
			}
			{
				if (FNR == 1)
				{
					next
				}
				split($1, namearray, " ")
				chromname = namearray[1]
				$1 = ""
				print chromname, length($0) - NF + 1
			}' \
			"$ref") \
	> "$out"/intergenic.bed

exit 0