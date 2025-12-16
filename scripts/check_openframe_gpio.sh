#! /usr/bin/env bash

# checks the openframe gpio configuration and settings

# usage: check_openframe_gpio.sh [<slot_list>]
# default is to run all slots

if (( $# > 0 )); then
	slot_args=("$@")
else
	slot_args=("1-40")
fi

slot_list=()
for slot_arg in "${slot_args[@]}"; do
	if [[ "$slot_arg" =~ ^[0-9]+$ ]]; then
		#echo "adding $slot_arg"
		slot_list+=("$(printf "%02d" "$slot_arg")")
	elif [[ "$slot_arg" =~ ^([0-9]+)-([0-9]+)$ ]]; then
		range_start=${BASH_REMATCH[1]}
		range_end=${BASH_REMATCH[2]}
		for ((slot=range_start; slot<=range_end; slot++)); do
			#echo "adding $slot"
			slot_list+=("$(printf "%02d" "$slot")")
		done
	fi
done


#echo "${slot_list[@]}"

for slot_index in "${slot_list[@]}"; do
	slot=slot-$slot_index
	[[ -d "$slot" ]] || continue  # skip missing directories
	pushd $slot 2>&1 > /dev/null
	if [[ -f user_top ]] && grep -q openframe user_top; then
		layout_top=$(cat user_top)
		user_top=$(cat user_top | sed 's/^.._//')
		echo $slot $user_top $layout_top
		if [[ ! -f lvs/$user_top/lvs_config.json ]]; then
			mkdir -p lvs/$user_top
			cp $LVS_ROOT/tech/$PDK/lvs_config.$user_top.json lvs/$user_top/lvs_config.json
		fi
		if [[ ! -f lvs/$user_top/cvc.power.$user_top ]]; then
			cp $LVS_ROOT/tech/$PDK/cvc.power.$user_top lvs/$user_top/.
		fi
		UPRJ_ROOT=$PWD WORK_ROOT=$PWD/work/$user_top $LVS_ROOT/run_openframe_check --noextract lvs/$user_top/lvs_config.json $layout_top *gds.gz 2>&1 |
			tee gpio.check
	else
		echo "Missing user_top in $slot"
	fi
	popd 2>&1 > /dev/null
done
