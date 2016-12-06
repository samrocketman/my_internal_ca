#!/bin/bash
#Sam Gleske
#Wed Oct  1 23:09:28 EDT 2014
#Ubuntu 16.04.1 LTS
#Linux 4.4.0-51-generic x86_64
#GNU bash, version 4.3.46(1)-release (x86_64-pc-linux-gnu)
#DESCRIPTION
#  Generate a java keystore from generated certificates
#USAGE
#  ./keystore.sh yourserver.com

CERT_DIR="${CERT_DIR:-./myCA}"
CERT_DIR="${CERT_DIR%/}"

function usage() {
cat <<EOF
$0 [OPTIONS] common-name

DESCRIPTION:
  Generate a Java keystore from SSL X.509 certificates for a local CA.  Where
  the common-name is typically a domain name.

OPTIONS:
  -h,--help      show help
  --changeit     Use the default changeit password as the keystore pass.  This
                 skips the password prompt.

EXAMPLES:
  Generate a Java keystore from X.509 certificates.

    $0 example.com
EOF
}

#common name
server=""
use_changeit_pass=false

while [ "$#" -gt '0' ]; do
  case $1 in
    -h|--help)
      usage 1>&2
      exit 1
      ;;
    --changeit)
      use_changeit_pass=true
      shift
      ;;
    *)
      if [ -z "${server}" ]; then
        server="$1"
      fi
      shift
      ;;
  esac
done

if [ -z "${server}" ]; then
  echo "No common-name supplied." 1>&2
  usage 1>&2
  exit 1
fi

cd "${CERT_DIR}"

if [ ! -f "certs/${server}.crt" -o ! -f "private/${server}.key" ]; then
  echo "Error: no certificate or private key found for ${server}." 1>&2
  echo "CERT_DIR=${CERT_DIR}" 1>&2
  exit 1
fi

if [ ! -d "./keystores" ]; then
  mkdir keystores
fi
if [ ! -r "./keystores/.gitignore" ]; then
cat > ./keystores/.gitignore <<EOF
*.p12
EOF
fi

if [ -f "./keystores/${server}.p12" -o -f "./keystores/${server}.keystore" ]; then
  echo "Keystore already exists." 1>&2
  echo "CERT_DIR=${CERT_DIR}" 1>&2
  exit 1
fi

#grab a password to use
pass="changeit"

if ! ${use_changeit_pass}; then
  confirmpass="match"
  while [ ! "${pass}" = "${confirmpass}" ]; do
    echo -n "Type a password: "
    read -s pass
    echo ""
    echo -n "Verify password: "
    read -s confirmpass
    echo ""
    if [ ! "${pass}" = "${confirmpass}" ]; then
      echo "Passwords do not match.  Try again." 1>&2
    fi
  done
fi

#aliases are stored by hostname
#first convert certificates to pkcs12
openssl pkcs12 -export \
  -out "keystores/${server}.p12" \
  -passout "pass:${pass}" \
  -inkey "private/${server}.key" \
  -in "certs/${server}.crt" \
  -certfile "certs/myca.crt" \
  -name "${server}"
#then convert pkcs12 to a java keystore
keytool -importkeystore \
  -srckeystore "keystores/${server}.p12" \
  -srcstorepass "${pass}" \
  -srcstoretype PKCS12 \
  -srcalias "${server}" \
  -deststoretype JKS \
  -destkeystore "keystores/${server}.keystore" \
  -deststorepass "${pass}" \
  -destalias "${server}"
