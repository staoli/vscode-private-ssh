#!/bin/bash

set -x

SSHD_PORT=$1
SSHD_PATH=$2

if [[ -f ~/${SSHD_PATH}/id_rsa_server ]]
then
  rm ~/${SSHD_PATH}/id_rsa_server
fi

if [[ -f ~/${SSHD_PATH}/id_rsa_server.pub ]]
then
  rm ~/${SSHD_PATH}/id_rsa_server.pub
fi

ssh-keygen -q -f ~/${SSHD_PATH}/id_rsa_server -N "" -t rsa

cat > ~/${SSHD_PATH}/my_sshd_config << SSHD_CONFIG
Port ${SSHD_PORT}
# Point to keys you have permission to read
HostKey ~/${SSHD_PATH}/id_rsa_server
AuthorizedKeysFile ~/${SSHD_PATH}/authorized_keys
PidFile ~/${SSHD_PATH}/sshd.pid
Subsystem sftp internal-sftp
# Disable features that require root
UsePAM no
SSHD_CONFIG

/usr/sbin/sshd -f ~/${SSHD_PATH}/my_sshd_config
echo $?
