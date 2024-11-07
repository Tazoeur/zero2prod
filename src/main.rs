use sqlx::PgPool;
use std::net::TcpListener;
use zero2prod::telemetry::{get_subscriber, init_subscriber};
use zero2prod::{configuration::get_configuration, startup::run};

#[tokio::main]
async fn main() -> Result<(), std::io::Error> {
    let subscriber = get_subscriber("zero2prod".into(), None, std::io::stdout);
    init_subscriber(subscriber);

    //
    // Application
    //

    // load configuration
    let config = get_configuration().expect("Failed to read configuration.");

    // create postgres connection pool
    let connection_pool = PgPool::connect(&config.database.connection_string())
        .await
        .expect("Failed to connect to Postgres.");

    // set up tcp listener
    let listener = TcpListener::bind("127.0.0.1:8000")?;

    // launch our server
    run(listener, connection_pool)?.await
}
