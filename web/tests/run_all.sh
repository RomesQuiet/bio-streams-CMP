#!/bin/sh
# Runs every converted test and prints one line each (from the project folder):
#   sh web/tests/run_all.sh
cd "$(dirname "$0")/../.." || exit 1
failed=0
for test in web/tests/*_test.js; do
	result=$(node "$test" 2>&1 | grep -E "ALL PASSED|SOME FAILED" | tail -1)
	echo "$(basename "$test" .js) | ${result:-NO RESULT (it crashed)}"
	case "$result" in "ALL PASSED"*) ;; *) failed=1 ;; esac
done
exit $failed
