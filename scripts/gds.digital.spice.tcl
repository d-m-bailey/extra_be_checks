# magic commands to extract netlist, 
# well connectivity is detemined by tech file specified in magicrc.
# output directory set by environment variable RUN_DIR

puts "Extracting with top ports unique (digital)"
drc off
#cif istyle sky130(legacy)

foreach cell $::env(FLATGLOB_CELLS) {
	gds flatglob $cell
}
# list cells to be flattened
puts "Flattening [gds flatglob]"
gds flatten yes
puts "Extracting $::env(LAYOUT_FILE)"
gds read $::env(LAYOUT_FILE)

foreach cell $::env(ABSTRACT_CELLS) {
	load $cell 
	property LEFview true
}

load $::env(TOP)
cd $::env(RUN_DIR)
extract no all
extract do aliases
extract do local
extract unique
extract

ext2spice lvs
ext2spice merge conservative
#ext2spice short resistor
ext2spice -o $::env(TOP).gds.spice $::env(TOP).ext
feedback save $::env(TOP)-ext2gds.spice.feedback.txt

