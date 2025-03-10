# rpm_lib.sh
#
# functions to help us with the creation of rpms
#

# assemble_rpm_specfile <source_file> <out_file> <log>
assemble_rpm_specfile()
{

  local SOURCE_FILE=$1
  local OUT_FILE=$2
  local log=$3

  log "INFO Assembling rpm specfile at ${OUT_FILE}" | tee -a ${log}

  if [ "${log}" = "" ]; then
    log "ERROR log variable is not set - Aborting..."
    exit 1
  fi

  # PKG_NAME typically comes from the pkg (version) file
  if [ "${PKG_NAME}" = "" ]; then
    log "ERROR PKG_NAME is not set - Aborting..." | tee -a ${log}
    exit 1
  fi

  if [ "${WSROOT}" = "" ]; then
    log "ERROR WSROOT variable is not set - Aborting..." | tee -a ${log}
    exit 1
  fi

  SERIALDATE=$(date "+%Y%m%d%H%M")

  if [ "${LICENSE}" = "" ]; then
    LICENSE=LICENSE
  fi
  if [ "${PKG_DATE}" = "" ]; then
    PKG_DATE=$(date "+%a %b %d %Y")
  fi
  if [ "${VENDOR_NAME}" = "" ]; then
    VENDOR_NAME=VENDOR_NAME
  fi
  if [ "${VENDOR_EMAIL}" = "" ]; then
    VENDOR_EMAIL=VENDOR_EMAIL
  fi
  if [ "${VENDOR_DOMAIN}" = "" ]; then
    VENDOR_DOMAIN=VENDOR_DOMAIN
  fi

  # Use the default
  GREP_SRC_NAME=`echo ${SOURCE_FILE} | grep "rpm.spec"`
  if [ "${GREP_SRC_NAME}" = "" ]; then
    # If we are using a custom specfile name, then use this name for pkg
    local NAME_OF_THE_PKG=`basename ${SOURCE_FILE} | sed -e "s/.spec//"`
  else
    # Default to PKG_NAME
    local NAME_OF_THE_PKG="${PKG_NAME}"
  fi

  # Perform substitution
  sed -e "s#__WSROOT__#${WSROOT}#g" \
      -e "s#__PLAT__#${PLAT}#g" \
      -e "s#__ARCH__#${ARCHITECTURE}#g" \
      -e "s#__PKG_NAME__#${NAME_OF_THE_PKG}#g" \
      -e "s#__PKG_VERSION__#${PKG_VERSION}#g" \
      -e "s#__PKG_RELEASE__#${PKG_RELEASE}#g" \
      -e "s#__LICENSE__#${LICENSE}#g" \
      -e "s#__PKG_DATE__#${PKG_DATE}#g" \
      -e "s#__VENDOR_NAME__#${VENDOR_NAME}#g" \
      -e "s#__VENDOR_EMAIL__#${VENDOR_EMAIL}#g" \
      -e "s#__VENDOR_DOMAIN__#${VENDOR_DOMAIN}#g" \
      -e "s#__SERIALDATE__#${SERIALDATE}#g" \
      $SOURCE_FILE > $OUT_FILE

  if [ -f "${OUT_FILE}" ]; then
    log "INFO Done assembling specfile at ${OUT_FILE}" | tee -a ${log}
  else
    log "ERROR Could not assemble rpm specfile at ${OUT_FILE}" | tee -a ${log}
    exit 1
  fi

  log "INFO Running rpmlint on ${OUT_FILE}" | tee -a ${log}
  ${PKGDIR}/rpmlint "${OUT_FILE}" | tee -a ${log}
  log "INFO Done with rpmlint on ${OUT_FILE}" | tee -a ${log}
} # end assemble_rpm_specfile

# Create a set of wrappers and scripts to operate on our local rpm repo
create_wrappers() {
  local PKGDIR=$1
  local KEYNAME=$2
  local KEYPATH=$3
  local KEYPASS=$4
  local log=$5

  log "INFO Generating wrappers" | tee -a ${log}

  #
  # Create a rpm wrapper that contains environment for workspace
  #
  if [ ! -f "${PKGDIR}/rpm" ]; then
    mkdir -p ${PKGDIR}
    echo "#!/bin/sh" >> ${PKGDIR}/rpm
    echo "#" >> ${PKGDIR}/rpm
    echo "# rpm (wrapper) - auto generated" >> ${PKGDIR}/rpm
    echo "#" >> ${PKGDIR}/rpm
    echo "HOME=${PKGDIR}" >> ${PKGDIR}/rpm
    echo "/bin/rpm -vv \"\$@\"" >> ${PKGDIR}/rpm
    echo "exit \$?" >> ${PKGDIR}/rpm
    chmod a+rx ${PKGDIR}/rpm
  fi
  if [ ! -f "${PKGDIR}/rpm" ]; then
    log "ERROR could not create ${PKGDIR}/rpm" | tee -a ${log}
  fi

  #
  # Create a rpmbuild wrapper that contains environment for workspace
  #
  if [ ! -f "${PKGDIR}/rpmbuild" ]; then
    mkdir -p ${PKGDIR}
    echo "#!/bin/sh" >> ${PKGDIR}/rpmbuild
    echo "#" >> ${PKGDIR}/rpmbuild
    echo "# rpmbuild (wrapper) - auto generated" >> ${PKGDIR}/rpmbuild
    echo "#" >> ${PKGDIR}/rpmbuild
    echo "HOME=${PKGDIR}" >> ${PKGDIR}/rpmbuild
    echo "/usr/bin/rpmbuild -vv \"\$@\"" >> ${PKGDIR}/rpmbuild
    echo "exit \$?" >> ${PKGDIR}/rpmbuild
    chmod a+rx ${PKGDIR}/rpmbuild
  fi

  #
  # Create a rpmlint wrapper that contains environment for workspace
  #
  if [ ! -f "${PKGDIR}/rpmlint" ]; then
    if [ ! -f "/bin/rpmlint" ]; then
      log "ERROR Can't find rpmlint at /bin/rpmlint" | tee -a ${log}
    fi
    mkdir -p ${PKGDIR}
    echo "#!/bin/sh" >> ${PKGDIR}/rpmlint
    echo "#" >> ${PKGDIR}/rpmlint
    echo "# rpmlint (wrapper) - auto generated" >> ${PKGDIR}/rpmlint
    echo "#" >> ${PKGDIR}/rpmlint
    echo "HOME=${PKGDIR}" >> ${PKGDIR}/rpmlint
    echo "/bin/rpmlint -v \"\$@\"" >> ${PKGDIR}/rpmlint
    echo "rpmlint returned exit code \$?" >> ${PKGDIR}/rpmlint
    echo "exit 0" >> ${PKGDIR}/rpmlint
    chmod a+rx ${PKGDIR}/rpmlint
  fi
  if [ ! -f "${PKGDIR}/rpmlint" ]; then
    log "ERROR could not create ${PKGDIR}/rpmlint" | tee -a ${log}
  fi

  #
  # Create a rpm macro file so that RPM knows where it's dirs are
  #
  if [ ! -f "${PKGDIR}/.rpmmacros" ]; then

    echo "#" >> ${PKGDIR}/.rpmmacros
    echo "# .rpmmacro file" >> ${PKGDIR}/.rpmmacros
    echo "# Automatically generated by $0" >> ${PKGDIR}/.rpmmacros
    echo "#" >> ${PKGDIR}/.rpmmacros
    echo "" >> ${PKGDIR}/.rpmmacros
    echo "%_topdir ${PKGDIR}" >> ${PKGDIR}/.rpmmacros
    echo "%_dbpath ${PKGDIR}/DB" >> ${PKGDIR}/.rpmmacros
    echo "%_tmppath ${PKGDIR}/TMP" >> ${PKGDIR}/.rpmmacros
    echo "%_rpmlock_path ${PKGDIR}/DB/__db.000" >> ${PKGDIR}/.rpmmacros
    echo "%_tmppath ${PKGDIR}/TMP" >> ${PKGDIR}/.rpmmacros
    echo "" >> ${PKGDIR}/.rpmmacros
    echo "# Needed for digital signatures" >> ${PKGDIR}/.rpmmacros
    echo "%_signature gpg" >> ${PKGDIR}/.rpmmacros
    echo "%_gpg_name ${KEYNAME}" >> ${PKGDIR}/.rpmmacros
    echo "%_gpg_path ${KEYPATH}" >> ${PKGDIR}/.rpmmacros
    echo "# Turn off unpackaged errors" >> ${PKGDIR}/.rpmmacros
    echo "%_unpackaged_files_terminate_build   0" >> ${PKGDIR}/.rpmmacros
    echo "" >> ${PKGDIR}/.rpmmacros
  fi

  #
  # Create a script to generate the package
  #
  if [ ! -f "${PKGDIR}/gen_rpm" ]; then
    echo "#!/bin/bash" >> ${PKGDIR}/gen_rpm
    echo "#" >> ${PKGDIR}/gen_rpm
    echo "# Automatically generated by $0" >> ${PKGDIR}/gen_rpm
    echo "#" >> ${PKGDIR}/gen_rpm
    echo "" >> ${PKGDIR}/gen_rpm
    echo "${PKGDIR}/rpmbuild -ba \$1" >> ${PKGDIR}/gen_rpm
    chmod a+rx ${PKGDIR}/gen_rpm
  fi


  #
  # Create an expect script to generate a signed package
  #
  if [ ! -f "${PKGDIR}/sign_rpm" ]; then
    if [ ! -f "/usr/bin/expect" ]; then
      log "ERROR Can't find expect at /usr/bin/expect" | tee -a ${log}
    fi
    echo "#!/usr/bin/expect -f" >> ${PKGDIR}/sign_rpm
    echo "#" >> ${PKGDIR}/sign_rpm
    echo "# Automatically generated by $0" >> ${PKGDIR}/sign_rpm
    echo "#" >> ${PKGDIR}/sign_rpm
    echo "" >> ${PKGDIR}/sign_rpm
    echo "set qpass \"${KEYPASS}\"" >> ${PKGDIR}/sign_rpm
    echo "" >> ${PKGDIR}/sign_rpm
    echo "spawn ${PKGDIR}/rpm --resign \$argv" >> ${PKGDIR}/sign_rpm
    echo "expect {" >> ${PKGDIR}/sign_rpm
    echo "  \"Enter pass phrase: \" {" >> ${PKGDIR}/sign_rpm
    echo "    send \"\$qpass\\r\";" >> ${PKGDIR}/sign_rpm
    echo "    set timeout -1;" >> ${PKGDIR}/sign_rpm
    echo "    exp_continue" >> ${PKGDIR}/sign_rpm
    echo "  }" >> ${PKGDIR}/sign_rpm
    echo "  timeout {puts \"Expect Script Timed Out\\n\"; exit 1}" \
         >> ${PKGDIR}/sign_rpm
    echo "}" >> ${PKGDIR}/sign_rpm
    echo "" >> ${PKGDIR}/sign_rpm


    # add expect error checking to pass on the rpm return value
    echo "set status [wait]" >> ${PKGDIR}/sign_rpm
    echo "" >> ${PKGDIR}/sign_rpm
    echo "# check if it is an OS error or a return code from our command" \
         >> ${PKGDIR}/sign_rpm
    echo "#   index 2 should be -1 for OS erro, 0 for command return code" \
         >> ${PKGDIR}/sign_rpm
    echo "if {[lindex \$status 2] == 0} {" >> ${PKGDIR}/sign_rpm
    echo "  # it is a return code, get the actual return code" \
         >> ${PKGDIR}/sign_rpm
    echo "  set command_result [lindex \$status 3]" \
         >> ${PKGDIR}/sign_rpm
    echo "  if {\$command_result == 0} {" >> ${PKGDIR}/sign_rpm
    echo "    puts \"rpm command succeeded\"" >> ${PKGDIR}/sign_rpm
    echo "    exit 0" >> ${PKGDIR}/sign_rpm
    echo "  } else {" >> ${PKGDIR}/sign_rpm
    echo "    puts \"error: rpm command failed\"" >> ${PKGDIR}/sign_rpm
    echo "    exit 1" >> ${PKGDIR}/sign_rpm
    echo "  }" >> ${PKGDIR}/sign_rpm
    echo "} else {" >> ${PKGDIR}/sign_rpm
    echo "  puts \"error: rpm command failed, OS error\"" \
         >> ${PKGDIR}/sign_rpm
    echo "}" >> ${PKGDIR}/sign_rpm
    echo "" >> ${PKGDIR}/sign_rpm

    chmod a+rx ${PKGDIR}/sign_rpm
  fi
} #end create_wrappers


#
# Create rpm staging area that is local to the workspace.  Populate it with
# generic resources
#
create_staging_area() {
  local PKGDIR=$1
  local log=$2

  log "INFO Creating staging area at ${PKGDIR}" | tee -a ${log}

  if [ ! -d "${PKGDIR}/RPMS" ]; then
    mkdir -p ${PKGDIR}/RPMS
    mkdir -p ${PKGDIR}/SOURCES
    mkdir -p ${PKGDIR}/SPECS
    mkdir -p ${PKGDIR}/SRPMS
    mkdir -p ${PKGDIR}/TMP
    mkdir -p ${PKGDIR}/BUILD
    mkdir -p ${PKGDIR}/DB

    ${PKGDIR}/rpm --initdb >> ${log} 2>&1
    if [ "$?" != "0" ]; then
      log "ERROR Could not initialize the rpm DB at ${PKGDIR}" | tee -a ${log}
    fi
  fi


  if [ -d "${PKGDIR}/SOURCES" ]; then
    if [ ! -d ${PKGDIR}/SOURCES/no-source-provide ]; then
      touch ${PKGDIR}/SOURCES/no-source-provide
    fi
    touch ${PKGDIR}/SOURCES/icon.xpm
    if [ ! -d ${PKGDIR}/SOURCES/logo.gif ]; then
      if [ -f "${PKGDIR}/src/logo.gif" ]; then
        cp ${PKGDIR}/src/logo.gif ${PKGDIR}/SOURCES
      fi
    fi
    if [ "${RPMSOURCES}" != "" ]; then
      log "INFO Copying RPMSOURCES to ${PKGDIR}/SOURCES" >> ${log}
      for filename in ${RPMSOURCES} ; do
        if [ -f "${WSROOT}/$filename" ]; then
          echo "cp ${WSROOT}/$filename ${PKGDIR}/SOURCES" | tee -a ${log}
          cp ${WSROOT}/$filename ${PKGDIR}/SOURCES
        elif [ -f "$filename" ]; then
          echo "cp $filename ${PKGDIR}/SOURCES" | tee -a ${log}
          cp $filename ${PKGDIR}/SOURCES
        else
          log "ERROR Can't find RPMSOURCES file: $filename" | tee -a ${log}
        fi
      done
    fi
  fi
} # end create_staging_area

# create rpm package
#
# create_rpm <spec_template> <pkgdir> <log>
create_rpm() {
    local SPEC_TEMPLATE=$1
    local PKGDIR=$2
    local log=$3

    if [ "${log}" = "" ]; then
      log "ERROR log variable is not set - Aborting..."
      exit 1
    fi

    if [ "${PKGDIR}" = "" ]; then
      PKGDIR=${WSROOT}/pkg
    fi

    local SPECNAME=`basename ${SPEC_TEMPLATE} | sed -e "s/.spec//"`
    local DESTSPEC="${PKGDIR}/SPECS/${SPECNAME}.spec"

    if [ -f "${DESTSPEC}" ]; then
      log "ERROR rpm specfile already exists at destination ${DESTSPEC}" | tee -a ${log}
      log "ERROR Use clean workspace or remove ${PKGDIR}" | tee -a ${log}
      exit 1
    fi
    mkdir -p "${PKGDIR}/SPECS"
    if [ ! -f "${SPEC_TEMPLATE}" ]; then
      log "ERROR rpm specfile template doesn't exist at ${SPEC_TEMPLATE}" | tee -a ${log}
      exit 1
    fi

    # Load keys and set KEY_PASS
    import_keys
    load_key_passphrase
    if [ "${DEBUG}" != "False" ]; then
      /usr/bin/gpg --list-keys | tee -a ${log}
    fi

    create_wrappers "${PKGDIR}" "${KEY_NAME}" "${KEY_PATH}" "${KEY_PASS}" "${log}"

    assemble_rpm_specfile "${SPEC_TEMPLATE}" "${DESTSPEC}" "${log}"

    create_staging_area "${PKGDIR}" "${log}"

    file_rpm=${WSROOT}/${PKG_NAME}_${SPECNAME}-${PKG_VERSION}-${PKG_RELEASE}.rpm

    #
    # Build and sign rpm (via our rpm wrapper) to generate package(s)
    #
    log "INFO Creating Rpm package File for $PKG_NAME [$file_rpm]" >> ${log}
    PKG_DESC="$PKG_NAME V$PKG_VERSION R$PKG_RELEASE"
    log "INFO ${PKGDIR}/gen_rpm ${PKGDIR}/SPECS/${SPECNAME}.spec" >> ${log}
    ${PKGDIR}/gen_rpm ${PKGDIR}/SPECS/${SPECNAME}.spec >> ${log} 2>&1

    if [ ! -f "${KEY_PATH}/secring.gpg" ]; then
      log "WARNING Can't find ${KEY_PATH}/.gnupg/secring.gpg" >> ${log}
      log "WARNING gpg KeyRing missing - Package Signing skipped" | tee -a ${log}
      SIGNRPM="False"
    fi

    for RPM_FILENAME in `find ${PKGDIR}/RPMS -name \*.rpm -print`; do
      log "INFO rpm created at ${RPM_FILENAME}" >> ${log}
      if [ "${SIGNRPM}" == "True" ]; then
        log "INFO signing ${RPM_FILENAME}" >> ${log}
        ${PKGDIR}/sign_rpm ${RPM_FILENAME} >> ${log} 2>&1
        if [ "$?" = "0" ]; then
          log "INFO Package Signed [$PKG_DESC]" | tee -a ${log}
        else
          log "INFO Error Signing Package [$PKG_DESC]" | tee -a ${log}
          return 4
        fi
      fi
    done
}
