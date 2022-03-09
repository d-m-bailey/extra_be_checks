BEGIN {
	#array port_order;
	#array connections;
	#array instance_lines;
	#array device_lines;
	instance_line_count = 0;
	port_line_count = 0;
}
/^\+/ {
	#print "DEBUG: continuation. " $0;
	if ( reading == "port" ) {
		ReadPorts(2, subckt);
	} else {
		instance_line_count += 1;
		instance_lines[instance_line_count] = $0;
		parent = $NF;
	}
	next;
}
/^.subckt/ || /^.SUBCKT/ {
	#print "DEBUG: subckt. " $0;
	reading = "port";
	subckt = $2;
	port_count = 0;
	port_line_count = 0;
	ReadPorts(3, subckt);
	device_line_count = 0;
	next;
}
/^[CcDdMmRrXx]/ {
	#print "DEBUG: device. " $0;
	if ( instance_line_count > 0 ) {
		SaveInstance(parent);
	}
	reading = "device";
	instance_line_count = 1;
	instance_lines[instance_line_count] = $0;
	parent = $NF;
	next;
}
/^.ends/ || /^.ENDS/ {
	#print "DEBUG: ends. " $0;
	if ( instance_line_count > 0 ) {
		SaveInstance(parent);
	}
	current = $0;
	port_count = 0;
	for (port_line_it = 1; port_line_it <= port_line_count; port_line_it++ ) {
		$0 = port_lines[port_line_it];
		if ( port_line_it == 1 ) {
			RemoveUnusedPorts(subckt, 3);
		} else {
			RemoveUnusedPorts(subckt, 2);
		}
		if ( ! /^\+ *$/ ) {
			print $0;
		}
	}
	for (output_line_it = 1; output_line_it <= device_line_count; output_line_it++ ) {
		print device_lines[output_line_it];
	}
	print current;
	delete port_lines;
	delete device_lines;
	next;
}
 {
	#print "DEBUG: other. " $0;
	print $0;
}
function SaveInstance(parent) {
	port_number = 0;
	current = $0;
	for (save_it = 1; save_it <= instance_line_count; save_it++ ) {
		$0 = instance_lines[save_it];
		for (net_it = 2; net_it <= NF; net_it++) {
			port_number += 1;
			connection_key = parent "&" port_number;
			if ( connection_key in connections && connections[connection_key] == 0 ) {
				$net_it = "";
			} else {
				key = subckt "&" $net_it;
				if ( key in port_order ) {
					connections[subckt "&" port_order[key]] += 1;
				}
			}
		}
		if ( ! /^\+ *$/ ) {
			device_line_count += 1;
			device_lines[device_line_count] = $0;
		}
	}
	instance_line_count = 0;
        delete instance_lines;
	$0 = current;
}
function ReadPorts(start, subckt) {
	port_line_count += 1;
	port_lines[port_line_count] = $0;
	for (port_it = start; port_it <= NF; port_it++ ) {
		port_count += 1;
		port_order[subckt "&" $port_it] = port_count;
		connections[subckt "&" port_count] = 0;
	}
}
function RemoveUnusedPorts(subckt, start) {
	for ( port_it = start; port_it <= NF; port_it++ ) {
		port_count += 1;
		connection_key = subckt "&" port_count;
		if ( connection_key in connections && connections[connection_key] == 0 ) {
			$port_it = "";
		}
	}
}
