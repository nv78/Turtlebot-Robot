#!/bin/bash

# First argument: Client identifier
# this must be run from the directory in which you have found it
# and can be run like:
# ./make_config.sh travers
# assuming you have already created travers.crt and travers.key
# in the KEY_DIR

KEY_DIR=../openvpn-ca/keys
OUTPUT_DIR=../client-configs/files
BASE_CONFIG=../client-configs/base.conf

cat ${BASE_CONFIG} \
    <(echo -e '<ca>') \
    ${KEY_DIR}/ca.crt \
    <(echo -e '</ca>\n<cert>') \
    ${KEY_DIR}/${1}.crt \
    <(echo -e '</cert>\n<key>') \
    ${KEY_DIR}/${1}.key \
    <(echo -e '</key>\n<tls-auth>') \
    ${KEY_DIR}/ta.key \
    <(echo -e '</tls-auth>') \
    > ${OUTPUT_DIR}/${1}.ovpn
