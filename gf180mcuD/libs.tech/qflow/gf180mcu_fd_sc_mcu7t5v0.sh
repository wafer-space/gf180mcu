#!/bin/tcsh
#---------------------------------------------------------------
# Shell script setting up all variables used by the qflow scripts
# for this project
#---------------------------------------------------------------

# The LEF file containing standard cell macros

set leffile=LOCAL_PREFIX/gf180mcuD/libs.ref/gf180mcu_fd_sc_mcu7t5v0/lef/gf180mcu_fd_sc_mcu7t5v0.lef

# The SPICE netlist containing subcell definitions for all the standard cells

set spicefile=LOCAL_PREFIX/gf180mcuD/libs.ref/gf180mcu_fd_sc_mcu7t5v0/spice/gf180mcu_fd_sc_mcu7t5v0.spice

# The liberty format file containing standard cell timing and function information

set libertyfile=LOCAL_PREFIX/gf180mcuD/libs.ref/gf180mcu_fd_sc_mcu7t5v0/lib/gf180mcu_fd_sc_mcu7t5v0__ss_1p62v_125c.lib

# If there is another LEF file containing technology information
# that is separate from the file containing standard cell macros,
# set this.  Otherwise, leave it defined as an empty string.

# NOTE:  Backend-specific technology LEF files come from BEOL-specific
# directories, and all have the same name.

set techleffile=LOCAL_PREFIX/gf180mcuD/TECHLEF_PATH/gf180mcu_fd_sc_mcu7t5v0.nom.tlef

# All cells below should be the lowest output drive strength value,
# if the standard cell set has multiple cells with different drive
# strengths.  Comment out any cells that do not exist.

set flopcell=gf180mcu_fd_sc_mcu7t5v0__dffq_x1	;# Standard positive-clocked DFF, no set or reset
set flopsetreset=gf180mcu_fd_sc_mcu7t5v0__dffrsnq_x1 ;# DFF with both set and clear
set setpin=SETN		;# The name of the set pin on DFFs
set resetpin=RN		;# The name of the clear/reset pin on DFFs
set setpininvert=1	;# Set this to 1 if the set pin is inverted (!set)
set resetpininvert=1	;# Set this to 1 if the reset pin is inverted (!reset)
set floppinout=Q	;# Name of the output pin on DFFs
set floppinin=D		;# Name of the output pin on DFFs
set floppinclk=CLK	;# Name of the clock pin on DFFs
set bufcell=gf180mcu_fd_sc_mcu7t5v0__buf_x2	;# Minimum drive strength buffer cell
set bufpin_in=I		;# Name of input port to buffer cell
set bufpin_out=Z	;# Name of output port to buffer cell
set clkbufcell=gf180mcu_fd_sc_mcu7t5v0__clkbuf_x2	;# Minimum drive strength buffer cell
set clkbufpin_in=I	;# Name of input port to buffer cell
set clkbufpin_out=Z	;# Name of output port to buffer cell
set inverter=gf180mcu_fd_sc_mcu7t5v0__inv_x1	;# Minimum drive strength inverter cell
set invertpin_in=I	;# Name of input port to inverter cell
set invertpin_out=ZN	;# Name of output port to inverter cell
set norgate=gf180mcu_fd_sc_mcu7t5v0__nor2_x1	;# 2-input NOR gate, minimum drive strength
set norpin_in1=A1	;# Name of first input pin to NOR gate
set norpin_in2=A2	;# Name of second input pin to NOR gate
set norpin_out=ZN	;# Name of output pin from OR gate
set nandgate=gf180mcu_fd_sc_mcu7t5v0__nand2_x1	;# 2-input NAND gate, minimum drive strength
set nandpin_in1=A1	;# Name of first input pin to NAND gate
set nandpin_in2=A2	;# Name of second input pin to NAND gate
set nandpin_out=ZN	;# Name of output pin from NAND gate
# Synchronize it with .par's TWSC*feedThruWidth
set fillcell=gf180mcu_fd_sc_mcu7t5v0__fill	;# Spacer (filler) cell (prefix, if more than one)
set decapcell=gf180mcu_fd_sc_mcu7t5v0__fillcap	;# Decap (filler) cell (prefix, if more than one)
set antennacell=gf180mcu_fd_sc_mcu7t5v0__antenna	;# Antenna (filler) cell (prefix, if more than one)
set antennapin_in="I"	;# Antenna cell input connection
set bodytiecell=gf180mcu_fd_sc_mcu7t5v0__filltie

# yosys tries to eliminate use of these; depends on source .v
set tiehi="tieh"	;# Cell to connect to power, if one exists
set tiehipin_out="ZN"	;# Output pin name of tiehi cell, if it exists
set tielo="tiel"	;# Cell to connect to ground, if one exists
set tielopin_out="Z"	;# Output pin name of tielo cell, if it exists

set gndnet="VSS,VPW"	;# Name used for ground pins in standard cells
set vddnet="VDD,VNW"	;# Name used for power pins in standard cells

set separator=x		;# Separator between gate names and drive strengths
set techfile=LOCAL_PREFIX/gf180mcuD/libs.tech/magic/gf180mcuD.tech	;# magic techfile
set magicrc=LOCAL_PREFIX/gf180mcuD/libs.tech/magic/gf180mcuD.magicrc	;# magic startup script
set magic_display="XR" 	;# magic display, defeat display query and OGL preference
set netgen_setup=LOCAL_PREFIX/gf180mcuD/libs.tech/netgen/gf180mcuD_setup.tcl	;# netgen setup file for LVS
set gdsfile=LOCAL_PREFIX/gf180mcuD/libs.ref/gf180mcu_fd_sc_mcu7t5v0/gds/gf180mcu_fd_sc_mcu7t5v0.gds	;# GDS database of standard cells
set verilogfile=LOCAL_PREFIX/gf180mcuD/libs.ref/gf180mcu_fd_sc_mcu7t5v0/verilog/gf180mcu_fd_sc_mcu7t5v0.v	;# Verilog models of standard cells

# Set a conditional default in the project_vars.sh file for this process
set postproc_options="-anchors"
set route_layers = 5
set fill_ratios="0,70,10,20"
set fanout_options="-l 150 -c 15"
set addspacers_options="-stripe 2.5 50.0 PG"
set xspice_options="-io_time=250p -time=50p -idelay=20p -odelay=50p -cload=250f"
