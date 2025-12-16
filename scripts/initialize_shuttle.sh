#! /usr/bin/env bash

# initializes the directories for shuttle verification

# usage: initialize_shuttle.sh <shuttle_directory> <target_directory>
# <shuttle_directory> must contain user_projects.csv

RED="\e[41m"
GREEN="\e[42m"
YELLOW="\e[43m"
RESET="\e[0m"

if [[ $# < 1 || $# > 2 ]]; then
	printf "${YELLOW}usage: initialize_shuttle.sh <source_directory> [<target_directory>]${RESET}\n"
	exit 1
fi

source_directory=$1
csv_file=$source_directory/user_projects.csv
if [[ ! -f $csv_file ]]; then
	printf "${RED}Could not find $csv_file${RESET}\n"
	exit 2
fi

if [[ $# > 1 ]]; then
	target_directory=$2
else
	target_directory=${source_directory##*/}
fi
run_directory=$PWD

printf "${GREEN}creating in $target_directory${RESET}\n"


while IFS=',' read -r slot user design id type other; do
	if [[ "$slot" == "N" ]]; then
		continue
	fi
	slot=$( printf "slot-%02d" "$slot" )
	echo "
Creating $slot and linking data from $user/$design"
	mkdir -p $target_directory/$slot
	pushd $target_directory/$slot 2>&1 >/dev/null
	find . -maxdepth 1 -type l -exec rm {} \;
	ln -s $source_directory/$user/$design/* .
	case "$type" in
		digital)
			top=caravel
			;;
		analog)
			top=caravan
			;;
		openframe)
			top=caravel_openframe
			;;
	esac
	if [[ ! -d tapeout/outputs/oas ]]; then
		printf "${RED}Missing tapeout/oasis/oas directory${RESET}\n"
	else
		if [[ ! -f $top.gds.gz ]]; then
			echo "Creating $top.gds"
			# convert oasis to gds and create user_top file with wrapper cell name
			klayout -b -r $run_directory/oas2gds.py \
				-rd input_oas=tapeout/outputs/oas/caravel_$id.oas \
				-rd output_gds=$top.gds.gz \
				-rd top_cell=$top
		fi
		if find tapeout/outputs/oas -newer $top.gds.gz | grep -q .; then 
			printf "${RED}WARNING: $top.gds.gz is out of date.${RESET}\n"
		fi
	fi
	head -v user_top
	popd 2>&1 >/dev/null
done <"$csv_file"
