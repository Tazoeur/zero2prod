#!/bin/bash

set -x
set -euo pipefail

cargo install sqlx-cli --no-default-features --features rustls,postgres
cargo install cargo-nextest
