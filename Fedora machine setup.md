Fedora machine setup:

### Python 
It is pre-installed.

### Github setup:

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"

cat ~/.ssh/id_ed25519.pub
# Copy the output and paste it to the Account > New ssh key

git config --global user.name "Your Name"

git config --global user.email "your_email@example.com"

git config --global url."git@github.com:".insteadOf "https://github.com/"
```

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
 
### Setup yt-dlp:

```bash
sudo dnf install yt-dlp
```

`sudo nano /usr/bin/audio` :

```bash
#!/bin/bash
# Extracts highest quality audio as MP3 to ~/Videos
yt-dlp -x --audio-format mp3 --audio-quality 0 -P "~/Music" "$1"
```

`sudo nano /usr/bin/video` :

```bash
#!/bin/bash
# Downloads a single video to ~/Videos
yt-dlp -f 'bv+ba/b' -P "~/Videos" --merge-output-format mp4 "$1"
```

`sudo nano /usr/bin/playlist` :

```bash
#!/bin/bash
# Downloads a playlist into its own subfolder in ~/Videos
yt-dlp -f 'bv+ba/b' -P "~/Videos" --yes-playlist \
-o "%(playlist_title)s/%(playlist_index)s - %(title)s.%(ext)s" "$1"
```


### Git custom commit message

```bash
mkdir -p ~/.config/git/hooks
git config --global core.hooksPath ~/.config/git/hooks
nano ~/.config/git/hooks/prepare-commit-msg

#########################################

#!/bin/bash

COMMIT_MSG_FILE=$1
COMMIT_SOURCE=$2

# Intercept command line (-m) or standard editor commits
if [ "$COMMIT_SOURCE" = "message" ] || [ -z "$COMMIT_SOURCE" ]; then
    TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
    GIT_USER=$(git config user.name)
    GIT_USER=${GIT_USER:-"UnknownUser"}
    ORIGINAL_MSG=$(cat "$COMMIT_MSG_FILE")
    
    # Prevent duplicate prepending
    if [[ ! "$ORIGINAL_MSG" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2} ]]; then
        NEW_MSG="${TIMESTAMP}: ${GIT_USER}: ${ORIGINAL_MSG}"
        echo "$NEW_MSG" > "$COMMIT_MSG_FILE"
    fi
fi

##########################################

chmod +x ~/.config/git/hooks/prepare-commit-msg
# Use `git commit -m "Commit message" --no-verify` while message formatting is not preferable.
```
