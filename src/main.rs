use sqlx::postgres::PgPoolOptions;
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
    let connection_pool = PgPoolOptions::new().connect_lazy_with(config.database.with_db());

    // set up tcp listener
    let address = format!("{}:{}", &config.app.host, &config.app.port);
    let listener = TcpListener::bind(&address)?;

    // launch our server
    run(listener, connection_pool)?.await
}
