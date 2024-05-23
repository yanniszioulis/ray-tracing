#!/bin/bash

# Define the Python script filename
PYTHON_SCRIPT="convert.py"

# Run the Python script
python3 $PYTHON_SCRIPT

# Check if the Python script ran successfully
if [ $? -eq 0 ]; then
    echo "PPM to PNG conversion completed successfully."
else
    echo "There was an error running the Python script."
fi