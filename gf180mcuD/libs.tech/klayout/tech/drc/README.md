# DRC Documentation

Explains how to use the runset.

## Folder Structure

```text
📁 drc
 ┣ 📁testing                        Testing environment directory for GF180MCU DRC. 
 ┣ 📁rule_decks                     All DRC rule decks used in GF180MCU.
 ┣ 📜README.md                      This file to document the DRC run for GF180MCU.
 ┗ 📜run_drc.py                     Main python script used for GF180MCU DRC.
 ```

## **Prerequisites**
You need the following set of tools installed to be able to run GF180MCU DRC:
- Python 3.6+
- KLayout 0.28.4+

## **Usage**

The `run_drc.py` script takes your input gds file to run DRC rule decks of GF180 technology on it with switches to select subsets of all checks. 

```bash
    run_drc.py (--help | -h)
    run_drc.py --path=<file_path>
            [--table=<table_name>]... [--mp=<num_cores>] [--run_dir=<run_dir_path>]
            [--topcell=<topcell_name>] [--run_mode=<mode>] [--no_feol] [--no_beol] [--no_density]
            [--density_thr=<density_threads>] [--density_only] [--antenna]
            [--antenna_only] [--no_offgrid] [--verbose] [--no_connectivity] [--slow_via]
```

Example:

```bash
    python3 run_drc.py --path=testing/testcases/unit/dualgate.gds --variant=C --table=dualgate --run_mode=deep --no_offgrid
```

### Options

- `--help -h`                           Print this help message.

- `--path=<file_path>`                  The input GDS file path.

- `--variant=<combined_options>`        Select combined options of metal_top, mim_option, and metal_level. Allowed values (A, B, C, D, E, F).
                                        variant=A: Select  metal_top=30K  mim_option=A  metal_level=3LM
                                        variant=B: Select  metal_top=11K  mim_option=B  metal_level=4LM
                                        variant=C: Select  metal_top=9K   mim_option=B  metal_level=5LM
                                        variant=D: Select  metal_top=11K  mim_option=B  metal_level=5LM
                                        variant=E: Select  metal_top=9K   mim_option=B  metal_level=6LM
                                        variant=F: Select  metal_top=9K   mim_option=A  metal_level=6LM

- `--topcell=<topcell_name>`            Topcell name to use.

- `--table=<table_name>`                Table name to use to run the rule deck.

- `--mp=<num_cores> `                   Run the rule deck in parts in parallel to speed up the run. [default: 1]

- `--run_dir=<run_dir_path>`            Run directory to save all the results [default: pwd]

- `--density_thr=<density_threads>`     The number of threads used in run.

- `--run_mode=<run_mode>`               Select klayout mode Allowed modes (flat, deep). [default: deep]

- `--no_feol`                           Turn off FEOL rules from running.

- `--no_beol`                           Turn off BEOL rules from running.

- `--no_connectivity`                   Turn off connectivity rules.

- `--no_density`                        Turn off Density rules.

- `--density_only`                      Turn on Density rules only.

- `--antenna`                           Turn on Antenna checks.

- `--antenna_only`                      Turn on Antenna checks only.

- `--no_offgrid`                        Turn off OFFGRID checking rules.

- `--verbose`                           Detailed rule execution log for debugging.

- `--slow_via`                          Turn on SLOW_VIA option for MT30.8 rule.


## **DRC Outputs**

You could find the run results at your run directory if you previously specified it through `--run_dir=<run_dir_path>`. Default path of run directory is `drc_run_<date>_<time>` in current directory.

### Folder Structure of run results

```text
📁 drc_run_<date>_<time>
 ┣ 📜 drc_run_<date>_<time>.log
 ┗ 📜 main.drc
 ┗ 📜 <your_design_name>.lyrdb
 ```

The result is a database file (`<your_design_name>.lyrdb`) contains all violations. 
You could view it on your file using: `klayout <input_gds_file> -m <resut_db_file> `, or you could view it on your gds file via marker browser option in tools menu using klayout GUI as shown below.

![image](https://user-images.githubusercontent.com/91015308/219004873-be7c1e81-7085-4e82-8cd4-8303bc021e13.png)


