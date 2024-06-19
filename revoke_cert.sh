#!/bin/bash -e
#Script by Sam Gleske
#Tue Jan 26 19:36:08 PST 2016
#Ubuntu 16.04.1 LTS
#Linux 4.4.0-51-generic x86_64
#GNU bash, version 4.3.46(1)-release (x86_64-pc-linux-gnu)
#Setup script has been adapted from instructions
#http://www.g-loaded.eu/2005/11/10/be-your-own-ca/
#https://docs.docker.com/engine/security/https/

CERT_DIR="${CERT_DIR:-./myCA}"
CERT_DIR="${CERT_DIR%/}"

function usage() {
cat <<EOF
$0 [OPTIONS] common-name

DESCRIPTION:
  Revoke a certificate based on common name.  This will generate a new
  certificate revocation list which can be used to deny revoked certificates
  from authenticating.

OPTIONS:
  -h,--help      show help
  --crl          Only generate a certificate revocation list.

EXAMPLES:
  Revoke a client certificate.

    $0 someclient

  Revoke a server certificate.

    $0 example.com
EOF
}

#common name
cname=""
do_revoke=true

while [ "$#" -gt '0' ]; do
  case $1 in
    -h|--help)
      usage 1>&2
      exit 1
      ;;
    --crl)
      do_revoke=false
      shift
      ;;
    *)
      if [ -z "${cname}" ]; then
        cname="$1"
      fi
      shift
      ;;
  esac
done

cd "${CERT_DIR}"
DATE="$(date +%Y-%m-%d-%s)"

if ${do_revoke}; then
  if [ -z "$cname" ];then
    echo "Error: missing common-name which is used to identify client." 1>&2
    usage 1>&2
    exit 1
  fi

  if [ ! -e "certs/${cname}.crt" ]; then
    echo "Certificate ${cname} does not exist.  Nothing to revoke." 1>&2
    exit 1
  fi

  echo "Revoking certificate for ${cname}." 1>&2

  openssl ca -config openssl.cnf -revoke "./certs/${cname}.crt"

  #make a backup directory to store revoked certificates and keys
  if [ ! -d "./backup" ];then
    mkdir "./backup"
  fi

  #back up the old certificate and key so it is no longer tracked for renewel but can still be referenced if necessary.
  echo "Backup old certificate and key." 1>&2
  mv "./certs/${cname}.crt" "./backup/${cname}_${DATE}.crt"
  mv "./private/${cname}.key" "./backup/${cname}_${DATE}.key"
fi

#generate the current certificate revokation list
echo "Generate a new certificate revocation list." 1>&2
openssl ca -config openssl.cnf -gencrl | openssl crl -text > ./crl.pem
cp "./crl.pem" "./crl/crl_${DATE}.pem"
echo "Finished revoking ${cname}.  The latest ./crl.pem has been generated and ./crl/crl_${DATE}.pem has been created." 1>&2
