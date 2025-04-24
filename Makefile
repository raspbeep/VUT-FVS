all: zip

zip:
	zip xkrato61.zip -r rtl/ Makefile verification_plan.xlsx report.pdf uvm_fve/abv uvm_fve/agents uvm_fve/env_lib uvm_fve/golden_model uvm_fve/regmodel uvm_fve/test_lib uvm_fve/compile.tcl uvm_fve/Makefile uvm_fve/start_common.tcl \
	uvm_fve/start_verification.sh uvm_fve/start.tcl uvm_fve/test_parameters.sv uvm_fve/top_level.sv uvm_fve/wave.tcl

clean:
	rm -rf uvm_fve/work uvm_fve/ucdb uvm_fve/covhtmlreport xkrato61.zip