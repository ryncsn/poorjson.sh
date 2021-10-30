# poorjson.sh

A minimal POSIX compatible JSON parser and query tool written in pure 60 lines of POSIX Shell code.
The goal is to be POSIX compatible, lightweight, and fast. Only requires `sed`.

## Usage:

```
# Just pipe JSON to it, and use parameters to query:
# (Note strings are quoted with "")
echo '{"key": ["ele1", "ele2", "ele3", "ele4"]}' | ./poorjson.sh '"key"' 2
# Prints:
# "ele3"

# If output is array or object, it's printed a token per line
echo '{"top-key": {"key1": [ "value1", "value2"],  "key2": "value2"} }' | ./poorjson.sh '"top-key"' '"key1"'
# Prints:
# [
# "value1"
# ,
# "value2"
# ]
```

## Known issues
- If the same key appears multiple times in an object, poorjson.sh will simply parse them repeatedly.
- Not tested enough.
