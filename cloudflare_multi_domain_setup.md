# 📋 Cloudflare Multi-Domain Tunnel Support for Pi

---

#### 🔗 Prepare the Rasbery Pi or any SBC you are using
  
Open your terminal. Run these:

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install nginx python3-pip python3-venv git build-essential -y
```

Install cloudflared on `/home/user` folder *(recommended)*:

```bash
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb -o ~/cloudflared.deb
sudo dpkg -i ~/cloudflared.deb
```

Check installation:

```bash
cloudflared --version
```
Once installed, authenticate via a browser/headless:

```bash
cloudflared tunnel login
```
You will be given a link, open with your `Pi/SBC/Laptop` You may be asked to select a domain/zone or anything like that. Select and you are done for this step. 
  
You may have `.cloudflared` folder in the `/home/user/` folder, or in the `/root/` folder. Verify the file:

```bash
file ~/.cloudflared/cert.pem
# OR
file /root/.cloudflared/cert.pem

# IN CASE, ROOT FOLDER CERT.PEM
sudo mkdir -p ~/.cloudflared/
sudo cp /root/.cloudflared/cert.pem ~/.cloudflared/cert.pem
```
  
Now create a tunnel from terminal, browser is not needed:

```bash
cloudflared tunnel create <tunnel-name>
```

You will be given a UUID for the tunnel. You may copy the tunnel id. We will use that later. A file is created `~/.cloudflared/<tunnel-id>.json`
  
If not:

```bash
sudo cp /root/.cloudflared/* ~/.cloudflared/
```

Create configuration file:

```bash
sudo mkdir -p /etc/cloudflared
sudo nano /etc/cloudflared/config.yml
```
  
Place tunnel id where needed:

```bash
tunnel: <tunnel-id>
credentials-file: /home/user/.cloudflared/<tunnel-id>.json

ingress:
  - hostname: site1-domain.extension
    service: http://127.0.0.1:80

  - hostname: site2-domain.extension
    service: http://127.0.0.1:80

  # ADD AS MANY DOMAINS AS YOU WANT

  - service: http_status:404
```

Create a service file `sudo nano /etc/systemd/system/cloudflared.service` :

```bash
[Unit]
Description=cloudflared service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/cloudflared tunnel run <tunnel-name>
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```
Enable it:

```bash
sudo systemctl enable cloudflared
sudo systemctl restart cloudflared
```

You should see your tunnel status is `Healthy` in the browser.

---

#### 🔗 Prepare your django apps (Gunicorn/Uvicorn Workers)

Create a gunicorn service file: `sudo nano /etc/systemd/system/project.service`
  
*For Django Projects > > >*

```bash
[Unit]
Description=Gunicorn daemon for Django Project
After=network.target

[Service]
User=user
Group=user
WorkingDirectory=/home/user/project # WHERE YOUR APP RESIDES
RuntimeDirectory=project
ExecStart=/home/user/project/venv/bin/gunicorn --workers 4 --threads 2 --timeout 60 --bind unix:/home/user/project/project.sock project.wsgi:application
Restart=always
Environment="DJANGO_SETTINGS_MODULE=project.settings"
Environment="PYTHONUNBUFFERED=1"

[Install]
WantedBy=multi-user.target
```
  
*For FastAPI/Flask Projects > > >*

```bash
[Unit]
Description=Gunicorn instance to serve FastAPI Project
After=network.target postgresql.service

[Service]
User=user
Group=user
WorkingDirectory=/home/user/project
Environment="PATH=/home/user/project/venv/bin"
ExecStart=/home/user/project/venv/bin/gunicorn --bind 127.0.0.1:8001 --workers 4 app:app
ExecReload=/bin/kill -s HUP $MAINPID
Restart=always

[Install]
WantedBy=multi-user.target
```
We are using 8001, 8002, 8003 ... ports for flask/fastapi projects. You can use socket files for them also.
  
Register this service file:

```bash
sudo systemctl daemon-reload
sudo systemctl start project.service
sudo systemctl enable project.service
sudo systemctl status project.service
```

You should see `status: active (running)`. If not, most common problems occur that the socket file is not created.
  
Correct the permissions:

```bash
sudo chown -R user:user /home/user/project
sudo chmod 600 /home/user/project/project.sock
```

---

#### 🔗 Prepare your apps (Nginx Workers)

Create nginx conf files for projects: `sudo nano /etc/nginx/sites-available/project`
  
*For Django Projects > > >*

```bash
server{
    listen 127.0.0.1:80;
    server_name site-domain.extension;
    client_max_body_size 999M;
    client_body_timeout 300s;
    send_timeout 300s;
    access_log /var/log/nginx/project.access.log;
    error_log /var/log/nginx/project.error.log;

    location = /favicon.ico { access_log off; log_not_found off; }

    location /static/ {
        alias /home/user/project/static/;
    }

    location /media/ {
        alias /home/user/project/media/;
        }

    location / {
        proxy_pass http://unix:/home/user/project/project.sock;
        include proxy_params;
    }
}
```

*For Flask/FastAPI Projects > > >*

```bash
# edit/change
proxy_pass http://127.0.0.1:8001; # adjust ports
```

Register the file to nginx:

```bash
sudo ln -s /etc/nginx/sites-available/project /etc/nginx/sites-enabled
sudo nginx -t
sudo systemctl restart nginx
```

Most common error is encountered is (Bad Request 400).
Check error logs:

```bash
tail -F /var/log/nginx/project.error.log
```

You may see nginx have a `Error (13): Permission Denied`
  
This causes because the `group` assigned to `project.sock` file is set to `user`
  
Edit nginx configuration file: `sudo nano /etc/nginx/nginx.conf`

```bash
user <user>;
worker_processes auto;
pid /run/nginx.pid;
error_log /var/log/nginx/error.log;
include /etc/nginx/modules-enabled/*.conf;

events {
    # ... remaining codes
}

http {
    # ... remaining codes
}
```

Restart the nginx. You should see nginx running good.

---

#### 🔗 Configure cloudflare dashboard

Go to cloudflare dashboard > Select domain > Add CNAME record:

```bash
CNAME ➡️ @ ➡️ <tunnel-id>.cfargotunnel.com ➡️ Proxied
# For sub-domain
CNAME ➡️ sub-domain ➡️ <tunnel-id>.cfargotunnel.com ➡️ Proxied
```

You are all good!

---

# Conclusion 🔴

@2025 All Rights Reserved . Tanvir Saklan
