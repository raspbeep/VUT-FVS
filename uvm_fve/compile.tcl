source "./start_common.tcl"

# compile SystemVerilog source file(s)
proc compile_fve_source { LIBRARY SRC_FILES } {
    #foreach SRC_FILE $SRC_FILES {
    #    regsub "/\[^/\]+\$" $SRC_FILE "/" INC_DIR
    #    set COMPILE_CMD "vlog -sv -incr -source -timescale \"1ps/1ps\" -work $LIBRARY +incdir+$INC_DIR $SRC_FILE"
    #    eval $COMPILE_CMD
    #}
    set COMPILE_CMD "vlog -sv -incr -source -timescale \"1ps/1ps\" -work ${LIBRARY} ${SRC_FILES}"
    eval ${COMPILE_CMD}
}

# compile VHDL RTL source file(s)
proc compile_vhdl { LIBRARY SRC_FILES } {
    global CODE_COVERAGE_FLAGS
    # VHDL 2008 is required for testbench compilation only, RTL is compliant with 1993 standard
    set COMPILE_CMD "vcom -explicit -2008 -source ${CODE_COVERAGE_FLAGS} -work ${LIBRARY} ${SRC_FILES}"
    eval "${COMPILE_CMD} -just pe"
    eval "${COMPILE_CMD} -skip pec"
    eval "${COMPILE_CMD} -just c"
}

# compile Verilog RTL source file(s)
proc compile_verilog { LIBRARY SRC_FILES } {
    global CODE_COVERAGE_FLAGS
    set COMPILE_CMD "vlog -incr -source ${CODE_COVERAGE_FLAGS} -timescale \"1ps/1ps\" -work ${LIBRARY} ${SRC_FILES}"
    eval ${COMPILE_CMD}
}

# compile SystemVerilog RTL source file(s)
proc compile_sverilog { LIBRARY SRC_FILES } {
    global CODE_COVERAGE_FLAGS
    set COMPILE_CMD "vlog -sv -sv12compat -incr -source ${CODE_COVERAGE_FLAGS} -timescale \"1ps/1ps\" -work ${LIBRARY} ${SRC_FILES}"
    eval ${COMPILE_CMD}
}

proc compile_cnd { LIBRARY SRC_FILES CMD HDL_EXT } {
    set FILES [filter_extensions ${SRC_FILES} ${HDL_EXT}]
    if { [llength ${FILES}] } {
        eval "${CMD} {${LIBRARY}} {${FILES}}"
    }
}

# compile all RTL source files in given directory and its sub-directories
proc compile_rtl_directory { LIBRARY HDL_DIRECTORY } {
    set SRC_FILES [get_file_list ${HDL_DIRECTORY} ""]

    compile_cnd ${LIBRARY} ${SRC_FILES} compile_vhdl vhd
    compile_cnd ${LIBRARY} ${SRC_FILES} compile_verilog v
    compile_cnd ${LIBRARY} ${SRC_FILES} compile_sverilog sv
}

# create working library and compile source files
proc compile_sources { LIBRARY HDL_DIRECTORY } {
    # backup previous error message and set new one
    global ERROR_MESSAGE
    quietly set prev_error_msg ERROR_MESSAGE
    quietly set ERROR_MESSAGE "Compilation error has been encountered."

    # create working library
    vlib $LIBRARY

    # DUT compilation
    #compile_directory $LIBRARY $HDL_DIRECTORY
    #eval "vcom -explicit -93 -source +cover=sbcef -nowarn 13 -work $LIBRARY $HDL_DIRECTORY/timer_fvs.vhd"
    quietly set CODE_COVERAGE_FLAGS "+cover=sbcef -nowarn 13"

    set SRC_FILES [list \
      [file join .. rtl . timer_fvs.vhd]
    ]

    compile_vhdl ${LIBRARY} ${SRC_FILES}

    # Can't use this because of dependencies in RTL
    # compile_rtl_directory ${LIBRARY} ${HDL_DIRECTORY}

    # verification environment compilation
    set SRC_FILES [list \
      test_parameters.sv  \
      [file join agents . sv_agent_pkg.sv]  \
      [file join golden_model sv_golden_model_pkg.sv] \
      [file join env_lib . sv_env_pkg.sv] \
      [file join test_lib . sv_test_pkg.sv] \
      [file join agents . ifc.sv] \
      [file join abv . abv_timer.sv] \
      top_level.sv  \
    ]

    # compile all sources at once
    compile_fve_source ${LIBRARY} ${SRC_FILES}
    # restore previous error message
    quietly set ERROR_MESSAGE prev_error_msg
}
