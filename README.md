# rpmbuilder

A framework and collection of scripts to facilitate building rpms in a docker
container.

## Basic workflow ##
1. Setup of rpmbuilder configs and keys
2. Setup workspace specific configs and version info in external repo
3. rpmbuilder stands up a docker container with the external repo mounted as a volume
4. rpmbuilder reads workspace specific configs and versions from the mounted repos
5. rpmbuilder creates a rpm staging area which contains the content and support scripts
6. rpmbuilder builds and signs the rpm
7. The generated rpm, scripts, and logs reside in the mounted repo for easy retrieval

### Installation ###
1. Install docker
2. Clone rpmbuilder repo
3. run docker to build the image
  ```
  docker build -t rpmbuilder .
  ```

### Setup ###
1. Set up docker-compose
   - Set volume in docker compose.  Volume is your external repo which contains
        the content, configs, and versions needed for rpm building.
   - Set WSROOT environment variable.  The value of WSROOT should be the full
        path to the workspace that contains the programs and spec files.  It
        corresponds with the volume set up above.
2. Create the version and packaging files within the external repo (WSROOT/.buildenv)
   - Use the files at rpmbuilder/.buildenv/* as a template.  Be sure to update
     them with details pertaining to your repo and desired rpm(s).
   - See rpmbuilder/.buildenv/README.md for details
5. Update rpmbuild globals
     Update rpmbuilder/globals.sh as needed
4. Set up secrets
   - Replace keys/creds in rpmbuilder/secrets for package signing, or turn off
     package signing in rpmbuilder/globals.sh

### Execution ###
1. Use docker-compose to stand up the docker container and generate the rpm
  ```
  docker-compose up
  ```
  - The resulting rpm(s) will be created in ${WSROOT}/.buildenv/pkgdir/RPMS
  - The resulting log resides at ${WSROOT}/.buildenv/pkgdir/rpm.log
  - Scripts/Wrappers for debugging are available in ${WSROOT}/.buildenv/pkgdir

### Out of scope - What rpmbuilder doesn't do ###
1. rpmbuilder does not build/compile binaries of the source repo.  It is
   expected that any build/compilation occurs before rpmbuilder as part of
   your CI/CD platform.  Technically, rpm is able to build/compile as part of
   package generation, but you should skip this for all but the simplest of
   cases.
2. rpmbuilder does not auto increment the version number in the source repo's
   version.sh file.  Bumping the version is the responsibility of the builds.
   None-the-less, some helper functions are included in version_lib.sh.
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
   using globals.  Shell scripts tend to be clunky in this regard, but adequate
   none-the-less.

### Additional info ###
1. By default, and for testing and examples, rpmbuilder packages its own
   toolset into an rpm.
