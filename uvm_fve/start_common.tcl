####################################################################################################
#
####################################################################################################

# define behavior when an error is encountered
proc run_on_error { ERROR_MESSAGE } {
    # generate error messages and quit
    echo "${ERROR_MESSAGE}"
    if [batch_mode] {
    quit -f
    } else {
    pause
    }
}

# save coverage into database file
proc save_coverage { COVERAGE_FILE } {
    global CODE_COVERAGE_ENABLED
    global FUNC_COVERAGE_ENABLED

    if { ${CODE_COVERAGE_ENABLED} || ${FUNC_COVERAGE_ENABLED} } {
        set CODE_PARAMS [expr ($CODE_COVERAGE_ENABLED)?"-codeAll -assert":""]
        set FUNC_PARAMS [expr ($FUNC_COVERAGE_ENABLED)?"-cvg":""]
        eval "coverage save $CODE_PARAMS $FUNC_PARAMS $COVERAGE_FILE"
    }
}

# suppress warnings from arithmetic library during reset
proc suppress_warnings {} {
    quietly set NumericStdNoWarnings 1;
    quietly set StdArithNoWarnings 1;
    if { [find signals /top/RST] != "" } {
        when -fast -label disable_StdWarn {/top/RST == 0} {
            quietly set NumericStdNoWarnings 1;
            quietly set StdArithNoWarnings 1;
        }
        when -fast -label enable_StdWarn {/top/RST == 1} {
            quietly set NumericStdNoWarnings 0;
            quietly set StdArithNoWarnings 0;
        }
    }
}

# reduce and limit size of the transcript file
proc clear_transcript_file {} {
    transcript file ""
    transcript file transcript
    # limit size of the transcript to 1 GB
    transcript sizelimit 1048576
}

# Return list of files with given extension only
proc filter_extensions { FILES EXT } {
    return [lsearch -inline -all -regexp ${FILES} [subst -nocommands -nobackslashes {^.*\.${EXT}$}]]
}

proc get_file_list { DIRECTORY EXT {RECURSIVE "1"} } {
    set FILES [lsort -dictionary [glob -nocomplain -types {f r} -directory ${DIRECTORY} -- *${EXT}]]
    if { ${RECURSIVE} } {
        foreach DIR [glob -nocomplain -types {d} -directory ${DIRECTORY} *] {
            set FILES [concat [get_file_list ${DIR} ${EXT}] ${FILES}]
        }
    }
    return ${FILES}
}

# global variables
# working library name
quietly set WORKING_LIBRARY "work"
# default directory with HDL source files of the DUT
quietly set HDL_DIRECTORY [file join .. rtl]
quietly set ERROR_MESSAGE "An unspecified error has been encountered."
# set path to top level and DUT instance
quietly set TOP_MODULE "top"
quietly set DUT_MODULE "$TOP_MODULE/dut"
quietly set HDL_DUT "$DUT_MODULE/HDL_DUT_U"

quietly set UCDB_DIR "ucdb"
# input parameters for start.tcl script
# set UVM_TESTNAME
quietly set UVM_TESTNAME "timer_t_test"
# set UVM_TESTS_FILE
quietly set UVM_TESTS_FILE "./test_lib/test_list"
# set RUN_MULTIPLE_TESTS
quietly set RUN_MULTIPLE_TESTS 0

# enable or disable functional coverage collection
quietly set FUNC_COVERAGE_ENABLED 1
# enable or disable code coverage collection
quietly set CODE_COVERAGE_ENABLED 1

# prepare command to start simulation
#quietly set VSIM_RUN_CMD "vsim -voptargs=\"+acc=rn\" -msgmode both -assertcover -coverage -t 1ps -lib ${WORKING_LIBRARY} ${TOP_MODULE}"
#quietly set VSIM_RUN_CMD "vsim -voptargs=\"+acc=rn\" -msgmode both -coverage -t 1ps -lib ${WORKING_LIBRARY} ${TOP_MODULE}"
quietly set VSIM_RUN_CMD "vsim -voptargs=\"+acc=rn\" -msgmode both -coverage -t 1ps -lib ${WORKING_LIBRARY} ${TOP_MODULE}"
quietly set VSIM_COV_MERGE_FILE "./${UCDB_DIR}/final.ucdb"
quietly set VSIM_COVERAGE_MERGE "vcover merge -64 ${VSIM_COV_MERGE_FILE} ./${UCDB_DIR}/*.ucdb"

# default action when an error is encountered
onElabError { run_on_error ${::errorInfo} ${ERROR_MESSAGE}; }
onerror { run_on_error ${ERROR_MESSAGE}; }
