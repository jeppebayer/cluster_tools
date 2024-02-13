#!/bin/bash

# ------------------ Usage ------------------------------------------------

usage(){
cat << EOF

Usage: $(basename "$0") [-r] [-h]

Start JuiceBox.
Request resources:
    srun --cpus-per-task=2 --mem=100g --time=06:00:00 --account=EcoGenetics --pty bash

OPTIONS:
    -r                  Run JuiceBox.
    -h                  Show this usage message.

EOF
}

# ------------------ Configuration ----------------------------------------

juicebox=/faststorage/project/EcoGenetics/people/Jeppe_Bayer/genome_assembly_and_annotation/scripts/HiC_scaffolding/workflow_source/software/Juicebox_1.11.08.jar

# ------------------ Flag Processing --------------------------------------

if [ -z "$1" ]; then
    usage
fi

while getopts 'rh' OPTION; do
    case "$OPTION" in
        r)
            # Sources necessary environment
            if [ "$USER" == "jepe" ]; then
                # shellcheck disable=1090
                source /home/"$USER"/.bashrc
                #shellcheck disable=1091
                source activate assembly
            fi
            java -jar -Xmx100g "$juicebox"
            exit 0
            ;;
        h)
            usage
            exit 0
            ;;
        ?)
            usage
            exit 1
            ;;
    esac
done