#!/bin/bash

# The script performs the following:
# - Replaces the API endpoint string inside counter.js for production deployment
# - Copies all files (except js) as it is to ../dist folder for use with TF for production deployment

# Set the staging and prod APIs to find and replace
STAGING_API="https://stagingapi.kgmy.at/updateVisitors"
PROD_API="https://api.kgmy.at/updateVisitors"

# Set the input and output JS file names
INPUT_JS_FILE="../src/counter.js"
OUTPUT_JS_FILE="counter.js"

# Output directory
DIST_DIR="../dist"

# Check if the output directory exists and create if needed
if [ ! -d $DIST_DIR ]; then
  mkdir $DIST_DIR
fi

# Copy all files except javascript files to the output directory
find ../src -type f ! -name "*.js" -exec cp {} $DIST_DIR \;

# Use sed to find and replace the old value with the new value
sed "s|$STAGING_API|$PROD_API|g" $INPUT_JS_FILE > $DIST_DIR/$OUTPUT_JS_FILE

# Print a message indicating the operation was successful
echo "Check dist folder at $DIST_DIR"
