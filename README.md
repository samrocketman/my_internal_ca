# My Internal Certificate Authority

I use this lightweight set of scripts to manage my own internal certificate authority.  I share them with you.  My scripts are based off of [Be your own CA][yourca_tut] and the comments in `setup_ca.sh` reflect it.

# How to set up

System requirements

* GNU/Linux
* openssl tools installed

### Create the CA

Execute `setup_ca.sh` from the current directory of the repository.  When executed this will do a few things.  It will create the openssl `myCA` directory structure for a managed certificate authority.  All certificate authority information and management will be located within the `myCA` directory.

There is an optional `rootdir` environment variable that can be passed to specify a custom home for where the `myCA` directory can be created.  An example follows.

    rootdir="/tmp" ./setup_ca.sh

### Update the signed certificate subject

Once you have your certificate authority set up edit the `myCA/subject` file which will be used as the subject when generating your certificates.  Be sure to leave the `/CN=` at the end of the file because after that will be the first argument of the `cert.sh` script.  This follows the standard openssl subject format so read the openssl man page to learn more (`man req` specifically the topic `-subj arg`).

### Sign certificates

Now that you have everything set up you can start using `cert.sh` to generate your signed certificates.  The first argument of `cert.sh` is simply the server name in which the certificate will be signed.  By default certificate requests will be temporarily stored in `/tmp`.  If this is not desired there is an optional `reqir` environment variable that can be passed to specify a custom temporary directory for signing certificate requests.  An example follows.

    reqdir="/requests" ../cert.sh myserver.local

By default the certificate authority will be created within this repository so using `../cert.sh` is the recomended method.  However, in the case of a custom `rootdir` you can add `cert.sh` to your `$PATH` and execute it anywhere you like.  `cert.sh` will automatically fail if the current working directory is not the root of the `myCA` directory.

# Additional information and alternatives

Using self signed certificates is always a bad idea. It's far more secure to self manage a certificate authority than it is to use self signed certificates. Running a certificate authority is easy. There are four recommended options for managing a certificate authority for signing certificates.

1. The [xca project][xca] provides a graphical front end to certificate authority management in openssl.  It is available for Windows, Linux, and Mac OS.
2. The OpenVPN project provides a nice [set of scripts][ovpn_scripts] for managing a certificate authority as well.
3. [Be your own CA][yourca_tut] tutorial provides a more manual method of certificate authority management outside of scripts or UI.  It provides openssl commands for certificate authority management.  Additionaly, one can read up on certificate management in the [SSL Certificates HOWTO][tldp_certs] at The Linux Documentation Project.
4. Use my scripts in this repository which is based on option `3` in this list.

Once a certificate authority is self managed simply add the CA certificate to all browsers and mobile devices. Enjoy secure and validated certificates everywhere.  If a server service is designated for public access then self managing a certificate authority may not be the best option.  Signed certificates should still be the preferred method  to secure your public service.  The [StartCom SSL Certificate Authority][startcom_ssl] provides a free service to sign Class 1 SSL certificates.  If you are attempting payment transactions you should pay for an extended validation (EV) certificate from one of the EV issuing certificate authorities.

[xca]: http://sourceforge.net/projects/xca/
[ovpn_scripts]: http://openvpn.net/index.php/open-source/documentation/howto.html#pki
[yourca_tut]: http://www.g-loaded.eu/2005/11/10/be-your-own-ca/
[tldp_certs]: http://www.tldp.org/HOWTO/SSL-Certificates-HOWTO/x195.html
