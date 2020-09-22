# globals.sh
#
# define global variables used throughout the rpm packaging.  These are variables
# that don't change often and are typically identical between repositories
#

DEBUG="False"
SIGNRPM="True"

if [ "${KEY_NAME}" = "" ]; then
  KEY_NAME="devOps <devOps@example.com>"
fi
if [ "${KEY_PATH}" = "" ]; then
  KEY_PATH="/home/build/.gnupg"
fi
if [ "${KEY_FILE_BASE}" = "" ]; then
  KEY_FILE_BASE="example_pgp_key"
fi

if [ "${PLAT}" = "" ]; then
RAW_PLAT=$(uname -a | cut -d' ' -f 3)
  PLAT="${RAW_PLAT}"
fi
if [ "${ARCHITECTURE}" = "" ]; then
  ARCHITECTURE=$(uname -m)
fi

# WSROOT is a full path to the workspace that contains the programs and
# spec files.  It typically gets set on the command line or through env vars.

# For details on other global variables, see the readme in the .buildenv
# directory
