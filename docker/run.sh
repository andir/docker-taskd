#! /bin/sh
#
# run.sh
# Copyright (C) 2015 Óscar García Amor <ogarcia@connectical.com>
#
# Distributed under terms of the MIT license.
#

# If no config file found, do initial config
if ! test -e ${TASKDDATA}/config; then

  # Create directories for log and certs
  mkdir -p ${TASKDDATA}/log ${TASKDDATA}/pki

  # Init taskd and configure log
  taskd init
  taskd config --force log ${TASKDDATA}/log/taskd.log

  # Copy tools for certificates generation and generate it
  cp /usr/share/taskd/pki/generate* ${TASKDDATA}/pki

  cd ${TASKDDATA}/pki
  # Do not overwrite vars file if already mounted or injected
  if ! test -e ${TASKDDATA}/pki/vars; then
    cp /usr/share/taskd/pki/vars ${TASKDDATA}/pki
    echo "CN=$(hostname -f)" >> ${TASKDDATA}/pki/vars
  fi
  ./generate
  cd /

  # Configure taskd to use this newly generated certificates
  taskd config --force client.cert ${TASKDDATA}/pki/client.cert.pem
  taskd config --force client.key ${TASKDDATA}/pki/client.key.pem
  taskd config --force server.cert ${TASKDDATA}/pki/server.cert.pem
  taskd config --force server.key ${TASKDDATA}/pki/server.key.pem
  taskd config --force server.crl ${TASKDDATA}/pki/server.crl.pem
  taskd config --force ca.cert ${TASKDDATA}/pki/ca.cert.pem

  # And finally set taskd to listen in default port
  taskd config --force server 0.0.0.0:53589

  # Create first user
  cd /app/taskd && ./createUser.sh
fi

# Exec CMD or taskd by default if nothing present
if [ $# -gt 0 ];then
  exec "$@"
else
  exec taskd server --data ${TASKDDATA}
fi
