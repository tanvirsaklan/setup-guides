#!/bin/bash
# Exit on error, unset variables, or pipe failures
set -euo pipefail

echo "🚀 Starting automated Ubuntu/Debian setup for Rust Web & Embedded Workstation..."

# --------------------------------------------------------------------
# 1. System Updates, C/C++ Toolchain, & Cross-Compilation Dependencies
# --------------------------------------------------------------------
echo "📦 Installing system packages and build dependencies..."
sudo apt update && sudo apt upgrade -y

# System utilities, Web, Embedded, Android, and GUI prerequisites
sudo apt install -y \
    curl gcc g++ git build-essential libssl-dev pkg-config nano \
    clang libudev-dev minicom openocd gdb-multiarch cmake libusb-1.0-0-dev \
    libwebkit2gtk-4.1-dev libgtk-3-dev libsoup-3.0-dev libjavascriptcoregtk-4.1-dev \
    libxdo-dev libxcb-render0-dev libxcb-shape0-dev libxcb-xfixes0-dev \
    mold lld libsqlite3-dev default-jdk adb fastboot

# Hardware privilege access for flashing embedded devices without sudo
sudo usermod -aG dialout,plugdev "$USER"

# --------------------------------------------------------------------
# 2. GitHub Setup & Guarded SSH Key Generation
# --------------------------------------------------------------------
echo "🔑 Setting up GitHub SSH & global config..."
read -p "Enter your GitHub email address: " GH_EMAIL
read -p "Enter your Git user.name: " GH_NAME

if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    ssh-keygen -t ed25519 -C "$GH_EMAIL" -N "" -f "$HOME/.ssh/id_ed25519"
else
    echo "⚠️  SSH key already exists at ~/.ssh/id_ed25519, skipping generation."
fi

git config --global user.name "$GH_NAME"
git config --global user.email "$GH_EMAIL"

echo "--------------------------------------------------------"
echo "👉 COPY THIS SSH PUBLIC KEY TO YOUR GITHUB ACCOUNT:"
cat "$HOME/.ssh/id_ed25519.pub"
echo "--------------------------------------------------------"

# --------------------------------------------------------------------
# 3. Global Git Hook (Custom Commit Format)
# --------------------------------------------------------------------
echo "🛠️ Provisioning global custom Git commit hook..."
mkdir -p "$HOME/.config/git/hooks"
git config --global core.hooksPath "$HOME/.config/git/hooks"

cat << 'EOF' > "$HOME/.config/git/hooks/prepare-commit-msg"
#!/bin/bash
COMMIT_MSG_FILE=$1
COMMIT_SOURCE=$2

if [ "$COMMIT_SOURCE" = "message" ] || [ -z "$COMMIT_SOURCE" ]; then
    TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
    GIT_USER=$(git config user.name || echo "UnknownUser")
    ORIGINAL_MSG=$(cat "$COMMIT_MSG_FILE")
    
    if [[ ! "$ORIGINAL_MSG" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2} ]]; then
        echo "${TIMESTAMP}: ${GIT_USER}: ${ORIGINAL_MSG}" > "$COMMIT_MSG_FILE"
    fi
fi
EOF
chmod +x "$HOME/.config/git/hooks/prepare-commit-msg"

# --------------------------------------------------------------------
# 4. Zed Text Editor Setup (AI Features Disabled)
# --------------------------------------------------------------------
echo "⚡ Installing Zed text-editor..."
if ! command -v zed &> /dev/null; then
    curl -f https://zed.dev/install.sh | sh
fi

# Pre-configure Zed settings (AI disabled)
mkdir -p "$HOME/.config/zed"
cat << 'EOF' > "$HOME/.config/zed/settings.json"
{
  "assistant": {
    "enabled": false
  },
  "features": {
    "edit_predictions": "off"
  },
  "telemetry": {
    "metrics": false,
    "diagnostics": false
  },
  "vim_mode": false,
  "ui_font_size": 16,
  "buffer_font_size": 15,
  "theme": "One Dark",
  "lsp": {
    "rust-analyzer": {
      "initialization_options": {
        "check": {
          "command": "clippy"
        },
        "cargo": {
          "allTargets": true,
          "features": "all"
        },
        "procMacro": {
          "enable": true
        }
      }
    }
  },
  "languages": {
    "Rust": {
      "format_on_save": "on"
    }
  }
}
EOF

# --------------------------------------------------------------------
# 5. Rust Toolchain (Web, Embedded & Mobile Cross Target Setup)
# --------------------------------------------------------------------
echo "🦀 Installing Rust development toolchain..."
if ! command -v rustup &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
fi

# Export cargo binaries into current shell environment
export PATH="$HOME/.cargo/bin:$PATH"
source "$HOME/.cargo/env" || true

echo "⚙️ Adding Rust Compilation Targets..."
# Web / WASM
rustup target add wasm32-unknown-unknown

# Embedded Targets (ARM Cortex-M & RISC-V)
rustup target add thumbv6m-none-eabi thumbv7m-none-eabi thumbv7em-none-eabi thumbv7em-none-eabihf riscv32imac-unknown-none-elf

# Android Targets (for Dioxus Mobile)
rustup target add aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android

# Source Components
rustup component add rust-analyzer rust-src clippy llvm-tools-preview

# --------------------------------------------------------------------
# 6. Global CLI Utilities for Web, Mobile, Embedded & Security
# --------------------------------------------------------------------
echo "📦 Installing Rust CLI utilities (dx, sqlx, cargo-ndk, probe-rs, cargo-audit)..."

# Fast linker setup in Cargo config
mkdir -p "$HOME/.cargo"
cat << 'EOF' > "$HOME/.cargo/config.toml"
[target.x86_64-unknown-linux-gnu]
linker = "clang"
rustflags = ["-C", "link-arg=-fuse-ld=mold"]

[target.wasm32-unknown-unknown]
runner = "wasm-server-runner"
EOF

# Install essential binaries
cargo install cargo-binstall

# Install pre-built binaries via binstall where available to save compilation time
cargo binstall -y dioxus-cli || cargo install dioxus-cli
cargo binstall -y sqlx-cli || cargo install sqlx-cli --no-default-features --features postgres,sqlite,mysql
cargo binstall -y cargo-ndk || cargo install cargo-ndk
cargo binstall -y cargo-expand || cargo install cargo-expand
cargo binstall -y cargo-watch || cargo install cargo-watch
cargo binstall -y cargo-audit || cargo install cargo-audit
cargo binstall -y cargo-deny || cargo install cargo-deny
cargo binstall -y probe-rs-tools || cargo install probe-rs-tools
cargo binstall -y flip-link || cargo install flip-link

# --------------------------------------------------------------------
# 7. Android SDK & NDK Setup for Dioxus Mobile
# --------------------------------------------------------------------
echo "🤖 Provisioning Android SDK and NDK..."
ANDROID_HOME="$HOME/Android/Sdk"
mkdir -p "$ANDROID_HOME/cmdline-tools"

if [ ! -d "$ANDROID_HOME/cmdline-tools/latest" ]; then
    CMDLINE_ZIP="/tmp/cmdline-tools.zip"
    curl -sSfL "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip" -o "$CMDLINE_ZIP"
    unzip -q "$CMDLINE_ZIP" -d "/tmp/cmdline-tools"
    mkdir -p "$ANDROID_HOME/cmdline-tools/latest"
    mv /tmp/cmdline-tools/cmdline-tools/* "$ANDROID_HOME/cmdline-tools/latest/"
    rm -rf "$CMDLINE_ZIP" /tmp/cmdline-tools
fi

# Export Android Paths
export ANDROID_HOME="$ANDROID_HOME"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"

# Accept SDK licenses & install build tools/NDK
yes | sdkmanager --licenses || true
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0" "ndk;26.1.10909125"

# Environment Variable Exports to Shell RC files
SHELL_RC="$HOME/.bashrc"
if [ -f "$HOME/.zshrc" ]; then SHELL_RC="$HOME/.zshrc"; fi

if ! grep -q "ANDROID_HOME" "$SHELL_RC"; then
    cat << EOF >> "$SHELL_RC"

# Android SDK & Rust NDK Environment
export ANDROID_HOME="\$HOME/Android/Sdk"
export NDK_HOME="\$ANDROID_HOME/ndk/26.1.10909125"
export PATH="\$PATH:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$ANDROID_HOME/emulator"
EOF
fi

# --------------------------------------------------------------------
# 8. Web Services & Database Tools (Nginx, PostgreSQL, Postman)
# --------------------------------------------------------------------
echo "🌐 Installing Nginx, PostgreSQL, and Postman..."
sudo apt install -y nginx postgresql postgresql-contrib
if ! command -v postman &> /dev/null; then
    sudo snap install postman
fi

# Configure Postgres dev user matching system user
sudo -u postgres psql -c "CREATE USER $USER WITH SUPERUSER PASSWORD 'postgres';" 2>/dev/null || true
sudo -u postgres createdb "$USER" 2>/dev/null || true

# --------------------------------------------------------------------
# 9. Media Download Wrappers
# --------------------------------------------------------------------
echo "🎥 Provisioning yt-dlp execution wrappers..."
sudo apt install -y yt-dlp

create_wrapper() {
    local name="$1"
    local script_content="$2"
    echo "$script_content" | sudo tee "/usr/local/bin/$name" > /dev/null
    sudo chmod +x "/usr/local/bin/$name"
}

create_wrapper "audio" '#!/bin/bash
yt-dlp -x --audio-format mp3 --audio-quality 0 -P "$HOME/Music" "$1"'

create_wrapper "video" '#!/bin/bash
yt-dlp -f "bv+ba/b" -P "$HOME/Videos" --merge-output-format mp4 "$1"'

create_wrapper "playlist" '#!/bin/bash
yt-dlp -f "bv+ba/b" -P "$HOME/Videos" --yes-playlist -o "%(playlist_title)s/%(playlist_index)s - %(title)s.%(ext)s" "$1"'

create_wrapper "reel" '#!/bin/bash
yt-dlp -f "bv*[vcodec^=avc1]+ba[acodec^=mp4a]/b" -P "$HOME/Videos/reels" "$1"'

# --------------------------------------------------------------------
# Verification & Diagnostics
# --------------------------------------------------------------------
echo "================================================================"
echo "✅ Machine Provisioning Complete!"
echo "================================================================"
echo "Tool Versions Installed:"
rustc --version
cargo --version
dx --version
sqlx --version
probe-rs --version
nginx -v
psql --version
echo "--------------------------------------------------------"
echo "⚠️ ACTION REQUIRED:"
echo "1. Log out and log back in (or reboot) for user group changes (dialout/plugdev) to take effect."
echo "2. Add your SSH Public Key above to your GitHub Account."
echo "3. Run 'source ~/.bashrc' or restart your terminal."
echo "================================================================"
