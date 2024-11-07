use tracing::{subscriber::set_global_default, Subscriber};
use tracing_bunyan_formatter::{BunyanFormattingLayer, JsonStorageLayer};
use tracing_log::LogTracer;
use tracing_subscriber::fmt::MakeWriter;
use tracing_subscriber::{layer::SubscriberExt, EnvFilter, Registry};

/// Compose multiple layers into a `tracing`'s subscriber
///
/// # Implementation Notes
///
/// we are using `impl Subscriber` as return type to avoid having to spell out the actual type of
/// the returned subscriber, which is indeed quite complex.
/// We need to explicitly call out that the returned subscriber is `Send` and `Sync` to make it
/// possible to pass it to `init_subscriber` later on.
///
/// * `name`: The name of the subscriber
/// * `env_filter`: log level
pub fn get_subscriber<T>(
    name: String,
    env_filter: Option<String>,
    writer: T,
) -> impl Subscriber + Send + Sync
where
    T: for<'a> MakeWriter<'a> + Send + Sync + 'static,
{
    // define log level
    let env_filter = EnvFilter::try_from_default_env()
        .unwrap_or_else(|_| EnvFilter::new(env_filter.unwrap_or("info".into())));

    let formatting_layer = BunyanFormattingLayer::new(name, writer);

    // define subscriber
    Registry::default()
        .with(env_filter)
        .with(JsonStorageLayer)
        .with(formatting_layer)
}

/// Register a subscriber a s global default to process span data.
///
/// It should only be called once!
///
/// * `subscriber`: the subscriber that should be registered
pub fn init_subscriber(subscriber: impl Subscriber + Send + Sync) {
    // redirect all `log`'s events to our subscriber
    LogTracer::init().expect("Failed to set logger");

    // enable log subscriber
    set_global_default(subscriber).expect("Failed to set subscriber");
}
