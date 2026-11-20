#!/bin/sh
# Writes expected.html and expected.stderr for every test case from the RUBY
# japanese-to-codes, which is the reference. Cases with a "fail" file are only
# checked: Ruby must fail on them too.
#
# Run it after regenerating scripts/FastKanji.rb.

here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../../../.." && pwd)
ruby_prog="$root/scripts/japanese-to-codes.rb"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# The test runs from the package directory, so do the same.
cd "$here/.." || exit 1

status=0
for dir in testdata/cases/*/; do
    dir=${dir%/}
    name=$(basename "$dir")
    args=""
    [ -f "$dir/args" ] && args=$(cat "$dir/args")

    # $args is meant to split into words
    "$ruby_prog" --data=testdata/data --include=testdata/include $args "$dir/input.jhtml" \
        > "$tmp/out" 2> "$tmp/err"
    rc=$?

    if [ -f "$dir/fail" ]; then
        fragment=$(cat "$dir/fail")
        if [ $rc -eq 0 ]; then
            echo "$name: Ruby was expected to fail but succeeded"; status=1
        elif ! grep -qF -- "$fragment" "$tmp/err"; then
            echo "$name: Ruby failed, but its stderr does not contain: $fragment"; head -3 "$tmp/err"; status=1
        else
            echo "$name: Ruby failed, as expected"
        fi
        continue
    fi
    
    if [ $rc -ne 0 ]; then
        echo "$name: Ruby FAILED unexpectedly (status $rc):"; head -5 "$tmp/err"; status=1
        continue
    fi

    cp "$tmp/out" "$dir/expected.html"
    if [ -s "$tmp/err" ]; then
        cp "$tmp/err" "$dir/expected.stderr"
    else
        rm -f "$dir/expected.stderr"
    fi
    echo "$name: written"
done
exit $status
