#!/bin/sh
#
# wrapper script to automatically generate and sign rpms in a local directory
#
# rpm_create.sh -ws /home/user/work/myrepo -pkgname zipper -pkgver 2.1.0 -pkgrel 1 -spec ./zipper.spec
#

BINDIR=$(cd $(/bin/dirname $0); pwd)
RBDIR=$(cd ${BINDIR}/..; pwd)

if [ ! -d "${BINDIR}" ]; then
  echo "Can not find script directory ${BINDIR}"
  echo "Aborting..."
  exit 1
else
  # Load globals and libs
  #  This needs to happen before command line parsing so that default values can be overwritten
  . ${RBDIR}/globals.sh
  . ${RBDIR}/lib/rpm_lib.sh
  . ${RBDIR}/lib/log_lib.sh
  . ${RBDIR}/lib/secrets_lib.sh
fi

# Parse command line options
#
while [ $# -gt 0 ]; do
    if [ "$1" = "-debug" ]; then
      # the -x option turns on command echoing as the script runs
      set -x
      DEBUG_ARG="-d"
    elif [ "$1" = "-ws" ]; then
      shift; WSROOT=$1;
    elif [ "$1" = "-pkgname" ]; then
      shift; PKG_NAME=$1
    elif [ "$1" = "-pkgver" ]; then
      shift; export PKG_VERSION=$1
    elif [ "$1" = "-pkgrel" ]; then
      shift; export PKG_RELEASE=$1
    elif [ "$1" = "-spec" ]; then
      shift; export SPECTEMPLATE=$1
    elif [ "$1" = "-pkgdir" ]; then
      shift; export PKGDIR=$1
    elif [ "$1" = "-envfile" ]; then
      shift; export ENVFILE=$1
    fi
  shift
done

usage()
{
  echo `$BASENAME $0` " -ws <workspace> -pkgname <str> -pkgver <#.#.#> -pkgrel <#> [-pkgdir <dir>] [-envfile <file>]"
  echo "  -ws             - path to the workspace that contains the sources"
  echo "  -pkgname        - name of the package"
  echo "  -pkgver         - version number in the form #.#.#"
  echo "  -pkgrel         - release number, this is the part that comes after pkgver"
  echo "  -spec           - optional - full path to the rpm spec template"
  echo "  -pkgdir <dir>   - optional - directory to build rpm database"
  echo "  -envfile <file> - optional - directory to build rpm database"
  exit 1
}

# Support for setting environment vars via a file
if [ "${ENVFILE}" != "" -a -f "${ENVFILE}" ]; then
  . ${ENVFILE}
fi

if [ "${WSROOT}" = "" ]; then
  log "ERROR WSROOT not set"
  usage
fi

# Load version info if version isn't already set
if [ "${PKG_VERSION}" = "" -a -f "${WSROOT}/.buildenv/version.sh" ]; then
  log "INFO Loading version info from ${WSROOT}/.buildenv/version.sh"
  . ${WSROOT}/.buildenv/version.sh
fi

if [ "${PKG_NAME}" = "" ]; then
  log "ERROR PKG_NAME not set"
  usage
fi

if [ "${PKG_VERSION}" = "" ]; then
  log "ERROR PKG_VERSION not set"
  usage
fi

if [ "${PKG_RELEASE}" = "" ]; then
  log "ERROR PKG_RELEASE not set"
  usage
fi

if [ "${SPECTEMPLATE}" = "" ]; then
  log "WARNING SPECTEMPLATE not set - defaulting to ${WSROOT}/.buildenv/rpm.spec"
  SPECTEMPLATE="${WSROOT}/.buildenv/rpm.spec"
fi

if [ "${PKGDIR}" = "" ]; then
  # This assumes that the repo is clean every time, which is a best practice
  log "WARNING PKGDIR not set - Defaulting to ${WSROOT}/.buildenv/pkgrpm"
  PKGDIR=${WSROOT}/.buildenv/pkgrpm
fi

log "INFO Running $0"

# Load pkg info
if [ -f "${WSROOT}/.buildenv/pkginfo.sh" ]; then
  . ${WSROOT}/.buildenv/pkginfo.sh
fi

log "INFO Logging to ${PKGDIR}/rpm.log"

if [ -f "${SPECTEMPLATE}" ]; then
   create_rpm "${SPECTEMPLATE}" "${PKGDIR}" "${PKGDIR}/rpm.log"
else
  log "ERROR Can not find spec template at ${SPECTEMPLATE}"
fi

if [ "${DEBUG}" != "False" ]; then
  cat ${PKGDIR}/rpm.log
fi
