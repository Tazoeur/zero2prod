use std log

let db_user = $env.POSTGRES_USER? | default "postgres"
let db_password = $env.POSTGRES_PASSWORD? | default "masterpassword"
let db_name = $env.POSTGRES_DB? | default "newsletter"
let db_port = $env.POSTGRES_PORT? | default "5432"
let db_host = $env.POSTGRES_HOST? | default "localhost"

let database_url = $"postgres://($db_user):($db_password)@($db_host):($db_port)/($db_name)"


def check_requirements [] {
	mut has_error = false;
	if ( which psql | is-empty) {
		log error "`psql` is not installed"
		$has_error = true;
	}
	if ( which sqlx | is-empty ) {
		log error "`sqlx` is not installed"
		log error "Use:"
		log error "cargo install sqlx-cli --no-default-features --features rustls,postgres"
		$has_error = true
	}
	return (not $has_error)
}

def launch_docker [] {
	(
		docker run
		-e POSTGRES_USER=$"($db_user)"
		-e POSTGRES_PASSWORD=$"($db_password)"
		-e POSTGRES_DB=$"( $db_name )"
		-e POSTGRES_HOST=$"( $db_host )"
		-p $"($db_port):5432"
		-d
		postgres
		postgres -N 1000
	)
}

def wait4pg [] {
	while  (psql $database_url -c '\q' | complete | get exit_code) != 0 { 
		log info "Posgres is still unavailable - sleeping..."
		sleep 1sec
	}
}
def setup_database [] {
	with-env {DATABASE_URL: $database_url} {
		sqlx database create
		sqlx migrate run
	}
	echo $'$env.DATABASE_URL = "($database_url)"'

}

def main [
	--skip-docker,
] {
	if (not (check_requirements) ) {
		return
	}
	if (not $skip_docker) {
		launch_docker
	}
	wait4pg
	setup_database

}


