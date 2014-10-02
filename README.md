# My Internal Certificate Authority

I use this lightweight set of scripts to manage my own internal certificatex
authority.  I share them with you.  My scripts are based off of
[Be your own CA][yourca_tut] and the comments in `setup_ca.sh` reflect it.

# How to set up

System requirements

* GNU/Linux
* openssl tools installed

### Create the CA

Execute `setup_ca.sh` from the current directory of the repository.  When
executed this will do a few things.  It will create the openssl `myCA` directory
structure for a managed certificate authority.  All certificate authority
information and management will be located within the `myCA` directory.

There is an optional `rootdir` environment variable that can be passed to
specify a custom home for where the `myCA` directory can be created.  An example
follows.

    rootdir="/tmp" ./setup_ca.sh

### Update the signed certificate subject

Once you have your certificate authority set up edit the `myCA/subject` file
which will be used as the subject when generating your certificates.  Be sure to
leave the `/CN=` at the end of the file because after that will be the first
argument of the `cert.sh` script.  This follows the standard openssl subject
format so read the openssl man page to learn more (`man req` specifically the
topic `-subj arg`).

### A quick final step

You might want to copy `cert.sh` into your `myCA` directory or make sure that it
is in your `$PATH`.

# Ready to manage certificates

Now that you have everything set up you can start using `cert.sh` to manage your
signed certificates.  `cert.sh` must be run from within the `myCA` working
directory wherever it might be.  `cert.sh` will automatically fail if the
current working directory is not the root of the `myCA` directory.  To see
information on the `cert.sh` command see `cert.sh --help`.

### Sign new certificates

    cert.sh --create myserver.local

A new signed certificate will be placed in `./myCA/certs/` and the private key
will be in `./myCA/private/`.

### Renew certificates

    cert.sh --renew myserver.local

The certificate in `./myCA/certs/myserver.local.crt` and the key in
`./myCA/private/myserver.local.key` will reflect the latest certificate.

A new certificate revocation list (crl) will be generated.  The latest is stored
in `./myCA/crl.pem` and any previously published CRLs can be viewed at
`./myCA/crl/crl_*.pem`.  A backup of the certificate and key will be maintained
in `./myCA/backup` which is autocreated.

### Revoke certificates

    cert.sh --revoke myserver.local

A new certificate revocation list (crl) will be generated.  The latest is stored
in `./myCA/crl.pem` and any previously published CRLs can be viewed at
`./myCA/crl/crl_*.pem`.  A backup of the certificate and key will be maintained
in `./myCA/backup` which is autocreated.  The revoked certificate will be
removed from `./myCA/certs` and the key will be removed from `./myCA/private`.

### Custom certificate request directory

By default certificate requests will be temporarily stored in `/tmp`.  If this
is not desired there is an optional `reqdir` environment variable that can be
passed to specify a custom temporary directory for signing certificate requests.
An example follows.

    reqdir="/requests" cert.sh --create myserver.local

# Additional information and alternatives

### Private CA Alternatives

Using self signed certificates is always a bad idea. It's far more secure to
self manage a certificate authority than it is to use self signed certificates.
Running a certificate authority is easy.  There are four recommended options for
managing a certificate authority for signing certificates.

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

If a server service is designated for public access then self managing a
certificate authority may not be the best option.  Signed certificates should
still be the preferred method  to secure your public service.

1. The [StartCom SSL Certificate Authority][startcom_ssl] provides a free
   service to sign Class 1 SSL certificates.  StartCom root certificates appear
   to be included in all popular browsers.
2. [CAcert.org][cacert] is a community driven certificate authority which
   provides free SSL certificates.  Note:  See the
   [inclusion page][cacert_inclusion] to see which applications and distros
   include the cacert.org root certificates.

If you are attempting payment transactions you should pay for an extended
validation (EV) certificate from one of the EV issuing certificate authorities.

[xca]: http://sourceforge.net/projects/xca/
[ovpn_scripts]: http://openvpn.net/index.php/open-source/documentation/howto.html#pki
[yourca_tut]: http://www.g-loaded.eu/2005/11/10/be-your-own-ca/
[tldp_certs]: http://www.tldp.org/HOWTO/SSL-Certificates-HOWTO/x195.html
[startcom_ssl]: http://cert.startcom.org/
[cert_auto]: https://github.com/berico-rclayton/certificate-automation
[cacert]: http://www.cacert.org/
[cacert_inclusion]: http://wiki.cacert.org/InclusionStatus
