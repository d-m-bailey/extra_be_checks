s/[^ ]* \(sky130_fd_pr__.fet\)/\1/
s/[^ ]* \(sky130_fd_pr__special_.fet\)/\1/
s/[^ ]* \(sky130_fd_pr__esd_.fet\)/\1/
s/[^ ]* \(sky130_fd_pr__res_x*high_po\)/\1/
s/[^ ]* \(sky130_fd_pr__res_generic_[np]d\)/\1/
/^D.* sky130_fd_pr__diode_pd2nw_/d
/^D.* sky130_fd_pr__diode_pw2nd_/d
