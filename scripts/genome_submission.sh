#!/bin/bash

# ------------------ Usage ------------------------------------------------

usage(){
cat << EOF



EOF
}

# ------------------ Configuration ----------------------------------------

address=ftp-private.ncbi.nlm.nih.gov

# ------------------ Flag Processing --------------------------------------

while getopts 'h' OPTION; do
	case "$OPTION" in
		
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

read -p 'USERNAME: ' username
read -s -p 'PASSWORD: ' password
read -p 'NAME OF SUBMISSION DIRECTORY: ' subdir

lftp "$address" -u "$username,$password" -e "cd uploads/jeppe.bayer_bio.au.dk_shjiB7tm; mkdir -p $subdir; cd $subdir"

exit 0