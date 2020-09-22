# .buildenv

This directory contains build and packaging resources.  Each repository
that requires rpm packaging will need this directory and with it's contents
customized for the repo.

### Contents ###
  - pkginfo.sh - Contains static details used for generating the rpm package
    - LICENSE="<txt>" (optional)
    - VENDOR_NAME="CompanyName"
    - VENDOR_EMAIL="CompanyEmail"
    - VENDOR_DOMAIN="CompanyDomain"
    - SOURCE_FILE=<full path to the rpm spec file>  (optional)
  - version.sh - Contains frequently changing version information
    - PKG_NAME=<your_pkg_name>
    - PKG_VERSION=1.0.0
    - PKG_RELEASE=1
    - VERSION_NUMBER=${PKG_NAME}-${PKG_VERSION}-${PKG_RELEASE}
    - LAST_VER=<your_pkg_name>-2.0.70-1  # Should be automatically updated by
        your build automation when the package version changes
  - rpm.spec - Template for the rpm spec file that defines the rpm contents,
       layout, install/uninstall scripts, etc.  Certain macros in this template
       (i.e. versions and such), get automatically populated before rpm
       generation
  - pkgrpm - A dynamically generated directory containing the rpm staging area,
             generated configs, generated tool wrappers, and the resulting rpm(s).
             This directory can be safely deleted.
  - .gitignore - Used to instruct git to ignore the pkgrpm directory

### Maintenance ###
  - The pkgrpm directory is entirely generated and can be safely removed and
    recreated.  It should not be checked in to the code repository
