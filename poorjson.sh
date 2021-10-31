#!/bin/sh
# A POSIX compatible JSON parser within 60 lines of code (without comments)
# Usage example:
# $ echo '{ "key1" : { "key2": {}, "key3": [null, true, false, "value"]}}' | ./poorjson.sh '"key1"' '"key3"' 3
# $ "value"
# shellcheck disable=SC2015

__JNUM='\(-\?\(0\|[1-9][0-9]*\)\(\.[0-9]\+\)\?\([eE][+-]\?[0-9]\+\)\?\)'
__JSTR='\("\([^[:cntrl:]"]\|\\["\\\/bfnrt]\|u[0-9]{4}\)*"\)'
_TOKEN="" _TMP="" __JTOK="$__JSTR\|$__JNUM\|true\|false\|null\|[][}{,:]"

_is_match() { [ "$1" = "$2" ] || [ "$1" = \* ] || [ "$1" = . ]; }
_eof_error() { echo "Unexpected EOF after \"$_TOKEN\""; exit 1; }
_token_error() { echo "Unexpected token \"$_TOKEN\""; exit 1; }
_jread() {
	read -r _TOKEN || _eof_error
	[ "$1" = . ] && echo "$_TOKEN"
}

_jarr() {
	if _is_match "$1" 0; then _jval "$@"; else _jval; fi || {
		[ "$_TOKEN" = ']' ] && return || _token_error
	}
	while :; do
		_jread "$1";
		case $_TOKEN in "]") return 0;;
				",") [ "$1" -ge 0 ] 2>/dev/null && _TMP=$(( $1 - 1)) && shift && set -- "$_TMP" "$@";;
				*) _token_error;;
		esac
		if _is_match "$1" 0; then _jval "$@"; else _jval; fi || _token_error
	done
}

_jobj() {
	_jread "$1"; [ "$_TOKEN" = "}" ] && return 0
	while :; do
		_TMP=$_TOKEN
		case $_TMP in '"'*'"')
			_jread "$1"
			[ "$_TOKEN" = ":" ] || _token_error
			if _is_match "$1" "$_TMP"; then _jval "$@"; else _jval; fi || _token_error
			_jread "$1"
			[ "$_TOKEN" = "}" ] && return 0
			[ "$_TOKEN" != "," ] && _token_error
			_jread "$1"
			continue
			;;
		esac
		_token_error
	done
}

_jval() {
	[ "$#" -eq 0 ] || [ "$*" = . ] || shift
	_jread "$1"
	case $_TOKEN in '{') _jobj "$@";;
			"[") _jarr "$@";;
			true|false|null|-*|[0-9]*|'"'*'"') [ "$1" = \* ] && echo "$_TOKEN"; :;;
		*) return 1;;
	esac
}

sed -e "s/\($__JTOK\)/\n\1\n/g" | sed -e "/^\s*$/d;/$__JTOK/!{q255};" | { _jval "" "$@" . && ! read -r; } || {
	echo "JSON string invalid."
	exit 1
}
