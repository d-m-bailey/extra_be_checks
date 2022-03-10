# magic commands to extract netlist, 
# well connectivity is detemined by tech file specified in magicrc.
# output directory set by environment variable RUN_DIR

foreach cell $::env(MAGIC_GDS_FLATTEN_CELLS) {
	gds flatglob $cell
}
# list cells to be flattened
puts "Flattening [gds flatglob]"
gds flatten yes
gds read $::env(CURRENT_GDS)

load $::env(TOP) -dereference
cd $::env(RUN_DIR)
extract do local
extract unique
extract

ext2spice lvs
ext2spice -o $::env(TOP).gds.spice $::env(TOP).ext
feedback save $::env(TOP)-ext2gds.spice.feedback.txt

