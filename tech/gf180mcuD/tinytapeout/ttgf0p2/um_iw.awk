BEGIN {
	project = "?";
}
 {
	if ( project != $1 ) {
		if ( project != "?" ) {
			print project, branch, max ":" min;
		}
		project = $1;
		branch = $2;
		min = $3;
		max = $3;
	}
	if ( $3 > max || $3 < min - 1 ) {
		print "unexpected order in project", project, "min(" min ")-max(" max ") found", $3;
	}
	min = ( min < $3 ) ? min : $3;
	max = ( max > $3 ) ? max : $3;
}
END {
	print project, branch, max ":" min;
}
