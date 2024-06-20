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
REQ_OPTS="${REQ_OPTS:--batch}"
CERT_DIR="${CERT_DIR%/}"

function usage() {
cat <<EOF
$0 [OPTIONS] common-name

DESCRIPTION:
  Generate SSL client certificates for a local CA.  This client certificate
  will be used to authenticate against a service supporting mutual TLS.

OPTIONS:
  -h,--help      show help

  -p,--prompt-password
                 User prompt to encrypt the private key with a password.

EXAMPLES:
  Generate a basic certificate for client auth.

    $0 someclient
EOF
}

function set_password() {
  local pass1=a
  local pass2=b
  while [ ! "${pass1:-}" = "${pass2:-}" ]; do
    read -ersp "Type a password: " pass1
    read -ersp "Confirm password: " pass2
    if [ ! "$pass1" = "$pass2" ] || [ "x${pass1:-}" = x ]; then
      echo 'Passwords do not match; try again. (Or press ctrl+c to cancel)' >&2
    else
      break
    fi
  done
  client_password="$pass1"
}

#common name
client=""
while [ "$#" -gt '0' ]; do
  case $1 in
    -h|--help)
      usage 1>&2
      exit 1
      ;;
    -p|--password-prompt)
      set_password
      shift
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
keyUsage=critical,nonRepudiation,digitalSignature,keyEncipherment
extendedKeyUsage=critical,clientAuth"

cd "${CERT_DIR}"

if [ -e "certs/${client}.crt" ]; then
  echo "Client certificate exists.  Must revoke existing certificate." 1>&2
  echo "revoke_cert.sh ${client}" 1>&2
  exit 1
fi

#create the password or plain text private key?
keygen_args=( -newkey rsa:4096 )
if [ ! "x${client_password:-}" = x ]; then
  keygen_args+=( -passout env:client_password )
  export client_password
else
  keygen_args+=( -nodes )
fi

# generate private key and CSR
openssl req -config openssl.cnf -new -sha256 "${keygen_args[@]}" \
  -keyout "private/${client}.key" -subj "/CN=${client}" -text \
  -out "newcerts/${client}.csr" ${REQ_OPTS}

#sign the CSR
openssl ca -config openssl.cnf -extfile <( echo "${opensslcnf}" ) \
  -in "newcerts/${client}.csr" -out "certs/${client}.crt" -batch

#change appropriate permissions
chmod 0600 "private/${client}.key"
chmod 0644 "certs/${client}.crt"
