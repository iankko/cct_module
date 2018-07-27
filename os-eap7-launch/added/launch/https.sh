# only processes a single environment as the placeholder is not preserved

source $JBOSS_HOME/bin/launch/logging.sh

function prepareEnv() {
  unset HTTPS_NAME
  unset HTTPS_PASSWORD
  unset HTTPS_KEYSTORE_DIR
  unset HTTPS_KEYSTORE
  unset HTTPS_KEYSTORE_TYPE
}

function configure() {
  configure_https
}

function configureEnv() {
  configure
}

function configure_https() {
  local ssl="<!-- No SSL configuration discovered -->"
  local https_connector="<!-- No HTTPS configuration discovered -->"

  if [ "${CONFIGURE_ELYTRON_SSL}" == "true" ]; then
    echo "Using Elytron for SSL configuration."
    return 
  fi

  if [ -n "${HTTPS_PASSWORD}" -a -n "${HTTPS_KEYSTORE_DIR}" -a -n "${HTTPS_KEYSTORE}" ]; then

    if [ -n "$HTTPS_KEYSTORE_TYPE" ]; then
      keystore_provider="provider=\"${HTTPS_KEYSTORE_TYPE}\""
    fi
    ssl="<server-identities>\n\
                    <ssl>\n\
                        <keystore ${keystore_provider} path=\"${HTTPS_KEYSTORE_DIR}/${HTTPS_KEYSTORE}\" keystore-password=\"${HTTPS_PASSWORD}\"/>\n\
                    </ssl>\n\
                </server-identities>"

    local enabled_protocols="enabled-protocols=\"${HTTPS_PROTOCOLS:-[\"TLSv1.2\",\"TLSv1.3\"]}\""
    if [ -n "${HTTPS_CIPHER_SUITES}" ]; then
      enabled_cipher_suites="enabled-cipher-suites=\"${HTTPS_CIPHER_SUITES}\""
    fi

    https_connector="<https-listener name=\"https\" socket-binding=\"https\" security-realm=\"ApplicationRealm\" proxy-address-forwarding=\"true\" $enabled_protocols $enabled_cipher_suites />"

  elif [ -n "${HTTPS_PASSWORD}" -o -n "${HTTPS_KEYSTORE_DIR}" -o -n "${HTTPS_KEYSTORE}" ]; then
    log_warning "Partial HTTPS configuration, the https connector WILL NOT be configured."
  fi

  sed -i "s|<!-- ##SSL## -->|${ssl}|" $CONFIG_FILE
  sed -i "s|<!-- ##HTTPS_CONNECTOR## -->|${https_connector}|" $CONFIG_FILE
}
