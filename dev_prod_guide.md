# Portfolio Website - Development & Production Guide

## 📋 Table of Contents
1. [Project Structure](#project-structure)
2. [Development Setup](#development-setup)
3. [Database Management](#database-management)
4. [Production Deployment](#production-deployment)
5. [Monitoring & Maintenance](#monitoring--maintenance)
6. [Troubleshooting](#troubleshooting)

---

## 🗂️ Project Structure

```
portfolio-website/
├── .env.example              # Environment variables template
├── .gitignore               # Git ignore rules
├── Cargo.toml               # Rust dependencies
├── docker-compose.yml       # Local development with Docker
├── migrations/
│   └── 001_init.sql        # Database schema
├── nginx/
│   └── portfolio.conf      # Nginx configuration
├── src/
│   ├── main.rs             # Application entry point
│   ├── config.rs           # Configuration management
│   ├── db.rs               # Database connection pool
│   ├── models.rs           # Data models
│   ├── handlers.rs         # Request handlers
│   └── routes.rs           # Route definitions
├── static/
│   ├── css/
│   ├── js/
│   └── media/
│       ├── images/
│       ├── scripts/
│       └── downloads/
└── templates/
    ├── index.html          # Homepage (your provided file)
    ├── resources.html      # Guidelines listing page
    └── guideline.html      # Individual guideline page
```

---

## 🚀 Development Setup

### Prerequisites

Before starting, ensure you have:
- **Rust 1.70+** - Install from https://rustup.rs
- **PostgreSQL 15+**
- **Git**
- **Node.js** (optional, for frontend tools)

### Step 1: Clone Repository

```bash
git clone https://github.com/yourusername/portfolio-website.git
cd portfolio-website
```

### Step 2: Install PostgreSQL

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

**macOS:**
```bash
brew install postgresql@15
brew services start postgresql@15
```

**Windows:**
Download from https://www.postgresql.org/download/windows/

### Step 3: Create Database

```bash
# Access PostgreSQL
sudo -u postgres psql

# In PostgreSQL shell:
CREATE DATABASE portfolio_db;
CREATE USER portfolio_user WITH ENCRYPTED PASSWORD 'dev_password123';
GRANT ALL PRIVILEGES ON DATABASE portfolio_db TO portfolio_user;

# Grant schema privileges (PostgreSQL 15+)
\c portfolio_db
GRANT ALL ON SCHEMA public TO portfolio_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO portfolio_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO portfolio_user;

\q
```

### Step 4: Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit .env file
nano .env
```

Update `.env` with your settings:
```bash
HOST=127.0.0.1
PORT=8080
RUST_LOG=debug
DATABASE_URL=postgresql://portfolio_user:dev_password123@localhost/portfolio_db
MAX_FILE_SIZE=104857600
```

### Step 5: Create Required Directories

```bash
mkdir -p static/media/{images,scripts,downloads}
mkdir -p templates
touch static/media/uploads/.gitkeep
```

### Step 6: Copy Your Homepage

Copy your provided HTML file:
```bash
# Copy your index.html to templates/
cp /path/to/your/index.html templates/index.html
```

### Step 7: Install Rust Dependencies & SQLx CLI

```bash
# Install SQLx CLI for database migrations
cargo install sqlx-cli --no-default-features --features postgres

# Check installation
sqlx --version
```

### Step 8: Run Database Migrations

```bash
# Run migrations
sqlx migrate run

# Verify tables were created
psql -U portfolio_user -d portfolio_db -c "\dt"
```

You should see:
```
             List of relations
 Schema |    Name    | Type  |     Owner      
--------+------------+-------+----------------
 public | guidelines | table | portfolio_user
 public | media_files| table | portfolio_user
```

### Step 9: Build and Run

```bash
# Development mode with auto-reload
cargo install cargo-watch
cargo watch -x run

# Or standard run
cargo run

# Production build
cargo build --release
./target/release/portfolio-website
```

Server will start at: **http://localhost:8080**

### Step 10: Verify Installation

Open your browser and test:
- Homepage: http://localhost:8080
- Resources: http://localhost:8080/resources
- Search: http://localhost:8080/search?q=python

---

## 🐳 Development with Docker (Alternative)

If you prefer Docker for local development:

```bash
# Start PostgreSQL with Docker Compose
docker-compose up -d

# Access database admin interface
# Open http://localhost:8081
# Server: postgres
# Username: portfolio_user
# Password: dev_password

# Run your Rust app
cargo run
```

---

## 💾 Database Management

### Add New Guideline

```sql
INSERT INTO guidelines (
    title, 
    slug, 
    category, 
    description, 
    markdown_content, 
    tags
) VALUES (
    'Linux Server Hardening',
    'linux-server-hardening',
    'Setup Guides',
    'Essential security configurations for Linux servers',
    '# Linux Server Hardening Guide

## SSH Configuration

Edit `/etc/ssh/sshd_config`:
```bash
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
```

Restart SSH:
```bash
sudo systemctl restart sshd
```

## Firewall Setup

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw enable
```',
    ARRAY['linux', 'security', 'server']
);
```

### Update Guideline

```sql
UPDATE guidelines 
SET 
    markdown_content = '# Updated content here...',
    updated_at = NOW()
WHERE slug = 'linux-server-hardening';
```

### Delete Guideline (Soft Delete)

```sql
-- Unpublish (recommended)
UPDATE guidelines 
SET is_published = false 
WHERE slug = 'linux-server-hardening';

-- Hard delete
DELETE FROM guidelines 
WHERE slug = 'linux-server-hardening';
```

### Query Guidelines

```sql
-- View all published guidelines
SELECT id, title, category, view_count 
FROM guidelines 
WHERE is_published = true 
ORDER BY created_at DESC;

-- Search guidelines
SELECT title, description 
FROM guidelines 
WHERE markdown_content ILIKE '%docker%' 
  AND is_published = true;

-- Group by category
SELECT category, COUNT(*) as count 
FROM guidelines 
WHERE is_published = true 
GROUP BY category;
```

### Add File Download to Guideline

```sql
-- First, place your file in static/media/downloads/
-- Then update the guideline:

UPDATE guidelines 
SET 
    download_url = '/static/media/downloads/automation-scripts.zip',
    file_size = 2457600,  -- in bytes
    file_path = 'automation-scripts.zip'
WHERE slug = 'python-automation-setup';
```

---

## 🌐 Production Deployment

### Server Requirements

- **OS**: Ubuntu 22.04 LTS (recommended)
- **RAM**: Minimum 2GB
- **Storage**: Minimum 20GB
- **Domain**: Configured and pointing to your server

### Step 1: Server Setup

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y build-essential pkg-config libssl-dev \
    postgresql postgresql-contrib nginx certbot python3-certbot-nginx \
    git curl

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
```

### Step 2: Create Application User

```bash
# Create user
sudo useradd -m -s /bin/bash portfolio
sudo passwd portfolio  # Set password

# Switch to portfolio user
sudo su - portfolio
```

### Step 3: Deploy Application

```bash
# As portfolio user
cd ~
git clone https://github.com/yourusername/portfolio-website.git
cd portfolio-website

# Copy environment file
cp .env.example .env
nano .env
```

Update `.env` for production:
```bash
HOST=127.0.0.1
PORT=8080
RUST_LOG=info
DATABASE_URL=postgresql://portfolio_user:STRONG_PASSWORD_HERE@localhost/portfolio_db
MAX_FILE_SIZE=104857600
ALLOWED_ORIGINS=https://yourdomain.com
```

### Step 4: Setup PostgreSQL for Production

```bash
# Exit portfolio user
exit

# As root/sudo user
sudo -u postgres psql

# Create production database
CREATE DATABASE portfolio_db;
CREATE USER portfolio_user WITH ENCRYPTED PASSWORD 'STRONG_RANDOM_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE portfolio_db TO portfolio_user;

\c portfolio_db
GRANT ALL ON SCHEMA public TO portfolio_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO portfolio_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO portfolio_user;

\q
```

### Step 5: Build Application

```bash
# Switch back to portfolio user
sudo su - portfolio
cd ~/portfolio-website

# Install SQLx CLI
cargo install sqlx-cli --no-default-features --features postgres

# Run migrations
sqlx migrate run

# Build release binary
cargo build --release

# Test the build
./target/release/portfolio-website
# Press Ctrl+C after verifying it starts
```

### Step 6: Create Systemd Service

```bash
# Exit portfolio user
exit

# Create service file
sudo nano /etc/systemd/system/portfolio.service
```

Copy the systemd service content (provided in separate artifact), then:

```bash
# Set correct permissions
sudo chmod 644 /etc/systemd/system/portfolio.service

# Reload systemd
sudo systemctl daemon-reload

# Enable service
sudo systemctl enable portfolio

# Start service
sudo systemctl start portfolio

# Check status
sudo systemctl status portfolio
```

### Step 7: Setup Nginx

```bash
# Create web root for static files
sudo mkdir -p /var/www/portfolio
sudo cp -r /home/portfolio/portfolio-website/static /var/www/portfolio/

# Set permissions
sudo chown -R www-data:www-data /var/www/portfolio

# Copy Nginx configuration
sudo cp /home/portfolio/portfolio-website/nginx/portfolio.conf \
    /etc/nginx/sites-available/portfolio

# Edit configuration
sudo nano /etc/nginx/sites-available/portfolio
# Replace 'yourdomain.com' with your actual domain

# Enable site
sudo ln -s /etc/nginx/sites-available/portfolio \
    /etc/nginx/sites-enabled/

# Remove default site (optional)
sudo rm /etc/nginx/sites-enabled/default

# Test configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
```

### Step 8: Setup SSL with Let's Encrypt

```bash
# Obtain SSL certificate
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com

# Follow prompts:
# - Enter email address
# - Agree to terms
# - Choose to redirect HTTP to HTTPS (option 2)

# Test auto-renewal
sudo certbot renew --dry-run
```

SSL certificates will auto-renew via systemd timer.

### Step 9: Configure Firewall

```bash
# Enable UFW
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable

# Check status
sudo ufw status
```

### Step 10: Test Production Site

Visit your domain:
- https://yourdomain.com
- https://yourdomain.com/resources

---

## 📊 Monitoring & Maintenance

### View Application Logs

```bash
# Real-time logs
sudo journalctl -u portfolio -f

# Last 100 lines
sudo journalctl -u portfolio -n 100

# Today's logs
sudo journalctl -u portfolio --since today

# Error logs only
sudo journalctl -u portfolio -p err
```

### View Nginx Logs

```bash
# Access logs
sudo tail -f /var/log/nginx/portfolio_access.log

# Error logs
sudo tail -f /var/log/nginx/portfolio_error.log

# Search for errors
sudo grep "error" /var/log/nginx/portfolio_error.log
```

### Restart Services

```bash
# Restart application
sudo systemctl restart portfolio

# Restart Nginx
sudo systemctl restart nginx

# Restart PostgreSQL
sudo systemctl restart postgresql
```

### Database Backup

```bash
# Create backup
sudo -u portfolio pg_dump -U portfolio_user portfolio_db > \
    backup_$(date +%Y%m%d_%H%M%S).sql

# Automated daily backups
sudo crontab -e
# Add this line:
0 2 * * * sudo -u portfolio pg_dump -U portfolio_user portfolio_db > /home/portfolio/backups/db_$(date +\%Y\%m\%d).sql
```

### Restore Database

```bash
# Restore from backup
sudo -u portfolio psql -U portfolio_user portfolio_db < backup_20240117_020000.sql
```

### Update Application

```bash
# As portfolio user
cd ~/portfolio-website
git pull origin main

# Rebuild
cargo build --release

# Restart service
exit
sudo systemctl restart portfolio
```

### Monitor System Resources

```bash
# CPU and Memory usage
htop

# Disk usage
df -h

# Database connections
sudo -u postgres psql -c "SELECT count(*) FROM pg_stat_activity;"
```

---

## 🔧 Troubleshooting

### Application Won't Start

**Check logs:**
```bash
sudo journalctl -u portfolio -n 50
```

**Common issues:**

1. **Port already in use:**
```bash
sudo netstat -tulpn | grep 8080
# Kill the process using port 8080
sudo kill -9 <PID>
```

2. **Database connection failed:**
```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Verify credentials in .env file
cat /home/portfolio/portfolio-website/.env

# Test connection
sudo -u portfolio psql -U portfolio_user -d portfolio_db
```

3. **Permission denied:**
```bash
# Fix ownership
sudo chown -R portfolio:portfolio /home/portfolio/portfolio-website
```

### Nginx Errors

**Test configuration:**
```bash
sudo nginx -t
```

**Common issues:**

1. **502 Bad Gateway:**
```bash
# Check if backend is running
sudo systemctl status portfolio

# Check Nginx error logs
sudo tail -f /var/log/nginx/error.log
```

2. **SSL certificate errors:**
```bash
# Renew certificate
sudo certbot renew --force-renewal

# Restart Nginx
sudo systemctl restart nginx
```

### Database Issues

**Can't connect to database:**
```bash
# Check PostgreSQL is running
sudo systemctl status postgresql

# Check if database exists
sudo -u postgres psql -l | grep portfolio_db

# Check user permissions
sudo -u postgres psql -c "\du portfolio_user"
```

**Migrations failed:**
```bash
# Check migration status
cd /home/portfolio/portfolio-website
sqlx migrate info

# Revert last migration
sqlx migrate revert

# Run migrations again
sqlx migrate run
```

### Performance Issues

**High memory usage:**
```bash
# Check PostgreSQL connections
sudo -u postgres psql -c "SELECT count(*) FROM pg_stat_activity;"

# Adjust max_connections in postgresql.conf
sudo nano /etc/postgresql/15/main/postgresql.conf
# Set: max_connections = 50

sudo systemctl restart postgresql
```

**Slow response times:**
```bash
# Check database query performance
sudo -u postgres psql portfolio_db
EXPLAIN ANALYZE SELECT * FROM guidelines WHERE is_published = true;

# Check Nginx cache
sudo nano /etc/nginx/nginx.conf
# Add proxy_cache configuration
```

### View Count Not Incrementing

```bash
# Check table permissions
sudo -u postgres psql portfolio_db
\dt+

# Grant permissions
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO portfolio_user;
```

---

## 🔒 Security Best Practices

### 1. Secure PostgreSQL

```bash
# Edit pg_hba.conf
sudo nano /etc/postgresql/15/main/pg_hba.conf

# Change to use md5 authentication:
local   all             all                                     md5
host    all             all             127.0.0.1/32            md5
```

### 2. Use Strong Passwords

```bash
# Generate strong password
openssl rand -base64 32
```

### 3. Regular Updates

```bash
# System updates
sudo apt update && sudo apt upgrade -y

# Rust updates
rustup update

# Dependency updates
cd ~/portfolio-website
cargo update
```

### 4. Enable Fail2Ban

```bash
sudo apt install fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### 5. Monitor Logs

Set up log rotation:
```bash
sudo nano /etc/logrotate.d/portfolio

/var/log/nginx/portfolio_*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 www-data adm
    sharedscripts
    postrotate
        [ -s /run/nginx.pid ] && kill -USR1 `cat /run/nginx.pid`
    endscript
}
```

---

## 📞 Support

For issues:
1. Check application logs
2. Check Nginx logs
3. Verify database connection
4. Review this troubleshooting guide

---

## ✅ Deployment Checklist

**Development:**
- [ ] PostgreSQL installed and running
- [ ] Database created with correct permissions
- [ ] .env file configured
- [ ] Dependencies installed
- [ ] Migrations run successfully
- [ ] Application starts without errors
- [ ] Can access homepage
- [ ] Can view resources page
- [ ] Can view individual guidelines

**Production:**
- [ ] Domain DNS configured
- [ ] Server secured (SSH keys, firewall)
- [ ] PostgreSQL configured for production
- [ ] Application built in release mode
- [ ] Systemd service created and enabled
- [ ] Nginx configured correctly
- [ ] SSL certificate obtained
- [ ] Static files served correctly
- [ ] Backups configured
- [ ] Monitoring in place
- [ ] Log rotation configured

---

**Your portfolio website is now ready for development and production! 🎉**