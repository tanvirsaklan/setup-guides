Fedora machine setup:

### Python 
It is pre-installed.

### Zed text-editor:

```bash
curl -f https://zed.dev/install.sh | sh
```

### Install Rust:

```bash
sudo dnf install curl gcc
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
# check version
rustc --version
cargo --version
```

### Nginx install:

```bash
sudo dnf install nginx
```

### Setup cloudflare:
 
```bash
sudo dnf install https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-x86_64.rpm

# Follow cloudlfare setup guide
 ```
