#!/bin/bash -e
#Script by Sam Gleske
#Thu Mar  6 23:14:29 EST 2014
#Ubuntu 16.04.1 LTS
#Linux 4.4.0-51-generic x86_64
#GNU bash, version 4.3.46(1)-release (x86_64-pc-linux-gnu)
#Setup script has been adapted from instructions
#http://www.g-loaded.eu/2005/11/10/be-your-own-ca/
#https://docs.docker.com/engine/security/https/

#DESCRIPTION
#  Generate a certificate authority for private use.  This can be used on
#  personal servers or for a docker server.  This CA will be used to sign both
#  client and server sertificates for mutual authentication via TLS.

CERT_DIR="${CERT_DIR:-./myCA}"
REQ_OPTS="${REQ_OPTS:--batch -nodes}"
CERT_DIR="${CERT_DIR%/}"

if [ ! -d "${CERT_DIR}" ]; then
  mkdir -p "${CERT_DIR}"
fi

#don't overwrite our existing CA
if [ -e "${CERT_DIR}/certs/myca.crt" ]; then
  echo "Error: Certificate authority already exists." 1>&2
  echo "CERT_DIR=${CERT_DIR}" 1>&2
  exit 1
fi


#openssl.cnf for generating a certificate authority
opensslcnf="
[ req ]
distinguished_name = req_distinguished_name
x509_extensions = v3_ca
[ req_distinguished_name ]
countryName =
countryName_default = US
stateOrProvinceName =
stateOrProvinceName_default = California
localityName =
localityName_default = Garden Grove
organizationName =
organizationName_default = Gleske Internal
organizationalUnitName =
organizationalUnitName_default = Systems
commonName =
commonName_default = Local Certificate Authority
emailAddress =
#emailAddress_default = none@example.com
[ v3_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = CA:true
"

if [ ! -e "${CERT_DIR}/openssl.cnf" ]; then
  cp openssl.cnf "${CERT_DIR}/"
  chmod 0600 "${CERT_DIR}/openssl.cnf"
fi

cd "${CERT_DIR}"

#Prepare the certificate authority for git
for x in certs crl private newcerts;do
  if [ ! -d "${x}" ];then
    mkdir -p "${x}"
    touch "${x}/.gitignore"
  fi
done
chmod 0700 private
echo -e '*\n!.gitignore' > ./newcerts/.gitignore

#Generate a CA good for 20 years.
#If you make it longer and you could run into compatibility issues.
openssl req -config <( echo "${opensslcnf}" ) -new -newkey rsa:4096 -sha256 \
  -keyout private/myca.key -x509 -days 7300 -text \
  -out certs/myca.crt ${REQ_OPTS} "$@"

#change appropriate permissions
chmod 0600 private/myca.key
chmod 0644 certs/myca.crt

#configure some additional files
touch index.txt
echo '01' > serial
