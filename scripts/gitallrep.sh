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
)

for i in "${repository_list[@]}"; do
	cd "$i" || echo "$i does not seems to be a directory... skipping."
	git add .
	git commit -m "$(date +"%d/%m-%Y")"
	git push origin main
	echo "chip"
done


	# /faststorage/project/EcoGenetics/people/Jeppe_Bayer/cluster_tutorial
	# /faststorage/project/EcoGenetics/people/Jeppe_Bayer/enchytraeus_albidus
	# /faststorage/project/EcoGenetics/people/Jeppe_Bayer/faster_x_evolution
	# /faststorage/project/EcoGenetics/people/Jeppe_Bayer/genome_assembly_and_annotation
	# /faststorage/project/EcoGenetics/people/Jeppe_Bayer/miscellaneous
	# /faststorage/project/EcoGenetics/people/Jeppe_Bayer/museomics
	# /faststorage/project/EcoGenetics/people/Jeppe_Bayer/old_setup
	# /faststorage/project/EcoGenetics/people/Jeppe_Bayer/population_genetics
	# /faststorage/project/EcoGenetics/general_workflows
	# /faststorage/project/EcoGenetics/utility_scripts

exit 0