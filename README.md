# sconnect_for_sky130_magic
Setup to find connections only through n/pwell.

Usage:
 ```run_scheck top_cell [gds_file]```

```
Inputs:
 top_cell
 gds_file: required initially
Output:
 nowell/<top_cell>.lvs.nowell.log
```

```
Internals:
 Create 2 versions of the extracted netlist.
  Version 1 extracts well connectivity.
   Remove well connections and disconnected signals.
  Version 2 does not extract well connectivity.
   Remove disconnected signals.
 Compare with LVS.
```

netgen normally flattens unmatched cells which can lead to confusing results at higher levels.
To avoid this, create a file `noflatten`, that contains the names of cells not to be flattened.
Rerunning without specifing `gds_file` is faster because only LVS will be run. 
You can also add cells the `flatten` file to flatten before extraction.

Also runs CVC-RV if the `top_cell` is `user_project_wrapper` or `user_analog_project_wrapper`.
CVC results will be in `well/cvc_<top_cell>.log` with error details in `well/cvc_<top_cell>.error.gz`.
May need to change net definitions in `<top_cell>.power`.

Requires:
magic
netgen
cvc
(all included in openlane docker container).
