#!/bin/bash -e
#Script by Sam Gleske
#Tue Jan 26 17:21:21 PST 2016
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
  Generate SSL SAN server certificates for a local CA.  Where the common-name is
  typically a domain name.

OPTIONS:
  -h,--help      show help
  --ip-alts      One or more ip addresses as the following argument (space
                 separated).  They will be used as subject alternative names.
  --dns-alts     One or more domain names as the following argument (space
                 separated).  They will be used as subject alternative names.
  --localhost    Include loopback hostname and IP addresses as part of the
                 signed certificate.  localhost, IPv4 127.0.0.1, and IPv6 ::1.

EXAMPLES:
  Generate a basic certificate using DNS only.

    $0 example.com

  Generate a more advanced certificate allowing auth to happen over multiple
  domains as well as via IP.

    $0 example.com --dns-alts "a.example.com b.example.com" --ip-alts "10.0.0.1"
EOF
}

#common name
server=""
dns_alts=""
ip_alts=""
use_localhost=false

while [ "$#" -gt '0' ]; do
  case $1 in
    -h|--help)
      usage 1>&2
      exit 1
      ;;
    --localhost)
      use_localhost=true
      shift
      ;;
    --ip-alts)
      shift
      ip_alts="$1"
      shift
      ;;
    --dns-alts)
      shift
      dns_alts="$1"
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

if [ -z "$server" ];then
  echo "Error: missing common-name which is typically a DNS name." 1>&2
  usage 1>&2
  exit 1
fi

#start alternative names for openssl cnf
if ${use_localhost}; then
  dns_alts_cnf="DNS:${server},DNS:localhost"
  #::1 is IPv6 loopback
  ip_alts_cnf="IP:127.0.0.1,IP:::1"
else
  dns_alts_cnf="DNS:${server}"
  ip_alts_cnf=""
fi
if [ ! -z "${ip_alts}" ]; then
  for x in ${ip_alts}; do
    ip_alts_cnf="${ip_alts_cnf},IP:${x}"
  done
fi
ip_alts_cnf="${ip_alts_cnf#,}"
if [ ! -z "${dns_alts}" ]; then
  for x in ${dns_alts}; do
    dns_alts_cnf="${dns_alts_cnf},DNS:${x}"
  done
fi
all_alts="${dns_alts_cnf},${ip_alts_cnf}"
all_alts="${all_alts%,}"

#configuration for openssl
opensslcnf="basicConstraints=CA:FALSE
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer
subjectAltName = ${all_alts}"

cd "${CERT_DIR}"

if [ -e "certs/${server}.crt" ]; then
  echo "Server certificate exists.  Must revoke existing certificate." 1>&2
  echo "revoke_cert.sh ${server}" 1>&2
  exit 1
fi

#create the key and CSR
openssl req -config openssl.cnf -new -newkey rsa:4096 -sha256 \
  -keyout "private/${server}.key" -subj "/CN=${server}" \
  -text -out "newcerts/${server}.csr" ${REQ_OPTS}

#sign the CSR
openssl ca -config openssl.cnf -extfile <( echo "${opensslcnf}" ) \
  -in "newcerts/${server}.csr" -out "certs/${server}.crt" -batch

#change appropriate permissions
chmod 0600 private/${server}.key
chmod 0644 certs/${server}.crt
