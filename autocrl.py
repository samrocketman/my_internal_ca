#!/usr/bin/env python
#Sam Gleske
#Mon Mar 10 10:54:51 EDT 2014
#Ubuntu 12.04.4 LTS \n \l
#Linux 3.8.0-36-generic x86_64
#Python 2.7.3

#This will automatically generate a new certificate revocation list.
#This is intended to be run via cron monthly in an automated fashion.

#USAGE:
#  ./autocrl.py

import os
import pexpect
from sys import argv
from sys import exit
from sys import stderr
command="./cert.sh"
args=['--crl']
child=pexpect.spawn(command=command,args=args)
if os.path.isfile('secret'):
  with open('secret','r') as f:
    password=f.read()
    password=password.strip()
else:
  print >> stderr, "secret file not found!  Create a file secret whose contents is the password to the CA private key."
  exit(1)
if child.expect('Enter pass phrase for ./private/myca.key:') == 0:
  sentbytes=child.sendline(password)
results=child.readlines()
print >> stderr, results[-1].strip()
