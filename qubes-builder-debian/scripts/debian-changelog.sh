#!/bin/bash
# vim: set ts=4 sw=4 sts=4 et :

# =============================================================================
# This script is run before the Debian package is built and possibly updates
# the debian/changelog to indicate a devel or release version
# 
# There are 2 modes:
# 1. Development mode.  Will append devel# and increment it by one on each
#    build.  The changelogs will be saved in package/debain directory as
#    changlelog.$(DIST) and are copied into place at time of build for each
#    specific distribution
# 2. Release mode.  If the version number (minus epoc and release info) in 
#    package root directory differs from what is reported in changelog a 
#    release is created, updating the changelog with commits since previous
#    version and bumping the changelog version
#
# Addtionally, if the script is called with --verify option, it will only check
# if the debian/changelog entry matches version/rel file and set appropriate
# exit code.
# -----------------------------------------------------------------------------
# NOTES:
#
# Examples used within this script are using the following package for 
# reference:
#   core-agent-linux; release2 branch; tagged as v2.1.5.5
#   building in a wheezy chroot environment
# =============================================================================

if ! [ -r version ]; then
    echo "This package does not have version file, changelog will not be generated" >&2
    exit 0
fi

debchange=$(dirname ${0})/debchange
debian_parser=$(dirname ${0})/debian-parser

previous_changelog=debian/changelog
# Create seperate changelogs for each dist
if [ -n "${INCREMENT_DEVEL_VERSIONS}" ]; then
    previous_changelog=debian/changelog.dist
    if [ ! -e debian/changelog.dist ]; then
        cp -p debian/changelog debian/changelog.dist
    fi
    if [ -e debian/changelog.${DIST} ]; then
        cp -fp debian/changelog.${DIST} debian/changelog
    else
        cp -fp debian/changelog.dist debian/changelog
    fi
fi

deb_version=$($debian_parser changelog --package-version $previous_changelog)
deb_revision=$($debian_parser changelog --package-revision $previous_changelog)
deb_epoc=$($debian_parser changelog --package-version-epoc $previous_changelog)

# drop dist-specific suffix for version comparision
deb_revision=${deb_revision%+deb*}

version="$(cat version|sed 's/-rc/~rc/')"
# only two components supports non-default revisions: linux-kernel and vmm-xen
revision="$(cat rel 2>/dev/null)"
previous_tag="v${deb_version/\~/-}-${deb_revision}"
if [ -z "$revision" ]; then
    revision="1"
    previous_tag="v${deb_version/\~/-}"
fi
if [ -z "$deb_revision" ]; then
    revision=""
fi

if [ "x$1" = "x--verify" ]; then
    if [ "${deb_version}-${deb_revision}" = "${version}-${revision}" ]; then
        exit 0
    else
        echo "Version mismatch: ${deb_version}-${deb_revision} in debian/changelog but ${version}-${revision} in version+rel" >&2
        exit 1
    fi
fi


# =============================================================================
#                            R E L E A S E   M O D E 
# =============================================================================
# Release version: Update changelog with commit history
# -----------------------------------------------------------------------------
#           --newversion:  Specifies the new version number
#          --no-auto-nmu:  Disable automatic non-maintainer upload detection
#   --nomultimaint-merge:  Do not merge all changes made by same author into
#                          same changelog section
#           --multimaint:  Indicate parts of a changelog entry have been made
#                          by different maintainers
if [ "${deb_version}-${deb_revision}" != "${version}-${revision}" ]; then
    # -----------------------------------------------------------------------------
    # Create new version number adding epoc and revision info for quilt packages
    # if they exist
    # -----------------------------------------------------------------------------
    if [ "X${deb_revision}" == "X" ]; then
        new_version="${version}"
    else
        new_version="${version}-${revision}"
        if [ "X${deb_epoc}" != "X" ]; then
            new_version="${deb_epoc}:${new_version}"
        fi
    fi

    # -----------------------------------------------------------------------------
    # Add new version number and git commit history to changelog
    # -----------------------------------------------------------------------------
    IFS=%
    (git log --no-merges --topo-order --reverse --pretty=format:%an%%%ae%%%ad%%%s ${previous_tag}..HEAD;echo) |\
        while read a_name a_email date sum; do
            export DEBFULLNAME="${a_name}"
            export DEBEMAIL="${a_email}"
            ${debchange} --newversion=${new_version} --no-auto-nmu --nomultimaint-merge --multimaint -- "${sum}"
        done

    # -----------------------------------------------------------------------------
    # Release - changelog name, email and distribution updated
    # -----------------------------------------------------------------------------
    export DEBFULLNAME=$(git config user.name)
    export DEBEMAIL=$(git config user.email)
    ${debchange} --force-distribution --distribution ${DIST} --release -- ''
fi


# =============================================================================
#                            D E V E L O P   M O D E 
# =============================================================================
# Devel version: Update changelog
# -----------------------------------------------------------------------------
# Check to see if the debain changelog contains ?devel in the version number
# - If it does; update the changelog, then exit with...
#            DEBFULLNAME:  Add users git name to changelog entry
#                DEBNAME:  Add users git email address to changelog entry
#   --nomultimaint-merge:  Do not merge all changes made by same author into
#                          same changelog section
#           --multimaint:  Indicate parts of a changelog entry have been made
#                          by different maintainers
#               -l~devel:  add a local suffix to the debian version of 
#                          '~devel'
#         --distribution:  Used in --release to change the DISTRIBUTION value
#                          in changelog to value provided ($DIST == wheezy)
#              --release:  Finalize the changelog for a release which updates
#                          timestamp, If DISTRIBUTION in changelog is set to 
#                          UNRELEASED change it to the distribution $DIST 
#                          (wheezy) 

#if [ -n "${INCREMENT_DEVEL_VERSIONS}" ] && [[ "${deb_version}" == $(cat version)?(devel*) ]]; then
if [ -n "${INCREMENT_DEVEL_VERSIONS}" ]; then
    export DEBFULLNAME=$(git config user.name)
    export DEBEMAIL=$(git config user.email)
    ${debchange} --nomultimaint-merge --multimaint -l+${DIST_TAG}u1+devel -- 'Test build'
    ${debchange} --force-distribution --distribution ${DIST} --release -- ''

    # Save dist specific changlog for next time
    cp -fp debian/changelog debian/changelog.${DIST}
fi
