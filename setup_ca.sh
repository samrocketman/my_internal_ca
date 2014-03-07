#!/bin/bash
#Script by Sam Gleske
#Thu Mar  6 23:14:29 EST 2014
#Ubuntu 13.10
#Linux 3.11.0-12-generic x86_64
#GNU bash, version 4.2.45(1)-release (x86_64-pc-linux-gnu)
#Setup script has been adapted from instructions
#http://www.g-loaded.eu/2005/11/10/be-your-own-ca/

rootdir="${rootdir:-.}"
#remove trailing slash if any
rootdir="${rootdir%/}"
#test to make sure that the rootdir actually exists.
if [ ! -d "${rootdir}" ];then
  echo "${rootdir} does not exist or is not a directory!" 1>&2
  exit 1
elif [ -d "${rootdir}/myCA" ];then
  echo "CA already created at ${rootdir}/myCA.  Create it elsewhere or choose a new path." 1>&2
  exit 1
fi

######################################################################
#myCA is our Certificate Authority’s directory.
#myCA/certs directory is where our server certificates will be placed.
#myCA/newcerts directory is where openssl puts the created
#   certificates in PEM (unencrypted) format and in the form 
#   cert_serial_number.pem (eg 07.pem). Openssl needs this directory, 
#   so we create it.
#myCA/crl is where our certificate revokation list is placed.
#myCA/private is the directory where our private keys are placed. Be 
#   sure that you set restrictive permissions to all your private keys 
#   so that they can be read only by root, or the user with whose 
#   priviledges a server runs. If anyone steals your private keys, 
#   then things get really bad.
mkdir -m 0755 -p "${rootdir}/myCA/private" "${rootdir}/myCA/certs" "${rootdir}/myCA/newcerts" "${rootdir}/myCA/crl"

######################################################################
#We are going to copy the default openssl configuration file 
#   (openssl.cnf) to our CA’s directory.
#On Ubuntu it is /etc/ssl; on Fedora it is /etc/pki/tls
#This script assumes Ubuntu.
cp /etc/ssl/openssl.cnf "${rootdir}/myCA/openssl.my.cnf"

######################################################################
#This file does not need to be world readable, so we change its 
#attributes.
chmod 0600 "${rootdir}/myCA/openssl.my.cnf"

######################################################################
#We also need to create two other files. This file serves as a 
#database for openssl.
touch "${rootdir}/myCA/index.txt"

######################################################################
#The following file contains the next certificate’s serial number. 
#Since we have not created any certificates yet, we set it to "01".
echo '01' > "${rootdir}/myCA/serial"

######################################################################
#Things to remember about SSL file extensions
#  KEY – Private key (Restrictive permissions should be set on this)
#  CSR – Certificate Request (This will be signed by our CA in order 
#        to create the server certificates. Afterwards it is not 
#        needed and can be deleted)
#  CRT – Certificate (This can be publicly distributed)
#  PEM – We will use this extension for files that contain both the 
#        Key and the server Certificate (Some servers need this). 
#        Permissions should be restrictive on these files.
#  CRL – Certificate Revokation List (This can be publicly 
#        distributed)
#Create the CA Certificate and Key
cd "${rootdir}/myCA/"

######################################################################
#Create a self-signed certificate with the default CA extensions which 
#is valid for 5 years. You will be prompted for a passphrase for your 
#CA's private key. Be sure that you set a strong passphrase. Then you 
#will need to provide some info about your CA. Fill in whatever you 
#like.
openssl req -config openssl.my.cnf -new -x509 -extensions v3_ca -keyout "./private/myca.key" -out "./certs/myca.crt" -days 1825

######################################################################
#Two files are created:
#certs/myca.crt   – This is your CA's certificate and can be publicly 
#                   available and of course world readable.
#private/myca.key – This is your CA’s private key. Although it is 
#                   protected with a passphrase you should restrict 
#                   access to it, so that only root can read it:
chmod 0400 "./private/myca.key"

######################################################################
#Copy the sample subject
