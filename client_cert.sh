#!/bin/bash -e
#Script by Sam Gleske
#Tue Jan 26 19:23:21 PST 2016
#Ubuntu 16.04.1 LTS
#Linux 4.4.0-51-generic x86_64
#GNU bash, version 4.3.46(1)-release (x86_64-pc-linux-gnu)
#Setup script has been adapted from instructions
#http://www.g-loaded.eu/2005/11/10/be-your-own-ca/
#https://docs.docker.com/engine/security/https/

CERT_DIR="${CERT_DIR:-./myCA}"
REQ_OPTS="${REQ_OPTS:--batch -nodes}"
CERT_DIR="${CERT_DIR%/}"

function usage() {
cat <<EOF
$0 [OPTIONS] common-name

DESCRIPTION:
  Generate SSL client certificates for a local CA.  This client certificate
  will be used to authenticate against a service supporting mutual TLS.

OPTIONS:
  -h,--help      show help

EXAMPLES:
  Generate a basic certificate for client auth.

    $0 someclient
EOF
}

#common name
client=""

while [ "$#" -gt '0' ]; do
  case $1 in
    -h|--help)
      usage 1>&2
      exit 1
      ;;
    *)
      if [ -z "${client}" ]; then
        client="$1"
      fi
      shift
      ;;
  esac
done

if [ -z "$client" ];then
  echo "Error: missing common-name which is used to identify client." 1>&2
  usage 1>&2
  exit 1
fi

#configuration for openssl
opensslcnf="basicConstraints=CA:FALSE
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer
extendedKeyUsage = clientAuth"

cd "${CERT_DIR}"

if [ -e "certs/${client}.crt" ]; then
  echo "Client certificate exists.  Must revoke existing certificate." 1>&2
  echo "revoke_cert.sh ${client}" 1>&2
  exit 1
fi

#create the key and CSR
openssl req -config openssl.cnf -new -newkey rsa:4096 -sha256 \
  -keyout "private/${client}.key" -subj "/CN=${client}" -text \
  -out "newcerts/${client}.csr" ${REQ_OPTS}

#sign the CSR
openssl ca -config openssl.cnf -extfile <( echo "${opensslcnf}" ) \
  -in "newcerts/${client}.csr" -out "certs/${client}.crt"

#change appropriate permissions
chmod 0600 "private/${client}.crt"
chmod 0644 "certs/${client}.crt"
