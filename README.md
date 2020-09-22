# rpmbuilder

A framework and collection of scripts to facilitate building rpms in a docker
container.

### Installation ###
1. Install docker
2. Clone rpmbuilder repo
3. Set ENV vars to define external repo with manifests and versions
4. run docker to build the image
  ```
  docker build -t rpmbuilder .
  ```
### Setup ###
1. Set WSROOT
   - WSROOT is an environment variable defining the full path to
     the workspace that contains the programs and spec files
   - WSROOT typically gets set on the command line, through env vars, or via
     docker-compose
2. Create the version and packaging files within the external repo (WSROOT/.buildenv)
   - Use the files at rpmbuilder/.buildenv/* as a template.  Be sure to update
     them with details pertaining to your repo and desired rpm(s).
   - See the README at rpmbuilder/.buildenv/README.md for details

### Execution ###
1. Run the docker container to generate the rpm
  ```
  docker-compose up
  ```
  - The resulting rpm(s) will be created in ${WSROOT}/.buildenv/pkgdir/RPMS
  - The resulting log resides at ${WSROOT}/.buildenv/pkgdir/rpm.log
  - Scripts/Wrappers for debugging are available in ${WSROOT}/.buildenv/pkgdir

### Out of scope - What rpmbuilder doesn't do ###
1. rpmbuilder does not build/compile binaries in the source repo.  It is
   expected that any build/compilation will occur before rpmbuilder.  While rpm
   is able to build/compile as part of package generation, we do not employ this
   functionality.
2. rpmbuilder does not auto increment the version number in the source repo's
   version.sh file.  Bumping the version is the responsibility of the builds.
   None-the-less, a helper script is included here (version_lib.sh).
3. rpmbuilder does not ensure that your repo is clean.  As per best
   build/release practices, rpmbuilder should only be run on builds/workspaces
   that haven't been packaged before.  While there are several checks to prevent
   rpmbuilder from running on a previously packaged workspace, the responsibility
   of using a clean workspace is out of the scope.

### Known issues ###
1. key security - keys and passwords are not handled securely.  For the most
   part, this can be mitigated through access controls on the repo/containers
   and/or by replacing the secrets directory/library with a secret management
   volume or service.
2. scripts are a little inconsistent when it comes to passing variables vs
   using globals.  Shell scripts tend to be clunky in this regard, but adequate.
