#!/bin/bash

DIR_NAMES=("apples" "bananas" "grapes")
DOT_REMOVED=$(echo "$0" | sed "s/^\.//g")
SCRIPT_PATH="$(pwd)${DOT_REMOVED///dir_mixed_permit.sh/}"

cd "$HOME" || exit

echo -e "\nCleaning up the $1 directory"
rm -r "$1"

echo -e "\nCreating directories..."
mkdir -p "$1"/apples "$1"/bananas "$1"/grapes


echo -e "\nCreating files in the directories..."
for dir in "${DIR_NAMES[@]}"; do
  while IFS= read -r line
  do
    touch "$1"/"$dir"/"$line"
  done < "${SCRIPT_PATH}/file_names.txt"
done

echo -e "\nChanging the directories permissions..."
chmod -R 750 "$1"/"${DIR_NAMES[0]}"
chmod -R 400 "$1"/"${DIR_NAMES[1]}"
chmod -R 100 "$1"/"${DIR_NAMES[2]}"

echo -e "\nChecking the directories permissions..."
ls -lhi "$1"/*
sleep 3
