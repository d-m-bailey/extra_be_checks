s/[^ ]* \(sky130_fd_pr__.fet\)/\1/
s/[^ ]* \(sky130_fd_pr__special_.fet\)/\1/
s/[^ ]* \(sky130_fd_pr__esd_.fet\)/\1/
s/[^ ]* \(sky130_fd_pr__res_high_po\)/\1/
s/[^ ]* \(sky130_fd_pr__res_xhigh_po\)/\1/
s/[^ ]* \(sky130_fd_pr__res_generic_nd\)/\1/
s/[^ ]* \(sky130_fd_pr__res_generic_pd\)/\1/
/^D.* sky130_fd_pr__diode_pd2nw_/d
/^D.* sky130_fd_pr__diode_pw2nd_/d
/^X.* sky130_fd_pr__pnp_05v5/d
