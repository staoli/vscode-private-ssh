#!/bin/bash

SSHD_PORT=$1

if [[ -f ~/.ssh/id_rsa_server ]]
then
  rm ~/.ssh/id_rsa_server
fi

if [[ -f ~/.ssh/id_rsa_server.pub ]]
then
  rm ~/.ssh/id_rsa_server.pub
fi

ssh-keygen -q -f ~/.ssh/id_rsa_server -N "" -t rsa

cat > ~/.ssh/my_sshd_config << SSHD_CONFIG
Port ${SSHD_PORT}
# Point to keys you have permission to read
HostKey ~/.ssh/id_rsa_server
PidFile ~/.ssh/sshd.pid
Subsystem sftp internal-sftp
# Disable features that require root
UsePAM no
SSHD_CONFIG

/usr/sbin/sshd -f ~/.ssh/my_sshd_config
echo $?
