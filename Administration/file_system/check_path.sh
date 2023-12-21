#!/bin/bash

echo "$PATH" | grep -q -E "$(pwd):|:$(pwd):|:$(pwd)$" &&  echo "Success"
echo "$PATH" | grep -q -E "$(pwd):|:$(pwd):|:$(pwd)$" ||  echo "Failed"
