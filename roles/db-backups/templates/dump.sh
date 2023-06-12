#!/bin/bash

# Ansible managed

DUMP_DIR="{{db_backups_dir}}"
DUMP_FILE_NAME="madek-dump_$(date +%FT%T%Z).pgbin"
DUMP_FILE="${DUMP_DIR}/${DUMP_FILE_NAME}"
LINK_NAME="latest.pgbin"
LINK="${DUMP_DIR}/${LINK_NAME}"
mkdir -p ${DUMP_DIR}
/usr/lib/postgresql/15/bin/pg_dump -d madek --port 5415 -F c -x -O -f ${DUMP_FILE} 
find ${DUMP_DIR} -name 'madek-dump*pgbin' -type f -mtime +10 -exec rm {} \;
cd ${DUMP_DIR} && ln -s -f ${DUMP_FILE_NAME} ${LINK_NAME}
