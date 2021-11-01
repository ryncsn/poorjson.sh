# poorjson.sh

A minimal POSIX compatible JSON parser and query tool written in pure 60 lines of POSIX Shell code.
The goal is to be POSIX compatible, lightweight, and fast. Only requires `sed`.

## Usage:

```
# Just pipe JSON to it, and use parameters to query:
# (Note strings are quoted with "")
echo '{"key": ["ele1", "ele2", "ele3", "ele4"]}' | ./poorjson.sh '"key"' 2
# Prints:
"ele3"

# If output is array or object, it's printed a token per line
echo '{"top-key": {"key1": [ "value1", "value2"],  "key2": "value2"} }' | ./poorjson.sh '"top-key"' '"key1"'
# Prints:
[
"value1"
,
"value2"
]

# Use \* to match anything, multilevel matching is supported:
echo '{"key0": {"key1": ["ele1-1", "ele1-2"], "key2": ["ele2-1", "ele2-2"]}}' | ./poorjson.sh '"key0"' \* 1
# Prints:
"ele1-1"
"ele2-1"

# poorjson.sh prints the whole JSON one token per line if no param is given:
echo '{"key0": [{"key1": "val1"}]}' | ./poorjson.sh
# Prints:
{
"key0"
:
[
{
"key1"
:
"val1"
}
]
}

# poorjson.sh prints basic error message for invalid JSON
# To simply check if a JSON string is valid:
echo '{"key": "val"}' | ./poorjson.sh - && echo "valid" || echo "invalid"
# Prints:
valid

echo '{"key":: "val"}' | ./poorjson.sh - && echo "valid" || echo "invalid"
# Prints:
Unexpected token ":"
JSON string invalid.
invalid
```

## Known issues
- If the same key appears multiple times in an object, poorjson.sh will simply parse them repeatedly.
- Not tested enough.
