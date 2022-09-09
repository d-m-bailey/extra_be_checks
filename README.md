# extra_be_checks
Scripts to run additional back-end checks on gds files.

`run_be_checks` should run with the default user_project_wrapper or user_analog_project_wrapper.

1. Soft connection check: find high resistance connections (i.e. soft connections) through n/pwell.

   Usage:
   `run_softcheck top_cell [gds_file]`

   Requires:
   - magic 3.8.319
   - netgen 1.5.227

   Arguments:
   - `top_cell`: Top cell name.
   - `gds_file`: gds file (gzip compression allowed). Required initially. If not specified,uses previous extraction results.

   Input:
   - `flatglob`: List of cell names to be flattened before extraction. Globbing permitted.
   - `abstract`: List of cell names to be extracted as black boxes.

   Output:
   - `<top_cell>.ext/*`: Extraction results with well connectivity.
   - `<top_cell>.ext.log`: Well connectivity extraction log. 
   - `<top_cell>.nowell/*`: Extraction results without well connectivity.
   - `<top_cell>.nowell.log`: No well connectivity extraction log. 
   - `<top_cell>.lvs.nowell.report`: Comparison results.

   Algorithm:
   - Create 2 versions of the extracted netlist.
   - Version 1 extracts well connectivity.
     - Remove well connections and disconnected signals.
   - Version 2 does not extract well connectivity.
     - Remove disconnected signals.
   - Compare with LVS.

   Analysis:
   - Any discrepancies should be the result of well/substrate taps not connected to the correct power net.
   - Use the `<top_cell>.lvs.nowell.report` file to find problem nets.
   - Use the problem nets to find a connected device in the `<top_cell>.nowell/<top_cell>.gds.nowell.spice` file.
   - Use the corresponding `<top_cell>.nowell/*.ext` file to find the coordinates of error devices. (divide by 200 to get coordinates in um).

2. Full device level LVS

   Usage: `run_full_lvs top_netlist_cell top_netlist top_layout_cell [gds_file]`

   Requires:
   - magic 3.8.319
   - netgen 1.5.227

   Arguments:
   - `top_netlist_cell`: Top cell name from verilog or spice netlist.
   - `top_netlist`: Verilog or spice file that contains the top cell.
   - `top_layout_cell`: Top cell name of the gds file.
   - `gds_file`: gds file (gzip compression allowed). Required initially. If not specified, uses previous extraction results. Will use softcheck results if available.
  
   Input:
   - `flatglob`: List of cell names to be flattened before extraction. Globbing permitted.
   - `abstract`: List of cell names to be extracted as black boxes.
   - `flatten`: List of cell names to be flattened during LVS.
   - `noflatten`: List of cell names that should not be flattened during LVS.
   - `verilog_files`: List of referenced verilog files. Should have child modules listed before parents. Initially created with the contents of verilog/gl.
   - `spice_files`: List of referenced spice files.
   
   Output:
   - `<top_cell>.ext/*`: Extraction results.
   - `<top_cell>.ext.log`: Extraction log. 
   - `<top_cell>.lvs.log`: Netgen output.
   - `<top_cell>.lvs.report`: LVS results.

   Hints:
   - Rerunning without specifing the `gds_file` is faster because previous extraction result will be used.
   - Add cells to the `flatglob` file to flatten before extraction.
   - Cells in the `abstract` file will be fully extracted, but netlisted as black-boxes. 
   - The `flatten` file contains a list of cell names to be flattened during LVS. 
Flattening cells with unmatched ports may resolve proxy port errors.
   - netgen normally flattens unmatched cells which can lead to confusing results at higher levels.
To avoid this, create a file `noflatten`, that contains the names of cells not to be flattened.

3. CVC-RV. Circuit Validity Check - Reliability Verification.
   Voltage aware ERC tool to detect current leaks and electrical overstress errors.

   Usage: `run_cvc top_cell`

   Requires:
   - cvc 1.1.4

   Arguments:
   - `top_cell`: Top layout cell name.

   Input:
   - `<top_cell>.ext/<top_cell>.gds.spice`: Extracted spice file.
   - `<top_cell>.power`: Power settings.
   - `cvc.sky130A.models`: Model settings.

   Output:
   - `<top_cell>.ext/<top_cell>.cdl`: CDL file converted from extracted spice file.
   - `<top_cell>.cvc.log`: Log file with error summary.
   - `<top_cell>.cvc.error.gz`: Detailed errors results.

   Analysis;
   - Works well with digital designs. Analog results can be obscure.
   - If the log file shows errors, look for details in the error file.
   - Error device locations can be found in the respective `<top_cell>.ext/*.ext` files. (coordinates should be divided by 200).

4. Check design hierarchies. A fast check for digital designs to ensure that design hierarchies match.

   Usage: `run_hier_check top_cell top_netlist layout_file [primitive_prefix [layout_prefix]]`

   Requires:
   - klayout:

   Arguments:
   - `top_cell`: Top cell name from verilog
   - `top_netlist`: Verilog file that contains the top cell.
   - `gds_file`: gds/oasis/text file (gzip compression allowed).
   - `primitive_prefix`: If given, prefix is removed before comparison.
   - `layout_prefix`: If given, prefix is removed from layout cell names before comparison.

   Input:
   - `verilog_files`: List of referenced verilog files. Should have child modules listed before parents.

   Output:
   - `<top_cell>.verilog.hier`: The netlist hierarchy.
   - `gds_text/<top_cell>.gds.txt.gz`: If input is gds/oas, the layout data converted to text.
   - `<top_cell>.layout.hier`: The layout hierarchy.
   - List of discrepancies on stdout. 

   Algorithm:
   - Convert gds/oasis to gds text file.
   - Extract netlist hierarchy.
   - Extract layout hierarchy.
   - Compare. 

5. (PENDING) Hierarchy XOR. Compare 2 layouts showing cell count mismatches, cell movement, and layer mismatches.

   Usage: `run_hier_xor top_cell first_layout second_layout`

   Requires:
   - klayout:

   Arguments:
   - `top_cell`: Top cell name for layout.
   - `first_layout`: first gds/oasis/text file (gzip compression allowed).
   - `second_layout`: second gds/oasis/text file (gzip compression allowed).

   Output:
   - `gds_text/<top_cell>.first.gds.txt.gz`: First layout file converted to text.
   - `gds_text/<top_cell>.second.gds.txt.gz`: Second layout file converted to text.
   - List of discrepancies on stdout. 

   Algorithm:
   - Convert gds/oasis to gds text file (if necessary).
   - Perform the following comparisons hierarchically.
     - Compare instance counts
     - If instance counts match, compare instance positions
     - Compare shape/text counts
     - If shape/text counts match, compare shape/text positions
