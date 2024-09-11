#!/bin/bash

# ------------------ Usage ------------------------------------------------

usage(){
cat << EOF

Usage: $(basename "$0") -a <reference.gtf> -o <output/directory>

Create a BED file containing gene intervals.

OPTIONS:
	-a	FILE			Annotation file in GTF format.
	-o	DIR 			Output directory.
	-h	    			Show this message.

EOF
}

# ------------------ Flag Processing --------------------------------------

if [ -z "$1" ]; then
	usage
	exit 1
fi

while getopts 'a:o:h' OPTION; do
	case "$OPTION" in
		
		a)
			if [ -e "$(readlink -f "$OPTARG")" ] && [[ "$(readlink -f "$OPTARG")" == *.gtf ]]; then
				ann="$(readlink -f "$OPTARG")"
			else
				echo -e 1>&2 "Argument passed to '-$OPTION' must be a .gtf file"
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

bedtools sort \
	-i <(awk \
		'BEGIN{
			FS = OFS = "\t"
		} 
		{
			if ($3 == "gene") 
			{
				print $1, $4 - 1, $5
			}
		}' \
		"$ann") \
	> "$out"/genes.bed

exit 0