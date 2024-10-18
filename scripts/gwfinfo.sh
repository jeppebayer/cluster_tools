#!/bin/bash

# ------------------ Usage ------------------------------------------------

usage(){
cat << EOF

Usage: gwfinfo <jobname>

Make output from 'gwf info' more readable.

EOF
}

if [ -z "$1" ]; then
	usage
	exit 1
fi

echo -e "$(gwf info "$1")" | less -S

exit 0