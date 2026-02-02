#  Installation

---

For linux or macOs:

```bash
curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh
```

Check versions:

```bash
rustc --version
cargo --version
```

To update:

```bash
rustup update
```

To uninstall:

```bash
rustup self uninstall
```

---

# Playground

---

Simple running command:

```bash
rustc main.rs
```

Cargo.toml file can have:

```bash
[packages]
[dependencies]
[dev-dependencies]
[build-dependencies]
[features]
[profile.release]
[[bin]]
[lib]
[workspace]
[replace]
[target.'cfg(target_os = "linux")'.dependencies]
[patch.crates-io]
[package.metadata.docs.rs]
[lints.rust]
[[example]]
[[bench]]
[badges]
........................
# Many more as per use
```

Playing with `Cargo.toml` with example + usage: 

```bash
[package]
name = "my_app"
version = "1.2.3"
edition = "2021"
description = "High performance backend service"
authors = ["uch <you@mail.com>"]
license = "MIT"
repository = "https://github.com/you/my_app"
readme = "README.md"
homepage = "https://myapp.com"
documentation = "https://docs.rs/my_app"
keywords = ["backend", "api", "rust"]
categories = ["web-programming"]
publish = true


[dependencies]
serde = "1.0"
tokio = { version = "1", features = ["full"] }
axum = "0.7"
# ADVANCED 
rand = { git = "https://github.com/rust-random/rand" }
my_lib = { path = "../my_lib" }
openssl = { version = "0.10", optional = true }



# for tests/benches
[dev-dependencies]
criterion = "0.5"



# Used by build.rs
[build-dependencies]
cc = "1.0"


# critical
[features]
default = ["http"]
http = ["reqwest"]
tls = ["openssl"]
# USED AS: cargo build --features tls


# For build optimizations and production grade aiming smaller binary - faster - no stack unwinding
[profile.release]
opt-level = 3
lto = true
codegen-units = 1
panic = "abort"
strip = true


# multiplke executables
[[bin]]
name = "server"
path = "src/bin/server.rs"

[[bin]]
name = "worker"
path = "src/bin/worker.rs"




[lib]
name = "core"
crate-type = ["rlib", "cdylib"]
# used for WASM, FFI, shared libs




# for professional microservices setup
[workspace]
members = [
  "api",
  "core",
  "iot",
]



# patch overriding
[patch.crates-io]
serde = { git = "https://github.com/serde-rs/serde" }






[lints.rust]
unsafe_code = "forbid"



# publish control 
exclude = ["secret.env"]
include = ["src/**"]
```


To use cargo update:

```bash
cargo update
# or
cargo update --verbose
```
