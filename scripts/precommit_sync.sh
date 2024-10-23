#!/bin/bash

echo "Using OPERATOR_PATH: ${OPERATOR_PATH}"
finame_name=".pre-commit-config.yaml"

# Check if .pre-commit-config.yaml exists
if [ ! -f "${finame_name}" ]; then
    touch "${finame_name}"
    echo "${finame_name} created."
fi

# Loop through all .yaml files in the specified directory
gifiles=("$OPERATOR_PATH"/pre-commit-hooks/*.yaml)

for file in "${gifiles[@]}"; do
    # Check if the file exists and is a regular file
    echo "Checking $file"
    if [[ -f "$file" ]]; then
        # Read the content of the file
        while IFS= read -r line; do
            # Skip lines containing "hooks"
            if [[ "$line" == *"hooks"* ]]; then
                echo "$line" >> "${finame_name}"
                echo "Appended line from $file to ${finame_name}: $line"
                continue
            fi
            # Check if the line already exists in ${finame_name}
            if ! grep -qxF "$line" "${finame_name}"; then
                echo "$line" >> "${finame_name}"
                echo "Appended line from $file to ${finame_name}: $line"
            else
                echo "Line from $file already exists in ${finame_name}: $line"
            fi
        done < "$file"
    fi
done
