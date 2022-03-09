foreach cell $::env(MAGIC_GDS_FLATTEN_CELLS) {
	gds flatglob $cell
}
# list cells to be flattened
puts "Flattening [gds flatglob]"
gds flatten yes
gds read $::env(CURRENT_GDS)

load $::env(TOP) -dereference
cd nowell
extract do local
extract unique
extract

ext2spice lvs
ext2spice -o $::env(TOP).gds.spice $::env(TOP).ext
feedback save $::env(TOP)-ext2gds.spice.feedback.txt

