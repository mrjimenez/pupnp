#! /bin/bash

# If DEBUG is unset, set it to "n"
: <<< "${DEBUG:=n}"

TAG_NAME=$1

if [[ -z $TAG_NAME ]]; then
	echo "Tag name is empty"
	exit 1
fi

PATTERN="release-[0-9]+\.[0-9]+\.[0-9]+$"
if [[ ! $TAG_NAME =~ $PATTERN ]]; then
	echo "Tag name does not respect the pattern: \"$TAG_NAME =~ $PATTERN\""
	exit 2
fi

#
# The expression $$((10#$variable)) forces base 10 interpretation and gets rid of
# leading zeroes. Otherwise, things like "010" would be interpreted as octal and
# become "8".
#

echo TAG_NAME="${TAG_NAME}"

parsed_release="${TAG_NAME#release-}"
parsed_prefix="${parsed_release%.*}"

current_major="${parsed_release%.*.*}"
current_major=$((10#$current_major))

current_minor="${parsed_release#*.}"
current_minor="${current_minor%.*}"
current_minor=$((10#$current_minor))

current_patch="${TAG_NAME##*.}"
current_patch=$((10#$current_patch))

next_patch=$((current_patch + 1))
curr_release=${current_major}.${current_minor}.${current_patch}
next_release=${current_major}.${current_minor}.${next_patch}

# Test if Github stuff is possible inside a script

# Copy the resulting variables to the environment
{
	echo "curr_release=${curr_release}"
	echo "next_release=${next_release}"
} >> "$GITHUB_ENV"

# Debug, print them in the step summary
{
	echo 
	echo "curr_release=${curr_release}"
	echo "next_release=${next_release}"
} >> "$GITHUB_STEP_SUMMARY"

if [[ $DEBUG != n ]]; then
	echo "Parsed  release is '${parsed_release}'"
	echo "Parsed  prefix  is '${parsed_prefix}'"
	echo "Current major   is '${current_major}'"
	echo "Current minor   is '${current_minor}'"
	echo "Current patch   is '${current_patch}'"
	echo "Next    patch   is '${next_patch}'"
	echo "Current release is '${curr_release}'"
	echo "Next    release is '${next_release}'"

	: <<- COMMENT
	Example output:

	$ ./scripts/parse_release.sh release-0010.020.030
	TAG_NAME=release-0010.020.030
	Parsed  release is '0010.020.030'
	Parsed  prefix  is '0010.020'
	Current major   is '10'
	Current minor   is '20'
	Current patch   is '30'
	Next    patch   is '31'
	Current release is '10.20.30'
	Next    release is '10.20.31'
	COMMENT
fi

#
# Old code, parsing was done with sed. Bash is much cleaner for simple stuff.
#
if false; then
	#
	# Parse the tag name
	prefix=$(echo "${TAG_NAME}" | sed -E 's/release-([0-9]+)\.([0-9]+)\.([0-9]+)/\1.\2/')
	patch=$(echo  "${TAG_NAME}" | sed -E 's/release-([0-9]+)\.([0-9]+)\.([0-9]+)/\3/')
	#
	# Increment the patch
	next_patch=$((patch+1))
	#
	# Build the release numbers
	curr_release="${prefix}.${patch}"
	next_release="${prefix}.${next_patch}"
fi

#
# Export the results
#export curr_release next_release
export next_release

exit 0
