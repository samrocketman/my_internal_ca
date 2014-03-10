#!/bin/bash
#Created by Sam Gleske
#Thu Mar  6 23:44:35 EST 2014
#Ubuntu 13.10
#Linux 3.11.0-12-generic x86_64
#GNU bash, version 4.2.45(1)-release (x86_64-pc-linux-gnu)

#exit upon first error
set -e

PROGNAME="${0##*/}"
PROGVERSION="0.1.1"

#Certificate generation defaults
strength="2048"
length="365"

#program default variables
create=false
crl=false
renew=false
revoke=false
force=false

#
# ARGUMENT HANDLING
#

#Short options are one letter.  If an argument follows a short opt then put a colon (:) after it
SHORTOPTS="hvc:r:x:"
LONGOPTS="help,version,create:,crl,renew:,revoke:,force"
usage()
{
  cat <<EOF
######################################################################
${PROGNAME} ${PROGVERSION} - MIT License by Sam Gleske

USAGE:
  ${PROGNAME} [--create|--renew|--revoke] CNAME
  ${PROGNAME} [-c|-r|-x] CNAME

DESCRIPTION:
  This program generates signed certificates in a self managed CA.  It
  may also renew or revoke certificates.

  -h,--help          Show help
  -v,--version       Show program version
  -c,--create CNAME  Create a key and CSR based on CNAME common name.
  --crl              Generate a new Certificate Revocation List.
  -r,--renew CNAME   Renew a key and generate CSR based on CNAME 
                     common name.
  -x,--revoke CNAME  Renew a key and generate CSR based on CNAME 
                     common name.
  --force            Attempt to force certificate --create.

  This is part of the my_internal_ca project.
  https://github.com/sag47/my_internal_ca


EOF
}
ARGS=$(getopt -s bash --options "${SHORTOPTS}" --longoptions "${LONGOPTS}" --name "${PROGNAME}" -- "$@")
eval set -- "$ARGS"
while true; do
  case $1 in
    -h|--help)
        usage 1>&2
        exit 1
      ;;
    -v|--version)
        echo "${PROGNAME} ${PROGVERSION} - github/sag47/my_internal_ca project" 1>&2
        exit 1
      ;;
    -c|--create)
        create=true
        cname="${2}"
        shift 2
      ;;
    --crl)
        crl=true
        shift 1
      ;;
    -r|--renew)
        renew=true
        cname="${2}"
        shift 2
      ;;
    -x|--revoke)
        revoke=true
        cname="${2}"
        shift 2
      ;;
    --force)
        force=true
        shift 1
      ;;
    --)
        shift
        break
      ;;
    *)
        shift
      ;;
    esac
done

#
# Program functions
#

function preflight(){
  STATUS=0
  option=0
  if ! [ -d "./certs" -a -d "./crl" -a -d "./newcerts" -a -d "./private" -a -f "./index.txt" -a -f "./openssl.my.cnf" -a -f "./serial" -a -f "./certs/myca.crt" -a -f "./private/myca.key" -a -f "./subject" ];then
    echo "cert.sh can only be run from a managed certicate authority directory." 1>&2
    exit 1
  fi
  for x in ${create} ${crl} ${renew} ${revoke};do
    if ${x};then
      ((option++))
    fi
  done
  if [ "${option}" -eq "0" ];then
    echo "Must choose at least one action: --create, --crl, --renew, --revoke."
    STATUS=1
  elif [ "${option}" -gt "1" ];then
    echo "May not choose more than one action.  Only one: --create, --crl, --renew, --revoke."
    STATUS=1
  fi
  if ${renew} && [ ! -f "./private/${cname}.key" ];then
    echo "${cname}.key does not exist!"
    echo "Perhaps you need to --create a new CSR?"
    STATUS=1
  fi
  if ! ${force} && ${create} && [ -f "./private/${cname}.key" -o -f "./certs/${cname}.crt" ];then
    echo "You must revoke the old ${cname} certificate first or renew your current certificate."
    echo "You may may force this action with --force.  This is generally not recomended."
    STATUS=1
  fi
  if ! ${force} && ${renew} && [ ! -f "./private/${cname}.key" -o ! -f "./certs/${cname}.crt" ];then
    echo "Missing certificate or key or both for ${cname}."
    if [ -f "./private/${cname}.key" ];then
      echo "Certificate renewal may be forced using --force.  This is generally not recommended."
    fi
    STATUS=1
  fi
  if ${renew} && [ ! -f "./private/${cname}.key" ];then
    echo "This action can't be forced by cause ./private/${cname}.key is missing."
    STATUS=1
  fi
  if ${revoke} && [ ! -f "./private/${cname}.key" -a ! -f "./certs/${cname}.crt" ];then
    echo "Both the certificate and private key must exist for revoke to work."
    if [ -f "./private/${cname}.key" ];then
      echo "The private key ./private/${cname}.key seems to exist.  Did you mean to --renew?"
    fi
    STATUS=1
  fi
  return ${STATUS}
}

#
# Main execution
#

#Run a preflight check on options for compatibility.
if ! preflight 1>&2;then
  echo "Command aborted due to previous errors." 1>&2
  echo "Perhaps try --help option." 1>&2
  exit 1
fi

#set the reqdir where certificate signing requests will be temporarily stored
reqdir="${reqdir:-/tmp}"
#remove trailing slash if any
reqdir="${reqdir%/}"

if ${create};then
  #do some precleanup if stuff exists
  if ${force};then
    rm -f "${reqdir}/${cname}.csr" "./private/${cname}.key" "./certs/${cname}.crt"
  fi

  #grab the subject from the subject file
  subj="$(head -n1 ./subject)${cname}"

  #generate the private key and certificate signing request
  openssl req -out "${reqdir}/${cname}.csr" -new -newkey rsa:${strength} -nodes -subj "${subj}" -keyout "./private/${cname}.key" -days ${length}

  #sign the certificate
  openssl ca -config openssl.my.cnf -policy policy_anything -out "./certs/${cname}.crt" -infiles "${reqdir}/${cname}.csr"

  #final cleanup and security measures
  rm -f "${reqdir}/${cname}.csr"
  chmod 644 "./certs/${cname}.crt"
  chmod 600 "./private/${cname}.key"

  #run some tests
  echo "" 1>&2
  echo "" 1>&2
  echo "Certificate signing information..." 1>&2
  openssl x509 -subject -issuer -enddate -noout -in "./certs/${cname}.crt" 1>&2
  echo "" 1>&2
  echo "Verify certificate..." 1>&2
  openssl verify -purpose sslserver -CAfile "./certs/myca.crt" "./certs/${cname}.crt" 1>&2

elif ${crl};then
  #generate the current certificate revokation list
  DATE="$(date +%Y-%m-%d-%s)"
  echo "Generate a new certificate revocation list." 1>&2
  openssl ca -config openssl.my.cnf -gencrl | openssl crl -text > ./crl.pem
  cp "./crl.pem" "./crl/crl_${DATE}.pem"
  echo "The latest ./crl.pem has been generated and ./crl/crl_${DATE}.pem has been created."

elif ${renew};then
  if [ -f "./certs/${cname}.crt" ];then
    #revoke the certificate
    echo "Revoke certificate." 1>&2
    openssl ca -config openssl.my.cnf -revoke "./certs/${cname}.crt"

    #make a backup directory to store revoked certificates and keys
    if [ ! -d "./backup" ];then
      mkdir "./backup"
    fi

    #back up the old certificate and key so it is no longer tracked for renewel but can still be referenced if necessary.
    DATE="$(date +%Y-%m-%d-%s)"
    echo "Backup old certificate and key." 1>&2
    cp "./certs/${cname}.crt" "./backup/${cname}_${DATE}.crt"
    cp "./private/${cname}.key" "./backup/${cname}_${DATE}.key"
  fi

  #grab the subject from the subject file
  subj="$(head -n1 ./subject)${cname}"

  #renew the certificate
  echo "Renew certificate for ${cname}." 1>&2
  openssl req -out "${reqdir}/${cname}.csr" -new -subj "${subj}" -key "./private/${cname}.key" -days ${length}

  #sign the certificate
  rm -f "./certs/${cname}.crt"
  openssl ca -config openssl.my.cnf -policy policy_anything -out "./certs/${cname}.crt" -infiles "${reqdir}/${cname}.csr"

  #generate the current certificate revokation list
  echo "Generate a new certificate revocation list." 1>&2
  openssl ca -config openssl.my.cnf -gencrl | openssl crl -text -noout > ./crl.pem
  cp "./crl.pem" "./crl/crl_${DATE}.pem"
  echo "The latest ./crl.pem has been generated and ./crl/crl_${DATE}.pem has been created."

  #final cleanup and security measures
  rm -f "${reqdir}/${cname}.csr"
  chmod 644 "./certs/${cname}.crt"
  chmod 600 "./private/${cname}.key"

  #run some tests
  echo "" 1>&2
  echo "" 1>&2
  echo "Certificate signing information..." 1>&2
  openssl x509 -subject -issuer -enddate -noout -in "./certs/${cname}.crt" 1>&2
  echo "" 1>&2
  echo "Verify certificate..." 1>&2
  openssl verify -purpose sslserver -CAfile "./certs/myca.crt" "./certs/${cname}.crt" 1>&2

elif ${revoke};then
  #revoke the certificate
  echo "Revoke certificate." 1>&2
  openssl ca -config openssl.my.cnf -revoke "./certs/${cname}.crt"

  #make a backup directory to store revoked certificates and keys
  if [ ! -d "./backup" ];then
    mkdir "./backup"
  fi

  #back up the old certificate and key so it is no longer tracked for renewel but can still be referenced if necessary.
  DATE="$(date +%Y-%m-%d-%s)"
  echo "Backup old certificate and key." 1>&2
  mv "./certs/${cname}.crt" "./backup/${cname}_${DATE}.crt"
  mv "./private/${cname}.key" "./backup/${cname}_${DATE}.key"

  #generate the current certificate revokation list
  echo "Generate a new certificate revocation list." 1>&2
  openssl ca -config openssl.my.cnf -gencrl | openssl crl -text -noout > ./crl.pem
  cp "./crl.pem" "./crl/crl_${DATE}.pem"
  echo "Finished revoking ${cname}.  The latest ./crl.pem has been generated and ./crl/crl_${DATE}.pem has been created."
fi
