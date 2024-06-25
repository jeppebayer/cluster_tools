#!/bin/bash

# Sources necessary environment
if [ "$USER" == "jepe" ]; then
	# shellcheck disable=1090
	source /home/"$USER"/.bashrc
	#shellcheck disable=1091
	source activate git
fi

repository_list=(
	/faststorage/project/EcoGenetics/people/Jeppe_Bayer/cluster_tools
	/faststorage/project/EcoGenetics/people/Jeppe_Bayer/cluster_tutorial
	/faststorage/project/EcoGenetics/people/Jeppe_Bayer/enchytraeus_albidus
	/faststorage/project/EcoGenetics/people/Jeppe_Bayer/faster_x_evolution
	/faststorage/project/EcoGenetics/people/Jeppe_Bayer/genome_assembly_and_annotation
	/faststorage/project/EcoGenetics/people/Jeppe_Bayer/miscellaneous
	/faststorage/project/EcoGenetics/people/Jeppe_Bayer/museomics
	/faststorage/project/EcoGenetics/people/Jeppe_Bayer/old_setup
	/faststorage/project/EcoGenetics/people/Jeppe_Bayer/population_genetics
	/faststorage/project/EcoGenetics/general_workflows
)

# ------------------ Usage ------------------------------------------------

usage(){
cat << EOF

Usage: $(basename "$0") [-c] [-l]

Script to minimize the amount of work to keep all repositories updated.

OPTIONS:
	-c				Commit and push all.
	-s				Get status of specific repository.
	-l				List all repositories checked by the script.
	-h				Show this message.

EOF
}

# ------------------ Functions --------------------------------------------

check_direcotry() {
	if [ ! -d "$1" ]; then
		echo -e "\n$1 does not seems to be a directory... exiting."
		exit 3
	else
		cd "$1"
	fi
}

check_repository() {
	if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	  echo -e "\nError: $PWD is not a Git repository."
	  exit 3
	fi
}

commit_and_push() {
	echo -e "\nRepository: $i"
	git add .
	git commit -m "$(date +"%d/%m-%Y")"
	git push origin main
}

# ------------------ Flag Processing --------------------------------------

if [ -z "$1" ]; then
	usage
	exit 1
fi

while getopts 'cs:lh' OPTION; do
	case "$OPTION" in
		c)
			for i in "${repository_list[@]}"; do
				check_direcotry "$i"
				check_repository
				commit_and_push "$i"
			done
			exit 0
			;;
		s)
			check_direcotry "${repository_list[$((OPTARG - 1))]}"
			check_repository
			git status
			exit 0
			;;
		l)
			n=1
			for i in "${repository_list[@]}"; do
				echo -e "$n.\t$i"
				((n++))
			done
			exit 0
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

exit 0