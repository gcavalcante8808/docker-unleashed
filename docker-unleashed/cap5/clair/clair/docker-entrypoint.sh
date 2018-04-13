#!/bin/bash

set -e

CONF=/config/config.yaml
mkdir -p /config

if [[ -z "${DB_HOST}" ]]; then
    echo "No Default DB Host Provided. Assuming 'db'"
    DB_HOST="db"
fi

if [[ -z "${DB_PORT}" ]]; then
    echo "No Default port for Db Provided. Assuming 5432."
    DB_PORT=5432
fi

if [[ -z "${DB_USER}" ]]; then
    echo "No Default User provided for Db. Assuming clair"
    DB_USER="clair"
fi

if [[ -z "${DB_PASSWORD}" ]]; then
    echo "No Default DB Password provided. Assuming clair"
    DB_PASSWORD="clair"
fi

if [ -z "${DB_NAME}" ]; then
    echo "No default db name provided. Assuming clair"
    DB_NAME="clair"
fi


if [[ ! -e "${CONF}" ]]; then
	echo "No Config File Found. Updating One with provided information"
	cp /config/config.yaml.sample $CONF
	sed -i "s/<DB_PASSWORD>/${DB_PASSWORD}/" $CONF
	sed -i "s/<DB_USER>/${DB_USER}/" $CONF
	sed -i "s/<DB_NAME>/${DB_NAME}/" $CONF
	sed -i "s/<DB_HOST>/${DB_HOST}/" $CONF
	sed -i "s/<DB_PORT>/${DB_PORT}/" $CONF
fi

exec /clair -config /config/config.yaml -insecure-tls
