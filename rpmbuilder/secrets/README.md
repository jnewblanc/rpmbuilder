# Secrets

Secrets pertaining to rpm signing are stored here.

### Contents ###
  - private key - Used for automated rpm signing
  - private key passphrase - Used as 2nd factor for rpm signing as part
      of automation
  - public key - Used for rpm signature verification - technically not a secret

### Secret Management ###
  - This directory can be replaced by an external volume or secret management
      service, depending on your security needs.

## WARNING ##
  - The keypairs included in this repo are public working examples and the keys
      should not be used or trusted.
