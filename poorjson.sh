#!/bin/sh
# A POSIX compatible JSON parser within 60 lines of code (without comments)
# Usage example:
# $ echo '{ "key1" : { "key2": {}, "key3": [null, true, false, "value"]}}' | ./poorjson.sh '"key1"' '"key3"' 3
# $ "value"
# shellcheck disable=SC2015

__JNUM='-\?\(0\|[1-9][0-9]*\)\(\.[0-9]\+\)\?\([eE][+-]?[0-9]\+\)\?'
__JSTR='"\([^[:cntrl:]"]\|\\["\\\/bfnrt]\|u[0-9]{4}\)*"'
__TOKEN="" __TMP="" __JTOK="$__JSTR\|$__JNUM\|true\|false\|null\|[][}{,:]"

_eof_error() { echo "Unexpected EOF after \"$__TOKEN\""; exit 1; }
_token_error() { echo "Unexpected token \"$__TOKEN\""; exit 1; }
__jread() {
	read -r __TOKEN || _eof_error
	[ "$1" = . ] && echo "$__TOKEN"
}

__jarr() {
	if [ "$1" -eq 0 ] 2>/dev/null || [ "$1" = \* ] || [ "$1" = . ]; then __jval "$@"; else __jval; fi || {
		[ "$__TOKEN" = ']' ] && return || _token_error
	}
	while :; do
		__jread "$1"; case $__TOKEN in
			",") [ "$1" -ge 0 ] 2>/dev/null && __TMP=$(( $1 - 1)) && shift && set -- "$__TMP" "$@" ;;
			"]") return 0 ;;
			*) _token_error ;;
		esac
		if [ "$1" -eq 0 ] 2>/dev/null || [ "$1" = \* ] || [ "$1" = . ]; then __jval "$@"; else __jval; fi || _token_error
	done
}

__jobj() {
	__jread "$1"; [ "$__TOKEN" = "}" ] && return 0
	while :; do
		case $__TOKEN in '"'*)
			__TMP=$__TOKEN
			__jread "$1"
			[ "$__TOKEN" = ":" ] || _token_error
			if [ "$__TMP" = "$1" ] || [ "$1" = \* ] || [ "$1" = . ]; then __jval "$@"; else __jval; fi || _token_error
			__jread "$1"
			[ "$__TOKEN" = "}" ] && return 0
			[ "$__TOKEN" != "," ] && _token_error
			__jread "$1"
			continue
			;;
		esac
		_token_error
	done
}

__jval() {
	[ "$#" -eq 0 ] || [ "$*" = . ] || shift
	__jread "$1"; case $__TOKEN in
		'{') __jobj "$@" ;;
		"[") __jarr "$@" ;;
		true | false | null | -* | [0-9]* | '"'*) [ "$1" = \* ] && echo "$__TOKEN" ;;
		*) return 1 ;;
	esac
	return 0
}

[ "$#" -gt 0 ] && set -- "" "$@" .
if ! sed -e "s/\s*\($__JTOK\)\s*/\1\n/g" -e "/\s*\|$__JTOK/!{q255};/^$/d" | __jval "$@"; then
	echo "JSON string invalid."
	exit 1
fi
