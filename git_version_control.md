# Git Version Control System 👾

*Version controlling without using github.*

---

#### 🔗 Git Server SetUp

Git Server is a remote server where your entire codebase resides with all the versions. The real difference is in the url and authentication system. When you host your project on github, it becomes something like:
  
`https://github.com/username/codebase-name.git`

What we are building, it's url will be like:
  
`ssh://user@ip_address:/srv/git/codebase-name.git`

Log into server, then run below commands:

```bash
sudo mkdir -p /srv/git    # you can use /opt/git folder
sudo chown -R user:user /srv/git
sudo chown -R user:user /srv/git/*
sudo chmod 775 /srv/git


# Initialize bare git repository
sudo git init --bare /srv/git/repo.git
cd /srv/git/repo.git && git branch -m main && cd ~
```

If you want to auto-deploy your code with every push, then edit `sudo nano /srv/git/repo.git/hooks/post-receive` file:

```bash
#!/bin/bash
set -e

# ===== CONFIG =====
REPO_NAME="repo_name"
USER_NAME="username"
DEPLOY_DIR="/home/${USER_NAME}/${REPO_NAME}"
GIT_DIR="/home/${USER_NAME}/github/${REPO_NAME}.git"
SERVICE_NAME="${REPO_NAME}.service"
BRANCH="main"
VENV_DIR="${DEPLOY_DIR}/venv"
PYTHON="${VENV_DIR}/bin/python"
PIP="${VENV_DIR}/bin/pip"
# ==================

echo "🚀 Deploying ${REPO_NAME} to ${DEPLOY_DIR}"

# Ensure deploy directory exists
mkdir -p "${DEPLOY_DIR}"

# Checkout latest code into working tree
git --work-tree="${DEPLOY_DIR}" --git-dir="${GIT_DIR}" checkout -f "${BRANCH}"

cd "${DEPLOY_DIR}"

# Activate virtual environment
if [ ! -d "${VENV_DIR}" ]; then
    echo "❌ Virtualenv not found at ${VENV_DIR}"
    python3 -m venv venv
fi

echo "📦 Installing dependencies"
"${PIP}" install -r requirements.txt

echo "🎨 Collecting static files"
"${PYTHON}" manage.py collectstatic --noinput

echo "🧩 Running migrations"
"${PYTHON}" manage.py makemigrations --noinput

echo "🧩 Running migrations"
"${PYTHON}" manage.py migrate --noinput

# Reload daemon
echo "🔄 Reloading daemon"
sudo systemctl daemon-reload

# Restart service (NO sudo in hooks)
echo "🔄 Restarting ${SERVICE_NAME}"
sudo systemctl restart "${SERVICE_NAME}"

echo "✅ Deployment completed successfully"
```

Make this script executable:

```bash
sudo chmod +x /srv/git/repo.git/hooks/post-receive
```

Make sure systemctl runs without password by user `sudo visudo`:

```bash
user ALL=(root) NOPASSWD: /bin/systemctl
```

---

#### 🔗 Git Local SetUp

Add `.gitignore` file to your git repo:

```bash
__pycache__/
*/__pycache__/
*.py[cod]
*$py.class
venv/
env/
.venv/
.vscode/
.idea/
*.sublime-workspace
*.sublime-project
.env
*.env
*.key
*.pem
*.cert
secrets.json
*.log
media/
staticfiles/
db.sqlite3
local_settings.py
*.sock
*.service
dist/
build/
*.bak
*.swp
*.tmp
*.sql
*.sqlite3
*.db
pytest_cache/
*.cache/
.cache/
```

Initialize git repository and configure:

```bash
git init
git branch -m main
git remote add origin ssh://user@ip_address:/srv/git/codebase-name.git


# If github is the origin you want ...
git remote add production ssh://user@ip_address:/srv/git/codebase-name.git


# If origin already exists ...
git remote set-url origin ssh://user@ip_address:/srv/git/codebase-name.git
```

Check if everything's okay:

```bash
git remote -v    # It rerurns all the remote git repo server url
git add . && git commit -m "New update - feature added" && git push origin main
```

You are all-set.

---

# Conclusion 🔴
  
This is a minimal CI/CD pipeline that I follow. Suggest improvements via email/forking.
  
@2025 All Rights Reserved . Tanvir Saklan
