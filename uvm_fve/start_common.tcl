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

    # Check if *any* coverage type was intended to be enabled.
    # The actual types saved depend on compile/simulation flags,
    # not options to the 'coverage save' command itself in Questa.
    if { [info exists CODE_COVERAGE_ENABLED] && ${CODE_COVERAGE_ENABLED} || \
         [info exists FUNC_COVERAGE_ENABLED] && ${FUNC_COVERAGE_ENABLED} } {

        # Recommend using the standard .ucdb extension
        if { ![string match "*.ucdb" $COVERAGE_FILE] } {
            puts "Warning: Coverage file '$COVERAGE_FILE' does not end with .ucdb. Recommend using the .ucdb extension for Questa."
            # Optionally force the extension:
            # set COVERAGE_FILE "${COVERAGE_FILE}.ucdb"
        }

        # Construct the Questa command (simple)
        set cmd [list coverage save $COVERAGE_FILE]
        puts "Executing coverage save command: $cmd"

        # Execute and catch errors
        # Use 'uplevel #0' if running this proc from another proc context
        # Use plain execution if running directly in vsim Tcl console/do script
        if { [catch { uplevel #0 $cmd } result] } {
            puts stderr "Error saving coverage to ${COVERAGE_FILE}: $result"
            # Return an error code or re-throw
            return -code error "Coverage save failed"
        } else {
            puts "Coverage data saved successfully to ${COVERAGE_FILE}"
            puts "Ensure simulation was run with 'vsim -coverage' and code compiled with '+cover=...' for data to be present."
        }
    } else {
        puts "Coverage saving skipped (CODE_COVERAGE_ENABLED and FUNC_COVERAGE_ENABLED are both false or not defined)."
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
quietly set VSIM_RUN_CMD "vsim -voptargs=\"+acc=arn\" -msgmode both -assertdebug -t 1ps -lib ${WORKING_LIBRARY} ${TOP_MODULE}"
quietly set VSIM_COV_MERGE_FILE "./${UCDB_DIR}/final.ucdb"
quietly set VSIM_COVERAGE_MERGE "vcover merge -64 ${VSIM_COV_MERGE_FILE} ./${UCDB_DIR}/*.ucdb"

# default action when an error is encountered
onElabError { run_on_error ${::errorInfo} ${ERROR_MESSAGE}; }
onerror { run_on_error ${ERROR_MESSAGE}; }
