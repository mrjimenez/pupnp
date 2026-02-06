#! /bin/bash

# If DEBUG is unset, set it to "n"
: <<< "${DEBUG:=n}"

# Assign a default value when testing
: <<< "${GITHUB_STEP_SUMMARY:=/dev/stdout}"

check_release () {
    local TAG_VALUE=$1
    local TAG_NAME=$2

    if [[ -z ${TAG_VALUE} ]]; then
        echo "${TAG_NAME} is empty"
        exit 1
    fi

    local PATTERN="[0-9]+\.[0-9]+\.[0-9]+$"
    if [[ ! ${TAG_VALUE} =~ ${PATTERN} ]]; then
        echo "${TAG_NAME} does not respect the pattern: \"${TAG_VALUE} =~ ${PATTERN}\""
        exit 2
    fi
}

check_release "${next_release:-}" "Next release"

# Creates temporary files
CHANGELOG_TEMPLATE=$(mktemp) || exit 1
CONFIGURE_AC_TEMPLATE=$(mktemp) || exit 1

# shellcheck disable=SC2329
cleanup_on_exit() {
    rm -f "${CHANGELOG_TEMPLATE}"
    rm -f "${CONFIGURE_AC_TEMPLATE}"
}

# Makes sure it will be gone
trap cleanup_on_exit EXIT

################################################################################
# The changelog template
################################################################################
cat > "${CHANGELOG_TEMPLATE}" << EOF
*******************************************************************************
Version "${next_release}"
*******************************************************************************



EOF

# Fix the ChangeLog file using the template
cat "${CHANGELOG_TEMPLATE}" ChangeLog > ChangeLog.tmp
mv ChangeLog.tmp ChangeLog

################################################################################
# Fix Doxyfile and spec file using simple sed substitution
################################################################################
sed -i "s/^PROJECT_NUMBER.*/PROJECT_NUMBER         = ${next_release}/" docs/Doxyfile
sed -i "s/^Version:.*/Version: ${next_release}/" libupnp.spec

################################################################################
# Fix the configure.ac file
#
# configure.ac is more challenging because we need to parse it to get the
# libtool numbers.
################################################################################

# Find out the line number of AC_INIT
line=$(sed -n "/AC_INIT/=" configure.ac)

# Read the two AC_SUBST([LT_VERSION_*]) lines to parse them in the sequence
line_ixml=$(sed -n -E "$((line+1)) p" configure.ac)
line_upnp=$(sed -n -E "$((line+2)) p" configure.ac)

# Find out the libtool version numbers for IXML
libtool_pattern=".*\[([0-9]+):([0-9]+):([0-9]+)\]\)"
current_ixml=$(echo "${line_ixml}" | sed -E "s/${libtool_pattern}/\1/")
revision_ixml=$(echo "${line_ixml}" | sed -E "s/${libtool_pattern}/\2/")
age_ixml=$(echo "${line_ixml}" | sed -E "s/${libtool_pattern}/\3/")
# We almost never change IXML, so if necessary, do it by hand.
new_revision_ixml=$((revision_ixml+0))

# Find out the libtool version numbers for UPNP
current_upnp=$(echo "${line_upnp}" | sed -E "s/${libtool_pattern}/\1/")
revision_upnp=$(echo "${line_upnp}" | sed -E "s/${libtool_pattern}/\2/")
age_upnp=$(echo "${line_upnp}" | sed -E "s/${libtool_pattern}/\3/")
new_revision_upnp=$((revision_upnp+1))

################################################################################
# The configure.ac template
################################################################################
cat > "${CONFIGURE_AC_TEMPLATE}" << EOF
AC_INIT([libupnp],[${next_release}],[mroberto@users.sourceforge.net])
AC_SUBST([LT_VERSION_IXML], [$current_ixml:$new_revision_ixml:$age_ixml])
AC_SUBST([LT_VERSION_UPNP], [$current_upnp:$new_revision_upnp:$age_upnp])
dnl ############################################################################
dnl # Release ${next_release}
dnl # "current:revision:age"
dnl #
dnl # - Code has changed in upnp
dnl #   revision: aaa_1_1 -> aaa_1_2
dnl # - interfaces changed/added/removed in upnp
dnl #   current: bbb_1_1 -> bbb_1_2
dnl #   revision: ccc_1_1 -> 0
dnl # - interfaces added in upnp
dnl #   age: ddd_1_1 -> ddd_1_2
dnl # - interfaces removed or changed in upnp
dnl #   age: eee_1_1 -> 0
dnl #
dnl # - Code has changed in ixml
dnl #   revision: aaa_2_1 -> aaa_2_2
dnl # - interfaces changed/added/removed in ixml
dnl #   current: bbb_1_1 -> bbb_1_2
dnl #   revision: ccc_1_1 -> 0
dnl # - interfaces added in ixml
dnl #   age: ddd_1_1 -> ddd_1_2
dnl # - interfaces removed or changed in ixml
dnl #   age: eee_1_1 -> 0
dnl #
dnl #AC_SUBST([LT_VERSION_IXML], [$current_ixml:$revision_ixml:$age_ixml])
dnl #AC_SUBST([LT_VERSION_UPNP], [$current_upnp:$revision_upnp:$age_upnp])
EOF

# Delete the two AC_SUBST([LT_VERSION_*]) lines
sed -i -E "$((line)),+2d" configure.ac
# Add the template at the right place
sed -i -E "$((line-1)) r ${CONFIGURE_AC_TEMPLATE}" configure.ac

exit 0
