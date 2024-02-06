#!/bin/bash
# ------------------ Usage ------------------------------------------------

usage(){
cat << EOF

Usage: $(basename "$0") [-p] [-x] [-h]

Setup initial directory structure for a GWF workflow.

OPTIONS:
    -p                  Only create a new workflow subsection.
    -x                  Add extra divider directory.
    -h                  Show this usage message.

EOF
}

# ------------------ Configuration ----------------------------------------

part_only=0
extra_layer=0
workflow_name="$PWD"

# ------------------ Functions --------------------------------------------

species_abbreviation() {
    genus=${1%%_*}; genus=${genus::3}; genus=${genus^}
    species=${1##*_}; species=${species::3}; species=${species^}
    echo -n "$genus""$species"
}

name_workflow() {
    read -p "Enter name of workflow: " workflow_name
    if [[ "$workflow_name" == @(" "|"") ]]; then
        echo "Workflow must have a name!"
        name_workflow
    elif [ -d "$workflow_name" ]; then
        echo "'$workflow_name' already exists!"
        name_workflow
    fi
}

name_part() {
    read -p "Enter name of workflow part: " part_name
    if [[ "$part_name" == @(" "|"") ]]; then
        echo "Workflow part must have a name!"
        name_part
    elif [ -d "$part_name" ]; then
        echo "'$part_name' already exists!"
        name_part
    fi
}

name_divider() {
    read -p "Enter name of divider: " divider_name
    if [[ "$divider_name" == @(" "|"") ]]; then
        echo "Workflow divider must have a name!"
        name_divider
    elif [ -d "$divider_name" ]; then
        echo "'$divider_name' already exists!"
        name_divider
    fi
}

name_species() {
    read -p "Enter species name using '_' instead of space: " species_name
    if [[ "$species_name" == @(" "|"") ]]; then
        echo "Species name must be entered!"
        name_part
    fi
    species_name=${species_name^}
}

make_directories() {
    if [ "$part_only" == 1 ]; then
        echo -ne "Create new workflow part at:\n'$PWD'?"
        read -p " (Y/n): " answer
    else
        echo -ne "Create new workflow at:\n'$PWD'?"
        read -p " (Y/n): " answer
    fi
    if [[ "$answer" == @("yes"|"Yes"|"y"|"Y"|"") ]]; then
        [ "$part_only" == 1 ] || name_workflow
        # name_part
        [ "$extra_layer" == 1 ] && name_divider
        name_species
        if [ -n "$workflow_name" ] && [ "$workflow_name" != "$PWD" ]; then
            mkdir -m 774 "$workflow_name"
            mkdir -m 774 "$workflow_name"/workflow_source
            echo -e "#!/bin/env python3\nfrom gwf import AnonymousTarget\nimport os, glob\n\n########################## Functions ##########################\n" > "$workflow_name"/workflow_source/workflow_templates.py
            # Inserts function I use a lot
            echo -e "def species_abbreviation(species_name: str) -> str:\n\t\"\"\"Creates species abbreviation from species name.\n\n\t:param str species_name:\n\t\tSpecies name written as *genus* *species*\"\"\"\n\tgenus, species = species_name.replace(' ', '_').split('_')\n\tgenus = genus[0].upper() + genus[1:3]\n\tspecies = species[0].upper() + species[1:3]\n\treturn genus + species" >> "$workflow_name"/workflow_source/workflow_templates.py
            echo -e "#!/bin/env python3\nfrom gwf import Workflow\nfrom gwf.workflow import collect\nimport os, yaml, glob, sys\nfrom workflow_templates import *" > "$workflow_name"/workflow_source/workflow_source.py
            echo -e "# The name of the relevant project account.\naccount: \n# Name of species being analyzed\nspecies_name: \n# Directory for intermediary files.\nworking_directory_path: \n# Directory for final output files.\noutput_directory_path: " > "$workflow_name"/workflow_source/template.config.yaml
            echo -e "This directory contains:\n\t- workflow_source.py - All relevant workflows in one place.\n\t- workflow_templates - All templates used by worflow_source.py.\n\t- template.config.yaml - Blank template configuration file.\n\t- Software directory." > "$workflow_name"/workflow_source/README.txt
            mkdir -m 774 "$workflow_name"/workflow_source/software
            echo -e "This directory contains software dependencies for the workflow not installable by conda" > "$workflow_name"/workflow_source/software/README.txt
        fi
        mkdir -m 774 "$workflow_name"/configurations
        echo -e "This directory contains sub-directories with configuration files for different runs of the workflow" > "$workflow_name"/configurations/README.txt
        if [ -n "$divider_name" ]; then
            mkdir -m 774 "$workflow_name"/configurations/"$divider_name"
            mkdir -m 774 "$workflow_name"/configurations/"$divider_name"/"$species_name"
            echo -e "# The name of the relevant project account.\naccount: EcoGenetics\n# Name of species being analyzed\nspecies_name: ${species_name/_/\ }\n# Directory for intermediary files.\nworking_directory_path: \n# Directory for final output files.\noutput_directory_path: " > "$workflow_name"/configurations/"$divider_name"/"$species_name"/"$(species_abbreviation "$species_name")".config.yaml
            echo -e "#!/bin/env python3\nimport sys, os\nsys.path.insert(0, os.path.realpath('../../../workflow_source/'))\nfrom workflow_source import *\n\ngwf = " > "$workflow_name"/configurations/"$divider_name"/"$species_name"/workflow.py
            echo "New workflow has been created..."
        else
            mkdir -m 774 "$workflow_name"/configurations/"$species_name"
            echo -e "# The name of the relevant project account.\naccount: EcoGenetics\n# Name of species being analyzed\nspecies_name: ${species_name/_/\ }\n# Directory for intermediary files.\nworking_directory_path: \n# Directory for final output files.\noutput_directory_path: " > "$workflow_name"/configurations/"$species_name"/"$(species_abbreviation "$species_name")".config.yaml
            echo -e "#!/bin/env python3\nimport sys, os\nsys.path.insert(0, os.path.realpath('../../workflow_source/'))\nfrom workflow_source import *\n\ngwf = " > "$workflow_name"/configurations/"$species_name"/workflow.py
            echo "New workflow has been created..."
        fi
    elif [[ "$answer" == @("no"|"No"|"n"|"N") ]]; then
        echo "Cancelling..."
        exit 0
    else
        echo "Unrecognized response"
        make_directories
    fi
}

# ------------------ Flag Processing --------------------------------------

if [ -z "$1" ]; then
    make_directories
fi

while getopts 'pxh' OPTION; do
    case "$OPTION" in
        p)
            part_only=1
            ;;
        x)
            extra_layer=1
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

# ------------------ Main -------------------------------------------------

make_directories