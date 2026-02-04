#! /bin/bash

TAG_NAME=${1:-release-1.14.21}

#
# Parse the tag name
prefix=$(echo "${TAG_NAME}" | sed -E 's/release-([0-9]+)\.([0-9]+)\.([0-9]+)/\1.\2/')
minor=$(echo  "${TAG_NAME}" | sed -E 's/release-([0-9]+)\.([0-9]+)\.([0-9]+)/\3/')
#
# Increment the minor
next_minor=$((minor+1))
#
# Build the release numbers
curr_release="${prefix}.${minor}"
next_release="${prefix}.${next_minor}"
#
# export results
export curr_release next_release
