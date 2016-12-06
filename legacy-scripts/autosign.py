#!/usr/bin/env python
#Sam Gleske
#Mon Mar 10 10:54:51 EDT 2014
#Ubuntu 12.04.4 LTS \n \l
#Linux 3.8.0-36-generic x86_64
#Python 2.7.3

#This will automatically sign certificates with a single command
#It is assumed the password is known for the private key of the CA.
#This is intended for internal automation schemes where the certificate
#authority is not critical but generates signed certificates on the fly.

#USAGE:
#  ./autosign.py myserver.local

import os
import pexpect
from sys import argv
from sys import exit
from sys import stderr
if len(argv) == 1:
  print >> stderr, "Must enter a server to autosign!"
  exit(1)
command="./cert.sh"
args=['--create',argv[1]]
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
if child.expect('Sign the certificate\? \[y/n\]:') == 0:
  sentbytes=child.sendline('y')
if child.expect('1 out of 1 certificate requests certified, commit\? \[y/n\]') == 0:
  child.sendline('y')
results=child.readlines()
print >> stderr, results[-1].strip()
