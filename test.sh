#!/bin/sh

FAILED_CASES=0

__do_test() {
	VALID=$1
	TEST=$2
	JSON=$3
	EXPT=$4
	shift 4

	PASSED=1

	if [ "$VALID" -eq 1 ]; then
		TEST="(VALID JSON) $TEST"
	else
		TEST="(INVALID JSON) $TEST"
	fi

	echo "========== RUN TEST - $TEST =========="
	echo "JSON string:"
	echo "$JSON"
	OUTPUT=$(echo "$JSON" | ./poorjson.sh "$@" 2>&1)
	RET=$?

	if [ -n "$EXPT" ]; then
		if [ "$OUTPUT" != "$EXPT" ]; then
			echo "== ERROR: Output is not expected:"
			echo "= JSON string:"
			echo "$JSON"
			echo "==  Query:"
			echo "$@"
			echo "= Expected:"
			echo "$EXPT"
			echo "= Got:"
			echo "$OUTPUT"
			PASSED=0
		fi
	fi

	if [ "$VALID" -eq 1 ]; then
		if [ $RET -ne 0 ]; then
			echo "== ERROR: Failed to parse valid JSON."
			PASSED=0
		fi
	else
		if [ $RET -eq 0 ]; then
			echo "== ERROR: Invalid JSON didn't raise an error."
			PASSED=0
		fi
	fi

	if [ "$PASSED" -eq 1 ]; then
		echo "========== TEST PASSED =========="
	else
		echo "========== TEST FAILED =========="
		FAILED_CASES=$(( $FAILED_CASES + 1 ))
	fi
	echo
}

positive() {
	__do_test 1 "$@"
}

negative() {
	__do_test 0 "$@"
}

# Test case defination:
# positive/negative "<Test case name>" "<JSON string>" "<Expected output>" "[<Query parameters>, ...]"

positive "Empty Object" '{}' "" ""

positive "Object with one key" '{"key": ""}' "" ""

positive "String Empty" '{"key": ""}' "" ""

positive "String Simple" '{"key": "value"}' '"value"' '"key"'

positive "Array with no element" '{"key": []}' "" ""

positive "Array with one element" '{"key": ["element"]}' '"element"' '"key"' 0

positive "Array with multiple elements" '{"key": ["ele1", "ele2", "ele3", "ele4"]}' '"ele3"' '"key"' 2

negative "Empty String" '' \
'Unexpected EOF after ""
JSON string invalid.'

negative "Invalid case 1" ',' \
'JSON string invalid.'

negative "Invalid case 2" '{,}' \
'Unexpected token ","
JSON string invalid.'

negative "Invalid case 3" '{"key": }' \
'Unexpected token "}"
JSON string invalid.'

negative "Invalid case 4" '{"key": ,"key2": []}' \
'Unexpected token ","
JSON string invalid.'

negative "Invalid case 5" '{"key":: ,"key2": []}' \
'Unexpected token ":"
JSON string invalid.'

negative "Invalid case 6" '{"key": true, "key2": [, true]}' \
'Unexpected token ","
JSON string invalid.'

exit $FAILED_CASES
