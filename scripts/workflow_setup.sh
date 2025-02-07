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

partOnly=0
extraLayer=0
workflowName="$PWD"

# ------------------ Functions --------------------------------------------

speciesAbbreviation() {
    genus=${1%%_*}; genus=${genus::3}; genus=${genus^}
    species=${1##*_}; species=${species::3}; species=${species^}
    echo -n "$genus""$species"
}

nameWorkflow() {
    read -p "Enter name of workflow: " workflowName
    if [[ "$workflowName" == @(" "|"") ]]; then
        echo "Workflow must have a name!"
        nameWorkflow
    elif [ -d "$workflowName" ]; then
        echo "'$workflowName' already exists!"
        nameWorkflow
    fi
}

namePart() {
    read -p "Enter name of workflow part: " partName
    if [[ "$partName" == @(" "|"") ]]; then
        echo "Workflow part must have a name!"
        namePart
    elif [ -d "$partName" ]; then
        echo "'$partName' already exists!"
        namePart
    fi
}

nameDivider() {
    read -p "Enter name of divider: " dividerName
    if [[ "$dividerName" == @(" "|"") ]]; then
        echo "Workflow divider must have a name!"
        nameDivider
    elif [ -d "$dividerName" ]; then
        echo "'$dividerName' already exists!"
        nameDivider
    fi
}

nameSpecies() {
    read -p "Enter species name using '_' instead of space: " speciesName
    if [[ "$speciesName" == @(" "|"") ]]; then
        echo "Species name must be entered!"
        namePart
    fi
    speciesName=${speciesName^}
}

makeDirectories() {
    if [ "$partOnly" == 1 ]; then
        echo -ne "Create new workflow part at:\n'$PWD'?"
        read -p " (Y/n): " answer
    else
        echo -ne "Create new workflow at:\n'$PWD'?"
        read -p " (Y/n): " answer
    fi
    if [[ "$answer" == @("yes"|"Yes"|"y"|"Y"|"") ]]; then
        [ "$partOnly" == 1 ] || nameWorkflow
        # name_part
        [ "$extraLayer" == 1 ] && nameDivider
        nameSpecies
        if [ -n "$workflowName" ] && [ "$workflowName" != "$PWD" ]; then
            mkdir -m 774 "$workflowName"
            mkdir -m 774 "$workflowName"/workflow_source
            echo -e "#!/bin/env python3\nfrom gwf import AnonymousTarget\nimport os, glob\n\n########################## Functions ##########################\n" > "$workflowName"/workflow_source/workflow_templates.py
            # Inserts function I use a lot
            echo -e "def speciesAbbreviation(speciesName: str) -> str:\n\t\"\"\"Creates species abbreviation from species name.\n\n\t:param str speciesName:\n\t\tSpecies name written as *genus* *species*\"\"\"\n\tgenus, species = speciesName.replace(' ', '_').split('_')\n\tgenus = genus[0].upper() + genus[1:3]\n\tspecies = species[0].upper() + species[1:3]\n\treturn genus + species" >> "$workflowName"/workflow_source/workflow_templates.py
            echo -e "#!/bin/env python3\nfrom gwf import Workflow\nfrom gwf.workflow import collect\nimport os, yaml, glob, sys\nfrom workflow_templates import *" > "$workflowName"/workflow_source/workflow_source.py
            echo -e "# The name of the relevant project account.\naccount: \n# Name of species being analyzed\nspeciesName: \n# Directory for intermediary files.\nworkingDirectoryPath: \n# Directory for final output files.\noutputDirectoryPath: " > "$workflowName"/workflow_source/template.config.yaml
            echo -e "This directory contains:\n\t- workflow_source.py - All relevant workflows in one place.\n\t- workflow_templates - All templates used by worflow_source.py.\n\t- template.config.yaml - Blank template configuration file.\n\t- Software directory." > "$workflowName"/workflow_source/README.txt
            mkdir -m 774 "$workflowName"/workflow_source/software
            echo -e "This directory contains software dependencies for the workflow not installable by conda" > "$workflowName"/workflow_source/software/README.txt
        fi
        mkdir -m 774 "$workflowName"/configurations
        echo -e "This directory contains sub-directories with configuration files for different runs of the workflow" > "$workflowName"/configurations/README.txt
        if [ -n "$dividerName" ]; then
            mkdir -m 774 "$workflowName"/configurations/"$dividerName"
            mkdir -m 774 "$workflowName"/configurations/"$dividerName"/"$speciesName"
            echo -e "# The name of the relevant project account.\naccount: EcoGenetics\n# Name of species being analyzed\nspeciesName: ${speciesName/_/\ }\n# Directory for intermediary files.\nworkingDirectoryPath: \n# Directory for final output files.\noutputDirectoryPath: " > "$workflowName"/configurations/"$dividerName"/"$speciesName"/"$(speciesAbbreviation "$speciesName")".config.yaml
            echo -e "#!/bin/env python3\nimport sys, os\nsys.path.insert(0, os.path.realpath('../../../workflow_source/'))\nfrom workflow_source import *\n\ngwf = " > "$workflowName"/configurations/"$dividerName"/"$speciesName"/workflow.py
            echo "New workflow has been created..."
        else
            mkdir -m 774 "$workflowName"/configurations/"$speciesName"
            echo -e "# The name of the relevant project account.\naccount: EcoGenetics\n# Name of species being analyzed\nspecies_name: ${speciesName/_/\ }\n# Directory for intermediary files.\nworkingDirectoryPath: \n# Directory for final output files.\noutputDirectoryPath: " > "$workflowName"/configurations/"$speciesName"/"$(speciesAbbreviation "$speciesName")".config.yaml
            echo -e "#!/bin/env python3\nimport sys, os\nsys.path.insert(0, os.path.realpath('../../workflow_source/'))\nfrom workflow_source import *\n\ngwf = " > "$workflowName"/configurations/"$speciesName"/workflow.py
            echo "New workflow has been created..."
        fi
    elif [[ "$answer" == @("no"|"No"|"n"|"N") ]]; then
        echo "Cancelling..."
        exit 0
    else
        echo "Unrecognized response"
        makeDirectories
    fi
}

# ------------------ Flag Processing --------------------------------------

# if [ -z "$1" ]; then
#    make_directories
# fi

while getopts 'pxh' OPTION; do
    case "$OPTION" in
        p)
            partOnly=1
            ;;
        x)
            extraLayer=1
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

makeDirectories
