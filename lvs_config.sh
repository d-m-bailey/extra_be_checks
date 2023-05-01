# LVS configuration file - bash version - non hierarchical

# All cell lists allow the use of the "*" wildcard

# list of cells to be flattened before extraction
export EXTRACT_FLATGLOB="
	"

# list of cells to be abstracted before extraction
export EXTRACT_ABSTRACT="
	"

# list of cells to be flattened during lvs
export LVS_FLATTEN="
	"

# list of cells not to be flattened during lvs
export LVS_NOFLATTEN="
	"

# list of cells to be ignored during lvs
export LVS_IGNORE="
	"

# list of spice input files (lowest hierarchy first)
export LVS_SPICE_FILES="
	$PDK_ROOT/$PDK/libs.ref/sky130_fd_sc_hd/spice/sky130_fd_sc_hd.spice"

# list of verilog input files (lowest hierarchy first)
export LVS_VERILOG_FILES="
	$UPRJ_ROOT/verilog/gl/$TOP_SOURCE.v"

# gds file
: "${LAYOUT_FILE:=$UPRJ_ROOT/gds/$TOP_LAYOUT.gds.gz}"
export LAYOUT_FILE
