BEGIN {
	project = "?";
	uio_oe_start = 24;
	uio_out_start = 16;
	uo_out_start = 8;
}
 {
	if ( project != $1 ) {
		if ( project != "?" ) {
			print project, uio_oe, uio_out, uo_out;
		}
		uo_out = "00000000";
		uio_out = "00000000";
		uio_oe = "00000000";
		project = $1;
	}
	if ( $3 == "unknown" ) {
		bit = "+";
	} else if ( $3 == "vdpwr@5000" ) {
		bit = "1";
	}
	if ( $2 <= uo_out_start ) {
		position = uo_out_start - $2 + 1;
		#print "DEBUG: project", project, "bit", $2, "position", position, "value", $3;
		uo_out = substr(uo_out, 1, position - 1) bit substr(uo_out, position + 1);
	} else if ( $2 <= uio_out_start ) {
		position = uio_out_start - $2 + 1;
		#print "DEBUG: project", project, "bit", $2, "position", position, "value", $3;
		uio_out = substr(uio_out, 1, position - 1) bit substr(uio_out, position + 1);
	} else if ( $2 <= uio_oe_start ) {
		position = uio_oe_start - $2 + 1;
		#print "DEBUG: project", project, "bit", $2, "position", position, "value", $3;
		uio_oe = substr(uio_oe, 1, position - 1) bit substr(uio_oe, position + 1);
	}
}
END {
	print project, uio_oe, uio_out, uo_out;
}
