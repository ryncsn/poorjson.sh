#!/bin/sh
# A POSIX compatible JSON parser within 60 lines of code (without comments)
# Usage example:
# $ echo '{ "key1" : { "key2": {}, "key3": [null, true, false, "value"]}}' | ./poorjson.sh '"key1"' '"key3"' 3
# $ "value"
# shellcheck disable=SC2015

__JNUM='(-?([1-9][0-9]*|0)(\.[0-9]+)?([eE][-+]?[0-9]+)?)'
__JSTR='("([^[:cntrl:]\\"]|\\(["\\\/bfnrt]|u[0-9a-fA-F]{4}))*")'
_TOKEN="" _TMP="" __JTOK="$__JSTR|$__JNUM|true|false|null|[][}{,:]"

_is_match() { case "$1" in "$2"|'*'|'.');; *) ! :;; esac }
_err() { echo "Unexpected $1: \"$_TOKEN\""; exit 1; }
_jread() {
	read -r _TOKEN || _err "EOF after"
	[ "$1" != . ] || echo "$_TOKEN"
}

_jarr() {
	if _is_match "$1" 0; then _jval "$@"; else _jval; fi || {
		[ "$_TOKEN" = ']' ]; return
	}
	while :; do
		_jread "$1"
		case $_TOKEN in "]") return;;
				",") [ "$1" -ge 0 ] 2>/dev/null && _TMP=$(($1 - 1)) && shift && set -- "$_TMP" "$@";;
				*) return 1;;
		esac
		if _is_match "$1" 0; then _jval "$@"; else _jval; fi || return
	done
}

_jobj() {
	_jread "$1"
	[ "$_TOKEN" = "}" ] && return
	while :; do
		case $_TOKEN in '"'*'"');; *)! :;; esac || return
		_TMP=$_TOKEN
		_jread "$1"
		[ "$_TOKEN" = ":" ] || return
		if _is_match "$1" "$_TMP"; then _jval "$@"; else _jval; fi || return
		_jread "$1"
		[ "$_TOKEN" = "}" ] && return
		[ "$_TOKEN" = "," ] || return
		_jread "$1"
	done
}

_jval() {
	[ "$#" -eq 0 ] || [ "$*" = . ] || shift
	_jread "$1"
	case $_TOKEN in '{') _jobj "$@" || _err "token";;
			"[") _jarr "$@" || _err "token";;
			true|false|null|-*|[0-9]*|'"'*'"') [ "$1" = \* ] && echo "$_TOKEN"; :;;
			*) ! :;;
	esac
}

sed -E "s/($__JTOK)/\n\1\n/g" | sed -E "/^[[:space:]]*$/d;/$__JTOK/!q;" | {
	_jval "" "$@" . && ! read -r _TOKEN 2>/dev/null || _err "invalid token"
}
