#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "🚀 Starting automated Ubuntu machine setup..."

# --------------------------------------------------------------------
# 1. System Updates & Prerequisites
# --------------------------------------------------------------------
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl gcc git build-essential libssl-dev pkg-config nano

# --------------------------------------------------------------------
# 2. GitHub Setup & SSH Key Generation
# --------------------------------------------------------------------
echo "🔑 Setting up GitHub SSH & global config..."
# Reads inputs interactively at runtime so you don't have to hardcode them
read -p "Enter your GitHub email address: " GH_EMAIL
read -p "Enter your Git user.name: " GH_NAME

ssh-keygen -t ed25519 -C "$GH_EMAIL" -N "" -f ~/.ssh/id_ed25519

git config --global user.name "$GH_NAME"
git config --global user.email "$GH_EMAIL"
git config --global url."git@github.com:".insteadOf "https://github.com/"

# Print the public key right away so you can add it to GitHub immediately
echo "--------------------------------------------------------"
echo "👉 COPY THIS SSH PUBLIC KEY TO YOUR GITHUB ACCOUNT:"
cat ~/.ssh/id_ed25519.pub
echo "--------------------------------------------------------"

# --------------------------------------------------------------------
# 3. Global Git Hook (Custom Commit Format)
# --------------------------------------------------------------------
echo "🛠️ Provisioning global custom Git commit hook..."
mkdir -p ~/.config/git/hooks
git config --global core.hooksPath ~/.config/git/hooks

cat << 'EOF' > ~/.config/git/hooks/prepare-commit-msg
#!/bin/bash
COMMIT_MSG_FILE=$1
COMMIT_SOURCE=$2

if [ "$COMMIT_SOURCE" = "message" ] || [ -z "$COMMIT_SOURCE" ]; then
    TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
    GIT_USER=$(git config user.name)
    GIT_USER=${GIT_USER:-"UnknownUser"}
    ORIGINAL_MSG=$(cat "$COMMIT_MSG_FILE")
    
    if [[ ! "$ORIGINAL_MSG" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2} ]]; then
        NEW_MSG="${TIMESTAMP}: ${GIT_USER}: ${ORIGINAL_MSG}"
        echo "$NEW_MSG" > "$COMMIT_MSG_FILE"
    fi
fi
EOF

chmod +x ~/.config/git/hooks/prepare-commit-msg

# --------------------------------------------------------------------
# 4. Zed Text Editor Installation
# --------------------------------------------------------------------
echo "⚡ Installing Zed text-editor..."
curl -f https://zed.dev/install.sh | sh

# --------------------------------------------------------------------
# 5. Rust Toolchain Installation (For Web & Embedded Dev)
# --------------------------------------------------------------------
echo "🦀 Installing Rust development toolchain..."
if ! command -v rustup &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    # Source environment variables for the current execution flow
    source "$HOME/.cargo/env"
fi

# --------------------------------------------------------------------
# 6. Nginx & Deployment Essentials
# --------------------------------------------------------------------
echo "🌐 Installing Nginx..."
sudo apt install -y nginx

# --------------------------------------------------------------------
# 7. Media Download Stack (yt-dlp) & Custom Global Binary Wrappers
# --------------------------------------------------------------------
echo "🎥 Installing yt-dlp and provisioning execution commands..."
sudo apt install -y yt-dlp

# Write /usr/bin/audio
sudo cat << 'EOF' > /tmp/audio
#!/bin/bash
yt-dlp -x --audio-format mp3 --audio-quality 0 -P "~/Music" "$1"
EOF
sudo mv /tmp/audio /usr/bin/audio
sudo chmod +x /usr/bin/audio

# Write /usr/bin/video
sudo cat << 'EOF' > /tmp/video
#!/bin/bash
yt-dlp -f 'bv+ba/b' -P "~/Videos" --merge-output-format mp4 "$1"
EOF
sudo mv /tmp/video /usr/bin/video
sudo chmod +x /usr/bin/video

# Write /usr/bin/playlist
sudo cat << 'EOF' > /tmp/playlist
#!/bin/bash
yt-dlp -f 'bv+ba/b' -P "~/Videos" --yes-playlist -o "%(playlist_title)s/%(playlist_index)s - %(title)s.%(ext)s" "$1"
EOF
sudo mv /tmp/playlist /usr/bin/playlist
sudo chmod +x /usr/bin/playlist

# Write /usr/bin/reel
sudo cat << 'EOF' > /tmp/reel
#!/bin/bash
yt-dlp -f "bv*[vcodec^=avc1]+ba[acodec^=mp4a]/b" -P "~/Videos/reels" $1
EOF
sudo mv /tmp/reel /usr/bin/reel
sudo chmod +x /usr/bin/reel


# ==============================================================================
# PostgreSQL install
# ==============================================================================
echo "Installing Postgresql"
sudo apt install postgresql postgresql-contrib
echo "Postgresql successfully installed"

# ==============================================================================
# PostgreSQL install
# ==============================================================================
echo "Installing Postman"
sudo snap install postman
echo "Postman successfully installed"



echo "✅ Machine setup successful! Verify tool versions below:"
rustc --version
cargo --version
nginx -v
psql --version
