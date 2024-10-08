#!/bin/bash

echo "Using OPERATOR_PATH: ${OPERATOR_PATH}"

# Check if .gitignore exists
if [ ! -f ".gitignore" ]; then
    touch .gitignore
    echo ".gitignore created."
fi

# Loop through all .gitignore files in the specified directory
gifiles=("$OPERATOR_PATH"/gitignore/*.gitignore)

for file in "${gifiles[@]}"; do
    # Check if the file exists and is a regular file
    echo "Checking $file"
    # Check if the file exists and is a regular file
    if [[ -f "$file" ]]; then
        # Read the content of the file
        while IFS= read -r line; do
            # Check if the line already exists in .gitignore
            if ! grep -qxF "$line" .gitignore; then
                echo "$line" >> .gitignore
                echo "Appended line from $file to .gitignore: $line"
            else
                echo "Line from $file already exists in .gitignore: $line"
            fi
        done < "$file"
    fi
done
