#!/bin/bash

# set working directory
DIR="$(dirname $0)"
mkdir -p "$DIR/data"
cd "$DIR/data"

## Create account key for LetsEncrypt.org once
if [ ! -f account.key ]; then
  openssl genrsa 4096 > account.key
  #openssl rsa -in account.key -pubout > account.pub
fi

## Create CSR and key once
if [ ! -f domain.csr ]; then
  # Get system ssl config
  CNF=/etc/ssl/openssl.cnf
  if [ ! -f $CNF ]; then # maybe testing on osx
    CNF=/System/Library/OpenSSL/openssl.cnf
    if [ ! -f $CNF ]; then
      echo 'Error: Cant find openssl.cnf'
      exit 1
    fi
  fi
  cp $CNF openssl.cnf

  # Get user config
  if [ ! -f csr.conf ]; then
    echo 'Error: Cant find csr.conf, please place in ./data/csr.conf'
    exit 1
  fi
  SUBJECT="$(head -1 csr.conf)"
  DOMAINS="$(tail -1 csr.conf)"
  if [[ -z "$SUBJECT" ]] || [[ -z "$DOMAINS" ]]; then
    echo 'Error: csr.conf is incomplete'
    exit 1
  fi

  # Add user confing to system config
  echo '[SAN]' >> openssl.cnf
  echo "subjectAltName=$DOMAINS" >> openssl.cnf

  # Create CSR and key
  openssl req -new \
    -keyout domain.key.pem -newkey rsa:4096 -sha256 -nodes \
    -subj "$SUBJECT" -reqexts SAN \
    -config openssl.cnf \
    -out domain.csr #.der -outform DER
fi


