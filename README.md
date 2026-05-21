# extra_be_checks
Scripts to run additional back-end checks on gds files.

INSTALLATION:
Requires:
- magic 3.8.413  https://github.com/RTimothyEdwards/magic.git
- netgen 1.5.255  https://github.com/RTimothyEdwards/netgen.git
- cvc 1.1.7  https://github.com/d-m-bailey/cvc.git

git clone -b precheck https://github.com/d-m-bailey/extra_be_checks.git
export LVS_ROOT=$PWD/extra_be_checks

In your `caravel_user_project`, `caravel_user_project_analog` or `openframe_user_project` directory,
create an LVS configuration file based on `extra_be_checks/tech/$PDK/lvs_config.<cellname>.json`.
`cf precheck` expects this file to be in `lvs/<cellname>/lvs_config.json`.

Environment variables.
These checks will use the following environment variables'
`LVS_ROOT`: path to the extra_be_checks directory. No default. Must be set.
`WORK_ROOT`: path to temporary work directory. Defaults to $PWD/work/$top_source
`LOG_ROOT`: path to runtime logs. Defaults to $PWD/logs/$top_source
`SIGNOFF_ROOT`: path to results. Defaults to $PWD/signoff/$top_source


```
$LVS_ROOT/run_be_checks [--noextract] [--nooeb] lvs/<cellname>/lvs_config.json
```
This command will run the following checks.
```
run_hier_check: Checks layout hierarchy against verilog hierarchy
run_scheck: Soft connection check (if RUN_SOFTCHECK=1)
run_full_lvs: Device level LVS
run_cvc: ERC checks
run_oeb_check: Check oeb and gpio configurations connections
```

## Configuration File

The `lvs_config.json` files are a possibly hierarchical set of files to set parameters for device level LVS

Required variables:
`TOP_SOURCE` : Top source cell name.

`TOP_LAYOUT` : Top layout cell name.

`LAYOUT_FILE` : Layout gds data file. 

`LVS_SPICE_FILES` : A list of spice files.

`LVS_VERILOG_FILES` : A list of verilog files. **Note: files with child modules may need to be listed before parent modules.**

Optional variable lists: `*` may be used as a wild card character.

### Extraction Options

`EXTRACT_FLATGLOB` : List of cell names to flatten before extraction. 
        Cells without text tend to work better if flattened.
        Note: it is necessary to flatten all sub cells of any cells listed.

`EXTRACT_ABSTRACT` : List of cells to extract as abstract devices.
        Normally, cells that do not contain any devices will be flattened during netlisting. 
        Using this variable can prevent unwanted flattening of empty cells.
        This has no effect of cells that are flattened because of a small number of layers.
        Internal connectivity is maintained (at least at the top level).
	Cells that actually contain devices or hierarchies may also be abstracted.
	If actual abstraction processing was done on a cell, a lef file will be created in the extraction diretory.
	Be warned that this may take up over an hour for cells with many 100K subcells.
	Also be aware that abstracting a cell will connect all ports by name
	even if they are not internally connected.

`EXTRACT_CREATE_SUBCUT` : List of cells to surround with the substrate isolation layer.
        The substrate isolation layer is used during LVS to virtually devide the substrate into regions
	that may be connected to different nets (ex. `vssa1` and `vssd1`).
	Without this layer all substrate connections are shorted and LVS is not possible.
	The isolation layer must not overlap any deep nwell or other isolation layers at sub-hierarchies. 
	Specifing the cell here results in an isolation area excluding deep nwell and pre-exisiting isolation layers.
	This is a temporary layer but the actual shape is stored in a gds file in the extraction directory.
	WARNING: This should only be used with ground nets. It allows psubstrate to be
	connected to any single net within the region, including power!

### LVS Options
`LVS_FLATTEN` : List of cells to flatten before comparing,
        Sometimes matching topologies with mismatched pins cause errors at a higher level.
        Flattening these cells can yield a match.

`LVS_NOFLATTEN` : List of cells not to be flattened in case of a mismatch.
        Lower level errors can propagate to the top of the chip resulting in long run times.
        Specify cells here to prevent flattening. May still cause higher level problems if there are pin mismatches.

`LVS_IGNORE` : List of cells to ignore during LVS.
        Cells ignored result in LVS ending with a warning.
        Generally, should only be used when debugging and not on the final netlist.

1. Check design hierarchies. A fast check for digital designs to ensure that design hierarchies match.

   Usage: `run_hier_check top_source verilog_files top_layout layout_file [primitive_prefix [layout_prefix]]`

   Requires:
   - klayout:

   Arguments:
   - `top_source`: Top cell name from verilog
   - `verilog_files`: Verilog files (only cells in the listed verilog files will be checked)
   - `top_layout`: Top cell name in the layout
   - `layout_file`: gds/oasis/text file (gzip compression allowed).
   - `primitive_prefix`: If given, prefix is removed from both source and layout before comparison.
   - `layout_prefix`: If given, prefix is removed from layout cell names before comparison.

   Input:
   - `verilog_files`: List of referenced verilog files. Should have child modules listed before parents.

   Output:
   - `$WORK_ROOT/verilog.hier`: The netlist hierarchy.
   - `$WORK_ROOT/layout.txt.gz`: If input is gds/oas, the layout hierarchy converted to text.
   - `$WORK_ROOT/layout.hier`: The layout hierarchy.
   - `$SIGNOFF_ROOT/hier.csv`: Comparison results.

   Algorithm:
   - Convert gds/oasis to gds text file.
   - Extract netlist hierarchy.
   - Extract layout hierarchy.
   - Compare.

2. Soft connection check: find high resistance connections (i.e. soft connections) through n/pwell.
   Default is to not run soft connection check. Enable with RUN_SOFT=1

   Usage:
   `run_softcheck [--noextract] [<config_file> [<top_layout> [<gds_file>]]]`

   Requires:
   - magic 3.8.413
   - netgen 1.5.255

   Arguments:
   - `--noextract`: Use previous extraction results.
   - `config_file`: Configuration file. For details, see sample in repo.
   - `top_layout`: Top layout name. Overrides config_file setting.
   - `gds_file`: gds file (gzip compression allowed). Overrides config_file setting.

   References: (created from config_file)
   - `$WORK_ROOT/flatglob`: cells to be flattened before extraction.
   - `$WORK_ROOT/abstract.glob`: cells to be abstracted during extraction.

   Output:
   - `$WORK_ROOT/ext/*`: Extraction results with well connectivity.
   - `$LOG_ROOT/ext.log`: Well connectivity extraction log.
   - `$WORK_ROOT/nowell.ext/*`: Extraction results without well connectivity.
   - `$LOG_ROOT/nowell.ext.log`: No well connectivity extraction log.
   - `$LOG_ROOT/soft.log`: Soft connection check LVS log.
   - `$SIGNOFF_ROOT/soft.report`: Comparison results.

   Algorithm:
   - Create 2 versions of the extracted netlist.
   - Version 1 extracts well connectivity.
     - Remove well connections and disconnected signals.
   - Version 2 does not extract well connectivity.
     - Remove disconnected signals.
   - Compare with LVS.

   Analysis:
   - Any discrepancies should be the result of well/substrate taps not connected to the correct power net.
   - Use the `$SIGNOFF_ROOT/soft.report` file to find problem nets.
   - Use the problem nets to find a connected device in the `$WORK_ROOT/nowell.ext/<top_layout>.gds.nowell.spice` file.
   - Use the corresponding `$WORK_ROOT/nowell.ext/*.ext` file to find the coordinates of error devices. (divide by 200 to get coordinates in um).

3. Full device level LVS

   Usage: `run_full_lvs [--noextract] [<config_file> [<top_source> [<top_layout> [layout_file]]]]

   Requires:
   - magic 3.8.413
   - netgen 1.5.255

   Arguments:
   - `--noextract`: Use previous extraction results.
   - `config_file`: Configuration file. For details, see sample in repo.
   - `top_source`: Top source name. Overrides config_file setting.
   - `top_layout`: Top layout name. Overrides config_file setting.
   - `layout_file`: Top layout file name. Overrides config_file setting.

   References: (created from config_file)
   - `$WORK_ROOT/flatglob`: cells to be flattened before extraction.
   - `$WORK_ROOT/abstract.glob`: cells to be abstracted during extraction.
   - `$WORK_ROOT/flatten.glob`: cells to be flattened during LVS.
   - `$WORK_ROOT/noflatten.glob`: cells not to be flattened during LVS.
   - `$WORK_ROOT/ignore.glob`: cells to be ignored during extraction.
   - `$WORK_ROOT/spice_files`: list of spice files in hierachical order (lowest level first).
   - `$WORK_ROOT/verilog_files`: list of verilog files in hierachical order (lowest level first).

   Output:
   - `$WORK_ROOT/ext/*`: Extraction results with well connectivity.
   - `$LOG_ROOT/ext.log`: Well connectivity extraction log.
   - `$LOG_ROOT/lvs.log`: LVS comparison log.
   - `$SIGNOFF_ROOT/lvs.report`: Comparison results.

   Hints:
   - Rerunning with --noextract is faster because previous extraction result will be used.
   - Add cells to the `EXTRACT_FLATGLOB` to flatten before extraction.
   - Cells in `EXTRACT_ABSTRACT` will be extracted (top level?), but netlisted as black-boxes.
   - Add cells to the `EXTRACT_CREATE_SUBCUT` to isolate the psubstrate.
     Use this when you have blocks with different substrate connections.
   - `LVS_FLATTEN` is a list of cell names to be flattened during LVS.
     Flattening cells with unmatched ports may resolve proxy port errors.
   - netgen normally flattens unmatched cells which can lead to confusing results at higher levels.
     To avoid this, add cells to `LVS_NOFLATTEN`.
   - Add cells to `LVS_IGNORE` to skip LVS checks.

4. CVC-RV. Circuit Validity Check - Reliability Verification - voltage aware ERC.
   Voltage aware ERC tool to detect current leaks and electrical overstress errors.

   Usage: `run_cvc [--noextract] [lvs_config_file [top_layout [layout_file]]]]"

   Requires:
   - cvc_rv 1.1.7

   Arguments:
   - `--noextract`: Use previous extraction results.
   - `lvs_config_file`: Configuration file. For details, see sample in repo.
   - `top_layout`: Top layout name. Overrides config_file setting.
   - `layout_file`: gds file (gzip compression allowed). Overrides config_file setting.

   Input:
   - `$WORK_ROOT/ext/<top_layout>.gds.spice`: Extracted spice file.
   - `$WORK_ROOT/cvc.power.<top_layout>`: Power settings.
   - `cvc.$PDK.models`: Model settings.

   Output:
   - `$WORK_ROOT/<top_layout>.cdl.gz`: CDL file converted from extracted spice file.
   - `$WORK_ROOT/cvc.error.gz`: Detailed errors results.
   - `$LOG_ROOT/cvc.log`: Log file with error summary.

   Analysis;
   - Works well with digital designs. Analog results can be obscure.
   - If the log file shows errors, look for details in the error file.
   - Error device locations can be found in the respective `$WORK_ROOT/ext/*.ext` files. (coordinates should be divided by 200).

5. OEB check. Check user connections against gpio configuration.
   See https://docs.google.com/spreadsheets/d/1nYYAiqxi1V9ZBvW9GzFHaRDODuWXLOA9Znsbq4re1Ek/edit?usp=sharing for error and warning conditions

   Usage: `run_oeb_check [--noextract] [lvs_config_file [top_layout [layout_file]]]]"

   Requires:
   - cvc_rv 1.1.4

   Arguments:
   - `--noextract`: Use previous extraction results.
   - `lvs_config_file`: Configuration file. For details, see sample in repo.
   - `top_layout`: Top layout name. Overrides config_file setting.
   - `layout_file`: gds file (gzip compression allowed). Overrides config_file setting.

   Input:
   - `$WORK_ROOT/ext/<top_layout>.gds.spice`: Extracted spice file.
   - `$WORK_ROOT/cvc.power.<top_layout>`: Power settings.
   - `cvc.$PDK.models`: Model settings.

   Output:
   - `$WORK_ROOT/<top_layout>.cdl.gz`: CDL file converted from extracted spice file.
   - `$WORK_ROOT/cvc.oeb.error.gz`: Detailed errors results.
   - `$LOG_ROOT/cvc.oeb.log`: Log file with error summary.
   - `$SIGNOFF_ROOT/cvc.oeb.report`: List of each gpio, connection counts, and errors
