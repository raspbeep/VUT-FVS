#!/bin/sh
####################################################################################################
#
####################################################################################################

ARGV=$*

RUN_CMD="vsim"
VSIM_OPT="-c"

CMDLINE=0
GUI=0
UVM_TESTNAME=0
UVM_TESTS_FILE=0
RUN_MULTIPLE_TESTS=0

if [ $# -gt 0 ]
then
  for args in $ARGV
  do
    case $args in
      -c)
            delete=(-c)
            CMDLINE=1
            VSIM_OPT="-c"
            ;;
      -gui)
            delete=(-gui)
            GUI=1
            VSIM_OPT="-gui"
            ;;
      -uvm_testname)
            UVM_TESTNAME=1
            ;;
      -uvm_tests_file)
            UVM_TESTS_FILE=1
            ;;
      -run_multiple_tests)
            RUN_MULTIPLE_TESTS=1
            ;;
      -h | -help)
            echo "USAGE: ./start_verification.sh -c -gui -uvm_testname uvm_class_name -uvm_tests_file path_to_tests_file -run_multiple_tests"
            echo "Parameters:
                -c -- Run simulator in command line mode (optional)
                -gui -- Run simulator in gui mode (optional)
                -uvm_testname -- Specify which UVM test to execute (optional)
                -uvm_tests_file -- Specify location of the file with list of test names (optional)
                -run_multiple_tests -- Run all tests specified in file with list of test names (optional)
                -h, -help -- Print Usage and Parameters
            "
            exit 0
    esac
    ARGV=( "${ARGV[@]/$delete}" )
  done
  if [ ${RUN_MULTIPLE_TESTS} -eq 1 ]
  then
    echo "Forcing comandline simulator run, as run of multiple tests was requested"
    VSIM_OPT="-c"
  fi
fi

# append chosen option cmdline or gui
RUN_CMD="${RUN_CMD} ${VSIM_OPT}"

${RUN_CMD} -do "do start.tcl $ARGV" #$@
