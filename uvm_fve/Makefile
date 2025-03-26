
coverage: run-tests
	rm -rf covhtmlreport
	vsim -c -viewcov ucdb/final.ucdb -do "coverage report -html -output covhtmlreport -annotate -details -assert -directive -cvg -code bcefst -threshL 50 -threshH 90; quit -f"
	firefox covhtmlreport/index.html

run-tests:
	./start_verification.sh -c -uvm_tests_file test_lib/test_list -run_multiple_tests
