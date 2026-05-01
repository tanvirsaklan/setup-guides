# ⚙️ GUIDE TO SET UP CLOUDFLARE IN RASPBERY PI5 🖥️

---

### 📌 Install & Authenticate Cloudflare

**Pre-requisites**
  
- You have an account in cloudflare.
- You have migrated your domain or domain's nameserver into cloudflare.
  

```bash
curl -fsSL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb -o cloudflared.deb
sudo dpkg -i cloudflared.deb
cloudflared --version
```
  
Login (tunnel):
  
```bash
cloudflared tunnel login
```
  
You will see a link, click on that. You don't really need a monitor connected to pi5. You can open the link even when you are connected via `ssh`.

1. Click on the link, open in a browser.
2. Select the domain you want to access.

You will see tunnel is authenticated.

### 📌 Create Tunnel

```bash
cloudflared tunnel create <tunnel_name>
```
This will output like:

```yaml
Tunnel ID: a1b2c3d4-e5f6-7890-abcd-123456789000
```

Save the id.

### 📌 Create the Config File

```bash
sudo mkdir -p /etc/cloudflared
sudo nano /etc/cloudflared/config.yml
```

Paste:

```yaml
tunnel: <tunnel_id>
credentials-file: /root/.cloudflared/<tunnel_id>.json
# OR
# credentials-file: /home/username/.cloudflared/<tunnel_id>.json

# Mind the spaces are two, neither four nor one TAB.

ingress:
  # Public SSH, you can skip. Not Necessary.
  # It will enable you to login to pi5 using "ssh ssh.your-domain.extension"
  - hostname: ssh.your-domain.extension
    service: ssh://localhost:22

  - hostname: your-domain.extension
    service: http://localhost:8000

  # If you want to add subdomain routing, else ignore this block.
  - hostname: subdomain.your-domain.extension
    service: http://localhost:8001

  # Add as many sub-domains as you want, just change the port numbers (8002,8003...)

  # Default fallback; Required - else error will occur
  - service: http_status:404
```
Save.

### 📌 Create DNS Records in Cloudflare

Run (one-by-one):

```bash
cloudflared tunnel route dns <tunnel_name> ssh.your-domain.extension
cloudflared tunnel route dns <tunnel_name> your-domain.extension
cloudflared tunnel route dns <tunnel_name> subdomain.your-domain.extension
```

This creates automatic CNAMEs in your cloudflare settings:

```php-template
ssh → <tunnelID>.cfargotunnel.com
@ → <tunnelID>.cfargotunnel.com
subdomain → <tunnelID>.cfargotunnel.com
```

### 📌 Run tunnel as system service

```bash
sudo cloudflared service install
# You may see error, because service is installed during cloudflare install. Just ignore.

sudo systemctl enable cloudflared
sudo systemctl start cloudflared
sudo systemctl status cloudflared
```

### 📌 Conclusion

Cloudflare automatically adds ssl certificates. Don't need to manually add them. If not added automatically, go to dashboard and click on your domain. You can find them under `Security > Settings` section.
