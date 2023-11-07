#!/bin/bash

#unset DOT_REMOVED SCRIPT_PATH
DOT_REMOVED=$(echo "$0" | sed "s/^\.//g; s/\/[[:alpha:]]*$//g")
SCRIPT_PATH="$(pwd)${DOT_REMOVED}"

echo "$SCRIPT_PATH"