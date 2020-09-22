
load_key_passphrase() {
  log "INFO Loading Passphrase" | tee -a ${log}
  KEY_PASS=$(cat ${RBDIR}/secrets/pgp_key_passphrase)
}

import_keys() {
  log "INFO Importing Keys" | tee -a ${log}
  /usr/bin/gpg --import ${RBDIR}/secrets/${KEY_FILE_BASE}.pri
}
