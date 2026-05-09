#!/bin/bash

# This script scans all Localizable.strings files, searching for all strings
# which are not referenced from code. It finds string resources which have are not used by the 
# application code and should be deleted.
# 
# Output is written to the console but can be redirected into a file for convenience.
#
# All Swift files are scanned.
#
# Usage:
#     Run this script from the root of the workspace, for example ~/src/caffeinator
#
#     By default, output goes to the console:
#         bruce[~/src/caffeinator]$ ./Scripts/find-unused-strings.sh
#
#     Use tee to echo to the console and also write to a text file:
#         bruce[~/src/caffeinator]$ ./Scripts/find-unused-strings.sh | tee unused-strings.txt
#

# Set the field separator to a newline to handle spaces in file names
IFS=$'\n'

# Define the locations of the Localizable.strings files
# strings_files=("Caffeinator/Caffeinator/Resources/Localizable.strings" "Unified/Unified/es.lproj/Localizable.strings" "Unified/Unified/ru.lproj/Localizable.strings")
strings_files=("Caffeinator/Caffeinator/Resources/Localizable.strings")

# Find all Swift files in the project directories
swift_files=$(find Caffeinator -name "*.swift")

# Count the number of Swift files to be scanned
echo -n "Counting all Swift source files..."
num_swift_files=$(echo "$swift_files" | wc -l)
printf "%d files found\n" "$num_swift_files"

# Read the contents of all Swift files into a (big) shell variable so our scans occur in memory and not
# by inefficiently grepping every source file in the filesystem.
echo -n "Reading and caching all Swift source files into memory..."
all_files_content_cache=""
for swift_file in $swift_files; do
    all_files_content_cache+=$(cat "$swift_file")
done
echo "done"

# Iterate over each Localizable.strings file
for strings_file in "${strings_files[@]}"; do
    echo ""
    echo "Scanning $strings_file for unused strings..."
    echo "------------------------------------------------------------------------------------"

    num_unused_strings=0

    # Iterate over each line in the current Localizable.strings file
    while read -r line; do
        # Check if the line matches the regex for a string resource key
        if [[ "$line" =~ ^\"[^\"]+\"\ =\ \".*\" ]]; then
             # Grab the string key
            key=$(echo "$line" | cut -d '"' -f 2)

            # Search for reference(s) to the key in our in-memory cache of all Swift code
            if [[ ! $all_files_content_cache =~ $key ]]; then
                # The key was not found, print it to stdout and increment the counter
                echo "$key"
                ((num_unused_strings++))
            fi
        fi
    done < "$strings_file"

    # Print the number of unused strings found in the current Localizable.strings file
    echo ""
    printf "Found %d unused strings in %s\n" "$num_unused_strings" "$strings_file"
    echo ""
done

printf "Scanned %d Swift files\n" "$num_swift_files"
echo "Scan completed"
echo ""
