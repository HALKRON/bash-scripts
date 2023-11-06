#!/bin/bash

DOT_REMOVED=$(echo "$0" | sed "s/^\.//g")
echo "$(pwd)${DOT_REMOVED//get_script_path.sh/}"
