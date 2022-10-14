#!/bin/sh
# A POSIX compatible JSON parser within 60 lines of code
# Usage example:
# $ echo '{ "key1" : { "key2": {}, "key3": [null, true, false, "value"]}}' | ./poorjson.sh '"key1"' '"key3"' 3
# $ "value"
# shellcheck disable=SC2015
__JNUM='(-?([1-9][0-9]*|0)(\.[0-9]+)?([eE][-+]?[0-9]+)?)'
__JSTR='("([^[:cntrl:]\\"]|\\(["\\\/bfnrt]|u[0-9a-fA-F]{4}))*")'
_TOK="" _TMP="" __JTOK="$__JSTR|$__JNUM|true|false|null|[][}{,:]"

_is_match() { case $1 in "$2"|'*'|.);; *)! :;; esac }
_err() { echo "Unexpected $1token: \"$_TOK\""; exit 1; }
_jread() {
	read -r _TOK || _err "EOF after "
	[ "$1" != . ] || echo "$_TOK"
}

_jarr() {
	if _is_match "$1" 0; then _jval "$@"; else _jval; fi || {
		[ "$_TOK" = ']' ] && return || _err
	}
	while :; do
		_jread "$1"
		case $_TOK in "]") return;;
				",") [ "$1" -ge 0 ] 2>/dev/null && _TMP=$(($1 - 1)) && shift && set -- "$_TMP" "$@";;
				*) _err;;
		esac
		if _is_match "$1" 0; then _jval "$@"; else _jval; fi || _err
	done
}

_jobj() {
	_jread "$1"
	[ "$_TOK" = "}" ] && return
	while :; do
		case $_TOK in '"'*'"');; *) _err;; esac
		_TMP=$_TOK
		_jread "$1"
		[ "$_TOK" = ":" ] || _err
		if _is_match "$1" "$_TMP"; then _jval "$@"; else _jval; fi || _err
		_jread "$1"
		[ "$_TOK" = "}" ] && return
		[ "$_TOK" = "," ] || _err
		_jread "$1"
	done
}

_jval() {
	[ "$#" -eq 0 ] || [ "$*" = . ] || shift
	_jread "$1"
	case $_TOK in '{') _jobj "$@";;
			"[") _jarr "$@";;
			true|false|null|-*|[0-9]*|'"'*'"') [ "$1" = \* ] && echo "$_TOK"; :;;
			*) ! :;;
	esac
}

sed -E "s/($__JTOK)/\1\n/g" | sed -E "/^[[:space:]]*$/d;/$__JTOK/!q;" | {
	_jval "" "$@" . && ! read -r _TOK 2>/dev/null || _err "invalid "
}
