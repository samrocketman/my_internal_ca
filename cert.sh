#!/bin/bash
#Created by Sam Gleske
#Thu Mar  6 23:44:35 EST 2014
#Ubuntu 13.10
#Linux 3.11.0-12-generic x86_64
#GNU bash, version 4.2.45(1)-release (x86_64-pc-linux-gnu)

#set the reqdir where certificate signing requests will be temporarily stored
reqdir="${reqdir:-/tmp}"
#remove trailing slash if any
reqdir="${reqdir%/}"

if ! [ -d "./certs" -a -d "./crl" -a -d "./newcerts" -a -d "./private" -a -f "./index.txt" -a -f "./openssl.my.cnf" -a -f "./serial" -a -f "./certs/myca.crt" -a -f "./private/myca.key" -a -f "./subject" ];then
  echo "cert.sh can only be run from a managed certicate authority directory." 1>&2
  exit 1
fi

if [ -z "${1}" ];then
  echo "Specify the common name of the certificate as an arg." 1>&2
  exit 1
fi

#do some precleanup if stuff exists
if [ -f "./private/${1}.key" ] && [ -f "./certs/${1}.crt" ];then
  echo "You must revoke the old ${1} certificate first!" 1>&2
  echo "openssl ca -config openssl.my.cnf -revoke \"./certs/${1}.crt\"" 1>&2
  echo 'After revoking you should backup the old certificate and key and then delete them from ./certs and ./private.' 1>&2
  exit 1
fi
rm -f "${reqdir}/${1}.csr" "./private/${1}.key" "./certs/${1}.crt"

#start the signing process

#grab the subject from the subject file
subj="$(head -n1 ./subject)${1}"

#generate the private key and certificate signing request
openssl req -out "${reqdir}/${1}.csr" -new -newkey rsa:2048 -nodes -subj "${subj}" -keyout "./private/${1}.key" -days 365

#sign the certificate
openssl ca -config openssl.my.cnf -policy policy_anything -out "./certs/${1}.crt" -infiles "${reqdir}/${1}.csr"

#final cleanup and security measures
rm -f "${reqdir}/${1}.csr"
chmod 644 "./certs/${1}.crt"
chmod 600 "./private/${1}.key"

#run some tests
echo "" 1>&2
echo "" 1>&2
echo "Certificate signing information..." 1>&2
openssl x509 -subject -issuer -enddate -noout -in "./certs/${1}.crt" 1>&2
echo "" 1>&2
echo "Verify certificate..." 1>&2
openssl verify -purpose sslserver -CAfile "./certs/myca.crt" "./certs/${1}.crt" 1>&2
