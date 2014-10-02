#!/bin/bash
#Sam Gleske
#Wed Oct  1 23:09:28 EDT 2014
#Fedora release 16 (Verne)
#Linux 3.6.11-4.fc16.x86_64 x86_64
#GNU bash, version 4.2.37(1)-release (x86_64-redhat-linux-gnu)
#DESCRIPTION
#  Generate a java keystore from generated certificates
#USAGE
#  ./keystore.sh yourserver.com

if [ -z "$1" ]; then
  echo "No server supplied." 1>&2
  echo "Usage: ./keystore.sh yourserver.com" 1>&2
  exit 1
fi

if ! [ -d "./certs" -a \
       -d "./crl" -a \
       -d "./newcerts" -a \
       -d "./private" -a \
       -f "./index.txt" -a \
       -f "./openssl.my.cnf" -a \
       -f "./serial" -a \
       -f "./certs/myca.crt" -a \
       -f "./private/myca.key" -a \
       -f "./subject" ]; then
  echo -n "keystore.sh can only be run from a managed certicate authority" 1>&2
  echo " directory." 1>&2
  exit 1
fi

if [ ! -f "certs/${1}.crt" -o ! -f "private/${1}.key" ]; then
  echo "Error: no certificate or private key found for ${1}." 1>&2
  exit 1
fi

if [ ! -d "./keystores" ]; then
  mkdir keystores
fi

if [ -f "./keystores/${1}.p12" -o -f "./keystores/${1}.keystore" ]; then
  echo "Keystore already exists." 1>&2
  exit 1
fi

#grab a password to use
pass="no"
confirmpass="match"
while [ ! "${pass}" = "${confirmpass}" ]; do
  echo -n "Type a password: "
  read -s pass
  echo ""
  echo -n "Verify password: "
  read -s confirmpass
  echo ""
  if [ ! "${pass}" = "${confirmpass}" ]; then
    echo "Passwords do not match.  Try again."
  fi
done

#aliases are stored by hostname
#first convert certificates to pkcs12
openssl pkcs12 -export \
  -out "keystores/${1}.p12" \
  -passout "pass:${pass}" \
  -inkey "private/${1}.key" \
  -in "certs/${1}.crt" \
  -certfile "certs/myca.crt" \
  -name "${1}"
#then convert pkcs12 to a java keystore
keytool -importkeystore \
  -srckeystore "keystores/${1}.p12" \
  -srcstorepass "${pass}" \
  -srcstoretype PKCS12 \
  -srcalias "${1}" \
  -deststoretype JKS \
  -destkeystore "keystores/${1}.keystore" \
  -deststorepass "${pass}" \
  -destalias "${1}"
