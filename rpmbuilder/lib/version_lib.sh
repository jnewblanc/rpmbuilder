# version_lib.sh - Version related functions
#
# Requires WSROOT to be set to the full path of the workspace
#


#
# load_version <version_file>
#
# load version info file
#
# $1 = full path to the package file
#
load_version() {
  # $ECHO "# Loading version information"

  local VERSION_FILE=$1

  if [ "${VERSION_FILE}" = "" ]; then
    $ECHO "# Version file not defined."
  else
    if [ -f "${VERSION_FILE}" ]; then
      . ${VERSION_FILE}
    else
      $ECHO -e "# Version file not found:\n#  ${VERSION_FILE}"
    fi
  fi

  if [ "${PKG_NAME}" = "" ]; then
    PKG_NAME="none"
  fi
  if [ "${PKG_VERSION}" = "" ]; then
    PKG_VERSION="none"
  fi
  if [ "${PKG_RELEASE}" = "" ]; then
    PKG_RELEASE="none"
  fi
  if [ "${buildtype}" = "experimental" ]; then
    PKG_RELEASE="${TIMESTAMP}"
  fi

  export VERSION_NUMBER
  export PKG_VERSION
  export PKG_RELEASE
  export LAST_VER

  $ECHO "# Version Info: ${VERSION_NUMBER}"
}


#
#############
split_version()
{
  local VER=$1
  #Split up the major, minor, and macro portions of the version

  # The first sed chops off the PKG_NAME, if it exists
  # The second sed pulls out a specific part of the version number
  export VER_NAME=`$ECHO $VER | $SED -e 's/^\([^-]\+\)-.*/\1/'`
  export VER_MAJOR=`$ECHO $VER | $SED -e "s/${VER_NAME}-//" | $SED 's/^\([0-9]\{1,\}\).\([0-9]\{1,\}\).\([0-9]\{1,\}\)-\([0-9]\{1,\}\)$/\1/g'`
  export VER_MINOR=`$ECHO $VER | $SED -e "s/${VER_NAME}-//" | $SED 's/^\([0-9]\{1,\}\).\([0-9]\{1,\}\).\([0-9]\{1,\}\)-\([0-9]\{1,\}\)$/\2/g'`
  export VER_MACRO=`$ECHO $VER | $SED -e "s/${VER_NAME}-//" | $SED 's/^\([0-9]\{1,\}\).\([0-9]\{1,\}\).\([0-9]\{1,\}\)-\([0-9]\{1,\}\)$/\3/g'`
  export VER_PATCH=`$ECHO $VER | $SED -e "s/${VER_NAME}-//" | $SED 's/^\([0-9]\{1,\}\).\([0-9]\{1,\}\).\([0-9]\{1,\}\)-\([0-9]\{1,\}\)$/\4/g'`
}


# calculate the the new version numbers
#
# First argument is the version number to increment
# second argument is the part of the version to increment.
#
###################
compute_new_version()
{
  local ver=$1
  local inc_part=$2
  local quiet=$3

  split_version ${ver}

  if [ "${inc_part}" = "major" ]; then
    if [ "${quiet}" != "quiet" ]; then
      $ECHO "# Incrementing the major version"
    fi
    if [ "${VER_MAJOR}" = "" ]; then
      VER_MAJOR=0
    else
      GREPOUT=`echo ${VER_MAJOR} | egrep "[^0-9]+"`
      if [ "${GREPOUT}" != "" ]; then
        echo "ERROR: compute_new_version - VER_MAJOR is not an integer: ${VER_MAJOR}"
      fi
      VER_MAJOR=`$EXPR \( ${VER_MAJOR} + 1 \)`
    fi
  fi

  if [ "${inc_part}" = "minor" ]; then
    if [ "${quiet}" != "quiet" ]; then
      $ECHO "# Incrementing the minor version"
    fi
    if [ "${VER_MINOR}" = "" ]; then
      VER_MINOR=0
    else
      GREPOUT=`echo ${VER_MINOR} | egrep "[^0-9]+"`
      if [ "${GREPOUT}" != "" ]; then
        echo "ERROR: compute_new_version - VER_MINOR is not an integer: ${VER_MINOR}"
      fi
      VER_MINOR=`$EXPR \( ${VER_MINOR} + 1 \)`
    fi
  fi

  if [ "${inc_part}" = "macro" ]; then
    if [ "${quiet}" != "quiet" ]; then
      $ECHO "# Incrementing the macro version"
    fi
    if [ "${VER_MACRO}" = "" ]; then
      VER_MACRO=0
    else
      GREPOUT=`echo ${VER_MACRO} | egrep "[^0-9]+"`
      if [ "${GREPOUT}" != "" ]; then
        echo "ERROR: compute_new_version - VER_MACRO is not an integer: ${VER_MACRO}"
      fi
      VER_MACRO=`$EXPR \( ${VER_MACRO} + 1 \)`
    fi
  fi

  if [ "${inc_part}" = "buildnum" -o "${inc_part}" = "patch" ]; then
    if [ "${quiet}" != "quiet" ]; then
      $ECHO "# Incrementing the build number"
    fi
    if [ "${VER_PATCH}" = "" ]; then
      VER_PATCH=0
    else
      GREPOUT=`echo ${VER_PATCH} | egrep "[^0-9]+"`
      if [ "${GREPOUT}" != "" ]; then
        echo "ERROR: compute_new_version - VER_PATCH is not an integer: ${VER_PATCH}"
      fi
      VER_PATCH=`$EXPR \( ${VER_PATCH} + 1 \)`
    fi
  fi

  PKG_VERSION_NEW=${VER_MAJOR}.${VER_MINOR}.${VER_MACRO}
  PKG_RELEASE_NEW=${VER_PATCH}
}

######################
# replace_version_file - update the version number (pkg) file with the new
#                        version numbers
#
# *** requires ${pkg_id} to be set to the name of the package (version #) file
# $1 - new version number
# $2 - new release number
replace_version_file()
{
  local PKG_NAME=$1
  local PKG_VERSION_NEW=$2
  local PKG_RELEASE_NEW=$3
  local PKG_VERSION_OLD=$4
  local PKG_RELEASE_OLD=$5
  local ALT_VER_FILENAME=$6


  if [ "${PKG_VERSION_NEW}" = "" -o "${PKG_RELEASE_NEW}" = "" ]; then
    $ECHO "# Did not update version file - New versions not specified"
  elif [ "${PKG_VERSION_NEW}" = "${PKG_VERSION_OLD}" -a "${PKG_RELEASE_NEW}" = "${PKG_RELEASE_OLD}" ]; then
    $ECHO -n "# Did not update version file: "
    $ECHO -n "new (${PKG_VERSION_NEW}-${PKG_RELEASE_NEW}) "
    $ECHO "-=- (${PKG_VERSION_OLD}-${PKG_RELEASE_OLD}) old"
  elif [ "${WSROOT}" = "" ]; then
    $ECHO "# Did not update version file - Workspace is not specified"
  else

    VERSION_FILENAME=".buildenv/version.sh"
    if [ ! -f "${WSROOT}/${VERSION_FILENAME}" ]; then
      if [ "${ALT_VER_FILENAME}" != "" ]; then
        VERSION_FILENAME="${ALT_VER_FILENAME}"
      fi
      if [ ! -f "${WSROOT}/${VERSION_FILENAME}" ]; then
        $ECHO "# replace_version_file: Error - Can not find version file ${WSROOT}/${VERSION_FILENAME}.  Aborting"
        return 1
      fi
    fi

    $SED -e s/^PKG_VERSION=.*$/PKG_VERSION=${PKG_VERSION_NEW}/g \
         -e s/^PKG_RELEASE=.*$/PKG_RELEASE=${PKG_RELEASE_NEW}/g \
         -e s/^LAST_VER=.*$/LAST_VER=${PKG_VERSION_OLD}-${PKG_RELEASE_OLD}/g \
         ${WSROOT}/${VERSION_FILENAME} > ${WSROOT}/${VERSION_FILENAME}.new
    $MV -f ${WSROOT}/${VERSION_FILENAME} ${WSROOT}/${VERSION_FILENAME}.old
    $MV -f ${WSROOT}/${VERSION_FILENAME}.new ${WSROOT}/${VERSION_FILENAME}

    ### The correct branch getst updated by default

    cd ${WSROOT}
    VERCOMMIT_FILES=${VERSION_FILENAME}
    $ECHO -n "# Updating version file to be "
    $ECHO "${PKG_NAME}-${PKG_VERSION_NEW}-${PKG_RELEASE_NEW}"
    if [ "${VERCOMMIT_FILES}" = "" ]; then
      $ECHO "# No files to commit"
    else
      COMMIT_MSG="# Automated version update: ${PKG_NAME}-${PKG_VERSION_NEW}-${PKG_RELEASE_NEW}\n\n"
#      vcs_commit "${VERCOMMIT_FILES}" "${COMMIT_MSG}"
    fi
  fi

}
