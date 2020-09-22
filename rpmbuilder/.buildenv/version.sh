# version.sh - Version information which is read and updated by the build
#              environment.

# The current version (i.e. the version that will be built next)
PKG_NAME=rpmbuilder
PKG_VERSION=0.1.0
PKG_RELEASE=1
VERSION_NUMBER=${PKG_NAME}-${PKG_VERSION}-${PKG_RELEASE}

# LAST_VER should get updated whenever the version changes.  Enables tracking
# across version bumps and release branches 
LAST_VER=rpmbuilder-0.0.0-1

# EOF PACKAGE
