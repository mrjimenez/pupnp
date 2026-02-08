#! /bin/bash

# If DEBUG is unset, set it to "n"
: <<< "${DEBUG:=n}"

# Same for TEST_DATA
: <<< "${TEST_DATA:=n}"

# This array trick is only necessary locally, when
# there might be some old tar ball lying around.
#
# Find the name of the generated tar ball.
if [[ $TEST_DATA == n ]]; then
	# bz2_files=($(ls libupnp-*.tar.bz2))
	# mapfile -t bz2_files < <(ls libupnp-*.tar.bz2)
	# Simplest way:
	bz2_files=(libupnp-*.tar.bz2)
else
	# Make up a test example
	bz2_files=(
		libupnp-10.2.3.tar.bz2
		libupnp-1.20.3.tar.bz2
		libupnp-1.2.3.tar.bz2
		libupnp-2.3.4.tar.bz2
		libupnp-2.3.5.tar.bz2
	)
fi

# "sort -V" sorts version numbers within the name as we expecte.
#sorted_bz2_files=($(echo "${bz2_files[*]}" | tr ' ' '\n' | sort -V))
mapfile -t sorted_bz2_files < <(echo "${bz2_files[*]}" | tr ' ' '\n' | sort -V)

# Get the last result of the "ls" command.
# Bash arrays are zero based, Zsh arrays are one based.
# Bash allows negative index.
bz2_name=${sorted_bz2_files[-1]}
if [[ $DEBUG != n ]]; then
	echo "bz2_files=\"${bz2_files[*]}\""
	echo "bz2_name=$bz2_name"
fi
if [[ -z "${bz2_name}" ]]; then
	echo "Error: bz2_name is empty"
	exit 1
fi

# Save in the environment
echo "bz2_name=${bz2_name}" >> "$GITHUB_ENV"
# Print in the summary
{
	echo
	echo "bz2_name=${bz2_name}"
} >> "$GITHUB_STEP_SUMMARY"

# Try via "step" output parameter
# ${{ steps.find-bz-name.outputs.bz2_name }}
echo "bz2_name=${bz2_name}" >> "$GITHUB_OUTPUT"

# Export the result
export bz2_name
