# My Internal Certificate Authority

I use this lightweight set of scripts to manage my own internal certificate
authority.  I share them with you.  My scripts are based off of
[Be your own CA][yourca_tut] and [Docker CA][docker_ca].

Features:

* Manage a personal certificate authority.
* Server SAN certificates ([Subject Alternative Name][wiki_san]).
* Client certificates for TLS [mutual authentication][wiki_ma].
* Create Java keystores from the X.509 certificates.

# How to set up

System requirements

* GNU/Linux (other platforms untested)
* openssl tools installed

### Create the CA

Execute `setup_ca.sh` from the current directory of the repository.  When
executed this will do a few things.  It will create the openssl `myCA` directory
structure for a managed certificate authority.  All certificate authority
information and management will be located within the `myCA` directory.

    ./setup_ca.sh

Customize the subject.

    ./setup_ca.sh -subj '/C=US/ST=Pennsylvania/L=Philadelphia/O=Example Domain/OU=Systems/CN=Super Root CA'

### Environment variables

* `CERT_DIR` - the directory where the certificate authority certificates and
  other client/server certificates are output.
* `REQ_OPTS` - additional opts to pass to the `openssl req` command in a script.

e.g.

    CERT_DIR="/tmp/myCA" ./setup_ca.sh

### Sign new certificates

    #server certificates
    ./server_cert.sh example.com
    #client certificates
    ./client_cert.sh me@example.com

A new signed certificate will be placed in `./myCA/certs/` and the private key
will be in `./myCA/private/`.

Issue a wildcard certificate.

    bash -f ./server_cert.sh '*.example.com'

### Revoke certificates

    ./revoke_cert.sh example.com

A new certificate revocation list (crl) will be generated.  The latest is stored
in `./myCA/crl.pem` and any previously published CRLs can be viewed at
`./myCA/crl/crl_*.pem`.  A backup of the certificate and key will be maintained
in `./myCA/backup` which is autocreated.  The revoked certificate will be
removed from `./myCA/certs` and the key will be removed from `./myCA/private`.

### Generate a java keystore from certificates

    ./keystore.sh example.com

You will be prompted for a password by the script.  That password will set the
java keystore password.

# Customization via .env file

You can populate a `.env` file to customize some of the options.  You can change
the behavior of scripts based environment variables set.  The following is an
example.

```bash
# lan_server.sh
LAN=192.168.1

# server_cert.sh
SERVER_EXPIRE_DAYS=397

# setup_ca.sh
CA_CERT_NAME="Local Certificate Authority"
CA_CERT_ORG="Gleske Internal"
CA_CERT_ORG_UNIT=Systems
CA_CERT_CITY="Garden Grove"
CA_CERT_STATE=California
CA_CERT_COUNTRY=US
# 20 years
CA_CERT_EXPIRE_DAYS=7300

# all scripts
REQ_OPTS="-batch -nodes"
CERT_DIR=./myCA
```

# Security recommendations

Here's a few security tips if you've not managed a personal certificate
authority before.

* Keep your certificate authority offline.  For example, store it on an
  encrypted flash drive and disconnect it from your computer when you don't need
  to create certificates.
* If nobody else is accessing a service except you, then a personal certificate
  authority is arguably more trustworthy than a third party.  Install your
  personal CA in your browsers and devices to use.
* Publish your certificate revocation list in a place where your browsers and
  devices can access it.
* Do not issue certificates longer than 398 days otherwise Apple devices will
  not recognize the certificate as valid.  The default issuance has been
  reduced from 2 years down to 397 days.  The expiration is configurable.

# Additional information and alternatives

### Private CA Alternatives

Using self signed certificates is always a bad idea. It's far more secure to
self manage a certificate authority than it is to use self signed certificates.
Running a certificate authority is easy.

In addition to the scripts in this repository, here is a short recommended list
of scripts and resources for managing a certificate authority.

1. The [xca project][xca] provides a graphical front end to certificate
   authority management in openssl.  It is available for Windows, Linux, and Mac
   OS.
2. The OpenVPN project provides a nice [set of scripts][ovpn_scripts] for
   managing a certificate authority as well.
3. [Be your own CA][yourca_tut] tutorial provides a more manual method of
   certificate authority management outside of scripts or UI.  It provides
   openssl commands for certificate authority management.  Additionaly, one can
   read up on certificate management in the [SSL Certificates HOWTO][tldp_certs]
   at The Linux Documentation Project.
4. Use my scripts in this repository which is based on option `3` in this list.
   Supports server certs only.
5. Use [certificate-automation][cert_auto] which is similar to these scripts
   organized slightly differently.  Supports client certs as well.

Once a certificate authority is self managed simply add the CA certificate to
all browsers and mobile devices. Enjoy secure and validated certificates
everywhere.

### Public CA Alternatives

If a service you manage is designated for public access then self managing a
certificate authority may not be the best option.  Signed Domain Validated (DV)
certificates should still be the preferred method to secure your public service.

1. [CAcert.org][cacert] is a community driven certificate authority which
   provides free SSL certificates.  Note:  See the [inclusion
   page][cacert_inclusion] to see which applications and distros
   include the cacert.org root certificates.
2. [Let's Encrypt][lets_encrypt] is a free, automated, and open Certificate
   Authority.

[cacert]: http://www.cacert.org/
[cacert_inclusion]: http://wiki.cacert.org/InclusionStatus
[cert_auto]: https://github.com/berico-rclayton/certificate-automation
[docker_ca]: https://docs.docker.com/engine/security/https/
[lets_encrypt]: https://letsencrypt.org/
[ovpn_scripts]: http://openvpn.net/index.php/open-source/documentation/howto.html#pki
[tldp_certs]: http://www.tldp.org/HOWTO/SSL-Certificates-HOWTO/x195.html
[wiki_ma]: https://en.wikipedia.org/wiki/Mutual_authentication
[wiki_san]: https://en.wikipedia.org/wiki/Subject_Alternative_Name
[xca]: http://sourceforge.net/projects/xca/
[yourca_tut]: http://www.g-loaded.eu/2005/11/10/be-your-own-ca/
