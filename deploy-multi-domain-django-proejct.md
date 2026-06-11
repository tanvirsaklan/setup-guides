Below is a **clean, production-grade setup** for using **Django + django-hosts behind Nginx**, where **each subdomain maps to a Django app**.

This assumes:

* **One Django project**
* **Multiple subdomains** (`www`, `api`, `blog`, etc.)
* **Nginx handles traffic**, Django handles subdomain routing

---

## 1️⃣ Architecture overview

```
client
  ↓
Nginx (subdomains)
  ↓
Django (django-hosts)
  ↓
App URLs
```

Nginx **does NOT route apps** — it only forwards requests.
`django-hosts` decides which app handles each subdomain.

---

## 2️⃣ DNS configuration

Make sure DNS points all subdomains to your server:

```
example.com      → SERVER_IP
*.example.com    → SERVER_IP
```

---

## 3️⃣ Nginx configuration (IMPORTANT)

### Single server block (recommended)

```nginx
server {
    listen 80;
    server_name example.com *.example.com;

    client_max_body_size 20M;

    location /static/ {
        alias /var/www/project/static/;
    }

    location /media/ {
        alias /var/www/project/media/;
    }

    location / {
        proxy_set_header Host $host;  # CRITICAL
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        proxy_pass http://unix:/run/gunicorn.sock;
    }
}
```

### ⚠️ Why `Host $host` matters

`django-hosts` relies on the **Host header** to detect subdomains.
If this is missing → **django-hosts will break**.

---

## 4️⃣ Gunicorn (example)

```bash
gunicorn project.wsgi:application \
  --bind unix:/run/gunicorn.sock \
  --workers 3
```

---

## 5️⃣ Django settings

### Install app

```bash
pip install django-hosts
```

---

### `settings.py`

```python
INSTALLED_APPS = [
    'django_hosts',
    ...
]

MIDDLEWARE = [
    'django_hosts.middleware.HostsRequestMiddleware',
    ...
    'django_hosts.middleware.HostsResponseMiddleware',
]

ROOT_URLCONF = 'project.urls'
ROOT_HOSTCONF = 'project.hosts'
DEFAULT_HOST = 'www'

ALLOWED_HOSTS = [
    'example.com',
    '.example.com',
]
```

---

## 6️⃣ Subdomain routing (`hosts.py`)

### `project/hosts.py`

```python
from django_hosts import patterns, host

host_patterns = patterns(
    '',
    host(r'www', 'main_app.urls', name='www'),
    host(r'api', 'api_app.urls', name='api'),
    host(r'blog', 'blog_app.urls', name='blog'),
)
```

---

## 7️⃣ App URLs

### `api_app/urls.py`

```python
from django.urls import path
from . import views

urlpatterns = [
    path('', views.index),
    path('users/', views.users),
]
```

Now:

* `api.example.com/` → `api_app`
* `blog.example.com/` → `blog_app`

---

## 8️⃣ HTTPS (Let’s Encrypt)

### Certbot

```bash
sudo certbot --nginx -d example.com -d '*.example.com'
```

### HTTPS Nginx block

```nginx
server {
    listen 443 ssl;
    server_name example.com *.example.com;

    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

    location / {
        proxy_set_header Host $host;
        proxy_pass http://unix:/run/gunicorn.sock;
    }
}
```

---

## 9️⃣ Static files (important)

```bash
python manage.py collectstatic
```

Ensure Nginx serves static files, not Django.

---

## 🔐 Cookies & auth across subdomains (optional)

```python
SESSION_COOKIE_DOMAIN = ".example.com"
CSRF_COOKIE_DOMAIN = ".example.com"
```

Now login works across subdomains.

---

## 10️⃣ Common issues & fixes

### ❌ 404 on subdomains

✔ Check `server_name *.example.com`
✔ Check `proxy_set_header Host $host`

---

### ❌ django-hosts not routing

✔ `HostsRequestMiddleware` must be FIRST
✔ `HostsResponseMiddleware` must be LAST

---

### ❌ Infinite redirects

✔ HTTPS settings consistent
✔ `SECURE_PROXY_SSL_HEADER`

```python
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
```