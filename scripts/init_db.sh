#!/bin/bash

set -x
set -euo pipefail


#
# Environment variables
#

DB_USER="${POSTGRES_USER:=postgres}"
DB_PASSWORD="${POSTGRES_PASSWORD:=masterpassword}"
DB_NAME="${POSTGRES_DB:=newsletter}"
DB_PORT="${POSTGRES_PORT:=5432}"
DB_HOST="${POSTGRES_HOST:=localhost}"

DATABASE_URL="postgres://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
#
# Functions
#

error_message () {
	echo >&2 $1
}
check4pg () {
	if ! [ -x "$(command -v psql)" ]; then
		error_message "Error: psql is not installed"
		exit 1
	fi
}
check4sqlx() {
	if ! [ -x "$(command -v sqlx)" ]; then
		error_message "Error: sqlx is not installed"
		error_message "Use:"
		error_message "cargo install sqlx-cli --no-default-features --features rustls,postgres"
		exit 1
	fi
}
wait4pg () {
	
	until psql "$DATABASE_URL" -c '\q'; do
		error_message "Postgres is still inavailable - sleeping..."
		sleep 1
	done
}

#
# Run
#

check4pg
check4sqlx

if [[ "${SKIP_DOCKER}" == "false" ]]; then
	docker run \
		-e POSTGRES_USER=${DB_USER} \
		-e POSTGRES_PASSWORD=${DB_PASSWORD} \
		-e POSTGRES_DB=${DB_NAME} \
		-e POSTGRES_HOST=${DB_HOST} \
		-p "${DB_PORT}:5432" \
		-d \
		postgres \
		postgres -N 1000
	#                ^ increased maximum number of connections for testing purposes
fi

wait4pg

export DATABASE_URL
sqlx database create
sqlx migrate run
