# The __VALUES__ in the block below get autopopulated - do not change
%define wsroot           __WSROOT__
%define build_plat       __PLAT__
%define build_arch       __ARCH__
%define pkg_name         __PKG_NAME__
%define pkg_version      __PKG_VERSION__
%define pkg_release      __PKG_RELEASE__
%define pkg_license      __LICENSE__
%define pkg_date         __PKG_DATE__
%define pkg_vendor_name  __VENDOR_NAME__
%define pkg_vendor_email __VENDOR_EMAIL__

# The following section is standard rpm boilerplate
Name:      %{pkg_name}
Version:   %pkg_version
Release:   %pkg_release
License:   %pkg_license
Icon:      icon.xpm
Vendor:    %pkg_vendor_name
Packager:  %pkg_vendor_name <%pkg_vendor_email>
Prefix:    %pkg_dest
Group:     Applications/Misc
Summary:   This is the %{pkg_name} package
BuildRoot: %wsroot/pkgrpm/BUILD

# Define the install directory - use a macro in case we need to move it at a
# later date
%define installdir /opt/rpmbuilder

%description
The rpmbuilder package is a set of tools that are used for generating rpms
from a code repository.

BUILD_NAME=%pkg_name

%changelog
* %pkg_date - %pkg_vendor_email
- Package created

# This can be used to disable automated dependency checking
# AutoReqProv: no

# Create the directory structure as needed
%prep

# No need for "build" - sources are built externally via CI/CD platform, if needed
%build

# Create the staging area for the rpm package
%install

mkdir -p ${RPM_BUILD_ROOT}/%installdir
rsync -av --exclude ".git" \
  %{wsroot}/globals.sh \
  ${RPM_BUILD_ROOT}/%installdir

mkdir -p ${RPM_BUILD_ROOT}/%installdir/bin
rsync -av \
  %{wsroot}/bin/rpmcreate.sh \
  ${RPM_BUILD_ROOT}/%installdir/bin

mkdir -p ${RPM_BUILD_ROOT}/%installdir/lib
rsync -av \
  %{wsroot}/lib/rpm_lib.sh \
  %{wsroot}/lib/version_lib.sh \
  ${RPM_BUILD_ROOT}/%installdir/lib

mkdir -p ${RPM_BUILD_ROOT}/%installdir/.buildenv
rsync -av \
  %{wsroot}/.buildenv/rpm.spec \
  %{wsroot}/.buildenv/version.sh \
  ${RPM_BUILD_ROOT}/%installdir/buildenv

mkdir -p ${RPM_BUILD_ROOT}/%installdir/secrets
rsync -av \
  %{wsroot}/secrets/example_pgp_key.pub \
  ${RPM_BUILD_ROOT}/%installdir/gpgkey.pub


# "pre" - pre-install script - runs before package is installed
#   Use this to stop services prior to install
%pre

# "post" - post-install script - runs after package have been installed
#   Use this to add users if necessary
#   Use this to force log rotation
#   Use this to start services after install
%post
# Run hook - can be used to change destination env/creds
if [ -x "%installdir/post_install_hook.sh" ]; then
  echo "Running %installdir/post_install_hook.sh"
  %installdir/post_install_hook.sh
  echo "Done with %installdir/post_install_hook.sh"
fi

if [ -f %installdir/gpgkey.pub ]; then
  echo "Importing devOps public key"
  echo "  rpm --import %installdir/gpgkey.pub"
  rpm --import %installdir/gpgkey.pub
fi

# "preun" - pre-uninstall script - runs before package is uninstalled
%preun

# "postun" - post-uninstall script - runs after package has been uninstalled
%postun

# "verifyscript" - runs when rpm --verify is run
%verifyscript

%files
%defattr(-,build,build,750)
%installdir
# %config
# %attr(<mode>, <user>, <group>) file
