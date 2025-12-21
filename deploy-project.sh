#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# --- 1. Variables ---
USERNAME=$1
PROJECT_NAME=$2
DOMAIN_NAME=$3

# Use absolute paths (avoiding ~ which can fail under sudo)
PROJECT_DIRECTORY="/home/$USERNAME/$PROJECT_NAME"
PROJECT_ENV_FILE="$PROJECT_DIRECTORY/.env"
PGBOUNCER_CONF_FILE="/etc/pgbouncer/pgbouncer.ini"
PROJECT_DB="${PROJECT_NAME}_db"
DB_USER="${PROJECT_NAME}_user"
DB_PASS="${PROJECT_NAME}_password"
PGBOUNCER_NEW_ENTRY="$PROJECT_DB = host=127.0.0.1 port=5432 user=$DB_USER password=$DB_PASS"
SERVICE_FILE="/etc/systemd/system/${PROJECT_NAME}.service"
NGINX_CONF_FILE="/etc/nginx/sites-available/${PROJECT_NAME}"

# --- 2. Functions ---

check_args() {
    if [ -z "$USERNAME" ] || [ -z "$PROJECT_NAME" ] || [ -z "$DOMAIN_NAME" ]; then
        echo "Usage: $0 [linux_user] [project_name] [domain_name]"
        exit 1
    fi
}

update_and_install_packages() {
    echo "Updating system and installing dependencies..."
    sudo apt update -qq
    sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -qq
    sudo apt install -y python3 python3-venv python3-pip python3-dev libpq-dev curl git gunicorn postgresql postgresql-contrib pgbouncer nginx certbot python3-certbot-nginx
}

setup_database() {
    echo "Setting up PostgreSQL..."
    # Create DB only if it doesn't exist
    if ! sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$PROJECT_DB"; then
        sudo -u postgres psql -c "CREATE DATABASE $PROJECT_DB;"
        sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
        sudo -u postgres psql -c "ALTER ROLE $DB_USER SET client_encoding TO 'utf8';"
        sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $PROJECT_DB TO $DB_USER;"
        sudo -u postgres psql -c "ALTER DATABASE $PROJECT_DB OWNER TO $DB_USER;"
    else
        echo "Database $PROJECT_DB already exists. Skipping creation."
    fi
}

setup_pgbouncer() {
    echo "Configuring PgBouncer..."
    if ! sudo grep -q "$PROJECT_DB =" "$PGBOUNCER_CONF_FILE"; then
        sudo sed -i "/\[databases\]/a $PGBOUNCER_NEW_ENTRY" "$PGBOUNCER_CONF_FILE"
        echo "\"$DB_USER\" \"$DB_PASS\"" | sudo tee -a /etc/pgbouncer/userlist.txt
        sudo systemctl restart pgbouncer
    else
        echo "PgBouncer entry already exists."
    fi
}

# --- 3. Execution ---

check_args

if [ -d "$PROJECT_DIRECTORY" ]; then
    update_and_install_packages
    setup_database
    setup_pgbouncer

    # Ensure the User home is traversable by Nginx
    sudo chmod 755 "/home/$USERNAME"

    cd "$PROJECT_DIRECTORY"
    
    echo "Setting up Virtual Environment..."
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt gunicorn psycopg2-binary

    echo "Creating .env file..."
    cat << EOF > "$PROJECT_ENV_FILE"
DEBUG="False"
SECRET_KEY="$(openssl rand -base64 38)"
ALLOWED_HOSTS="$DOMAIN_NAME,www.$DOMAIN_NAME,localhost,127.0.0.1"
CSRF_TRUSTED_ORIGINS="https://$DOMAIN_NAME,https://www.$DOMAIN_NAME"
DB_NAME="$PROJECT_DB"
DB_USER="$DB_USER"
DB_PASSWORD="$DB_PASS"
DB_HOST="127.0.0.1"
DB_PORT="6432"
EOF
    chmod 600 "$PROJECT_ENV_FILE"

    echo "Running Django Migrations..."
    python3 manage.py collectstatic --noinput
    python3 manage.py makemigarations
    python3 manage.py migrate

    mkdir -p logs
    touch logs/gunicorn-access.log logs/gunicorn-error.log

    echo "Configuring Systemd..."
    sudo bash -c "cat << EOF > $SERVICE_FILE
[Unit]
Description=Gunicorn instance for $PROJECT_NAME
After=network.target

[Service]
User=$USERNAME
Group=www-data
WorkingDirectory=$PROJECT_DIRECTORY
RuntimeDirectory=gunicorn
ExecStart=$PROJECT_DIRECTORY/venv/bin/gunicorn \\
    --access-logfile $PROJECT_DIRECTORY/logs/gunicorn-access.log \\
    --error-logfile $PROJECT_DIRECTORY/logs/gunicorn-error.log \\
    --workers 3 \\
    --bind unix:$PROJECT_DIRECTORY/$PROJECT_NAME.sock \\
    $PROJECT_NAME.wsgi:application
Restart=always

[Install]
WantedBy=multi-user.target
EOF"

    sudo systemctl daemon-reload
    sudo systemctl enable "$PROJECT_NAME"
    sudo systemctl start "$PROJECT_NAME"

    echo "Configuring Nginx..."
    sudo bash -c "cat << EOF > $NGINX_CONF_FILE
server {
    listen 80;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME;

    location = /favicon.ico { access_log off; log_not_found off; }
    
    location /static/ {
        alias $PROJECT_DIRECTORY/static;
        expires 30d;
    }

    location /media/ {
        alias $PROJECT_DIRECTORY/media;
        expires 30d;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:$PROJECT_DIRECTORY/$PROJECT_NAME.sock;
    }
}
EOF"

    sudo ln -sf "$NGINX_CONF_FILE" "/etc/nginx/sites-enabled/"
    sudo nginx -t
    sudo systemctl restart nginx

    echo "Setting up SSL..."
    sudo certbot --nginx -d "$DOMAIN_NAME" -d "www.$DOMAIN_NAME" --non-interactive --agree-tos -m "admin@$DOMAIN_NAME" || echo "SSL setup failed. Check domain propagation."

    echo "Deployment successful for $PROJECT_NAME at https://$DOMAIN_NAME"

else
    echo "Error: Directory $PROJECT_DIRECTORY not found. Please clone your repo first."
    exit 1
fi