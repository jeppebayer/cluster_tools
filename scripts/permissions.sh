#!/bin/bash

# ------------------ Usage ------------------------------------------------

usage(){
cat << EOF

Usage: $(basename "$0") [OPTIONS] <keyword>

Silly tool to help manage data permissions.

OPTIONS:
	-l			Lock. Sets permission of directories to 'read-only'.
	-u			Unlock. Sets permission of directories to 'write'.
	-k			Keywords. Lists keywords and their associated directories.
	-o			Ownership. Moves all files in the directories into new
				directories with identical directories owned by user and
				removes old directories.
	-s			Status. Summarises the permisson settings of directories.
	-d			Detail. Lists all sub-directories verbosely to inspect
				permisson settings.
	-h			Help. Show this message.

EOF
}

# ------------------ Configuration ----------------------------------------

basepath="/faststorage/project/EcoGenetics/BACKUP"

declare -A sections
sections["popgen"]="$basepath/population_genetics/fastq/*/*/* $basepath/population_genetics/reference_genomes/*/*"
sections["collembola"]="$basepath/population_genetics/fastq/collembola/*/* $basepath/population_genetics/reference_genomes/collembola/*"
sections["beetles"]="$basepath/population_genetics/fastq/beetles/*/* $basepath/population_genetics/reference_genomes/beetles/*"
sections["spiders"]="$basepath/population_genetics/fastq/spiders/*/* $basepath/population_genetics/reference_genomes/spiders/*"
sections["museomics"]="$basepath/museomics/fastq/*/*/* $basepath/museomics/reference_genomes/*/"
sections["denmark"]="$basepath/museomics/fastq/denmark/*/*"
sections["finland"]="$basepath/museomics/fastq/finland/*/*"
sections["mreference"]="$basepath/museomics/reference_genomes/*"
sections["assembly"]="$basepath/genome_assembly_and_annotation/*/*"
sections["x"]="$basepath/fastq/individual_data/*/* $basepath/fastq/population_data/*/* $basepath/reference_genomes/*"
sections["encalb"]="$basepath/Enchytraeus_albidus/fastq/* $basepath/Enchytraeus_albidus/reference_genome/*"
sections["microflora"]="$basepath/population_genetics//microflora_danica/*"

declare -A status
status["popgen"]="$basepath/population_genetics/fastq/*/* $basepath/population_genetics/reference_genomes/*"
status["collembola"]="$basepath/population_genetics/fastq/collembola/* $basepath/population_genetics/reference_genomes/collembola"
status["beetles"]="$basepath/population_genetics/fastq/beetles/* $basepath/population_genetics/reference_genomes/beetles"
status["spiders"]="$basepath/population_genetics/fastq/spiders/* $basepath/population_genetics/reference_genomes/spiders"
status["museomics"]="$basepath/museomics/fastq/*/* $basepath/museomics/reference_genomes"
status["denmark"]="$basepath/museomics/fastq/denmark/*"
status["finland"]="$basepath/museomics/fastq/finland/*"
status["mreference"]="$basepath/museomics/reference_genomes"
status["assembly"]="$basepath/genome_assembly_and_annotation/*"
status["x"]="$basepath/faster_x_evolution/fastq/individual_data/* $basepath/faster_x_evolution/fastq/population_data/* $basepath/faster_x_evolution/reference_genomes"
status["encalb"]="$basepath/Enchytraeus_albidus/fastq $basepath/Enchytraeus_albidus/reference_genome"
status["microflora"]="$basepath/population_genetics/microflora_danica"

declare -A descriptions
descriptions["popgen"]="population_genetics/fastq/*\tpopulation_genetics/reference_genomes/*"
descriptions["collembola"]="population_genetics/fastq/collembola/*"
descriptions["beetles"]="population_genetics/fastq/beetles/*"
descriptions["spiders"]="population_genetics/fastq/spiders/*"
descriptions["museomics"]="museomics/fastq/*\tmuseomics/reference_genomes/*"
descriptions["denmark"]="museomics/fastq/denmark/*"
descriptions["finland"]="museomics/fastq/finlands/*"
descriptions["mreference"]="museomics/reference_genomes/*"
descriptions["assembly"]="genome_assembly_and_annotation/*"
descriptions["x"]="faster_x_evolution/*"
descriptions["encalb"]="Enchytraeus_albidus/*"
descriptions["microflora"]="population_genetics/microflora_danica/*"

# ------------------ Functions --------------------------------------------

ownership() {
	mv "$1" "$1".temp
	mkdir "$1"
	mv "$1".temp/* "$1"
	rm -rf "$1".temp
}

sectionstatus() {
	echo -e "\n$1"
	ls -lh "$1" \
	| awk \
		'BEGIN{OFS = "\t"}
		{if (NR > 1) 
			{perarray[$1] += 1}}
		END{print "-----------------"
			print "Permissions", "N"
			print "-----------------"
			for (i in perarray)
				{print i, perarray[i]}
			print "Total", "", NR - 1}'
}

detailedstatus() {
	(echo "$1"; ls -lh "$1") | less
}

# ------------------ Flag Processing --------------------------------------

if [ -z "$1" ]; then
	usage
	exit 1
fi

while getopts 'lukosdh' OPTION; do
	case "$OPTION" in
		l)
			action="chmod ug-w"
			;;
		u)
			action="chmod ug+w"
			;;
		k)
			for i in "${!sections[@]}"; do
				echo -e "$i:\t\t${descriptions[$i]}"
			done
			exit 0
			;;
		o)
			action="o"
			;;
		s)
			action="s"
			;;
		d)
			action="d"
			;;
		h)
			usage
			exit 0
			;;
		\?)
			echo "Invalid option"
			exit 2
			;;
	esac
done

shift $((OPTIND-1))

# ------------------ Main -------------------------------------------------

if [ -z "$1" ]; then
	echo "Keyword must be supplied..."
	exit 1
fi

for i in "${!sections[@]}"; do
	if [ "$i" == "$1" ]; then
		if [ "$action" ]; then
			if [ "$action" == "o" ]; then
				for j in ${sections[$1]}; do
					if [ ! -d "$j" ]; then
						continue
					fi
					ownership "$j"
				done
			elif [ "$action" == "s" ]; then
				for j in ${status[$1]}; do
					if [ ! -d "$j" ]; then
						continue
					fi
					sectionstatus "$j"
				done
			elif [ "$action" == "d" ]; then
				for j in ${status[$1]}; do
					if [ ! -d "$j" ]; then
						continue
					fi
					detailedstatus "$j"
				done
			else
				for j in ${sections[$1]}; do
					if [ ! -d "$j" ]; then
						continue
					fi
					$action "$j"
				done
			fi
		else
			echo "Keyword exists..."
		fi
		exit 0
	fi
done

echo "Keyword does not exist..."

exit 0