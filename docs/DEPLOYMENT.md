# Deployment Guide

Complete guide for deploying HeyIm to production on macOS.

## Prerequisites

- macOS 13.1+ (Ventura or later)
- Sudo access
- Cloudflare account (for tunnel - optional)
- Domain name (optional)

## Quick Deploy (launchd)

The fastest way to deploy is using our automated script:

```bash
cd HeyIm/deploy
sudo ./deploy.sh
```

This will:
1. Build release versions
2. Install launchd daemons
3. Configure auto-restart
4. Set up logging
5. Start services

## Manual Deployment

### 1. Build Release Versions

**Backend:**
```bash
cd backend
swift build -c release
```

**Frontend:**
```bash
cd frontend
npm install
npm run build
```

### 2. Create Service Users (Optional)

For better security, run services as dedicated users:

```bash
sudo dscl . -create /Users/_heyim
sudo dscl . -create /Users/_heyim UserShell /usr/bin/false
sudo dscl . -create /Users/_heyim RealName "HeyIm Service"
sudo dscl . -create /Users/_heyim UniqueID 505
sudo dscl . -create /Users/_heyim PrimaryGroupID 20
```

### 3. Install launchd Daemons

**Backend daemon (`/Library/LaunchDaemons/com.heyim.backend.plist`):**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.heyim.backend</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/mac/HeyIm/backend/.build/release/HeyImServer</string>
    </array>
    <key>WorkingDirectory</key>
    <string>/Users/mac/HeyIm/backend</string>
    <key>StandardOutPath</key>
    <string>/Users/mac/HeyIm/logs/backend.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/mac/HeyIm/logs/backend-error.log</string>
    <key>KeepAlive</key>
    <true/>
    <key>RunAtLoad</key>
    <true/>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PORT</key>
        <string>5858</string>
    </dict>
</dict>
</plist>
```

**Frontend daemon (`/Library/LaunchDaemons/com.heyim.frontend.plist`):**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.heyim.frontend</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/npm</string>
        <string>start</string>
    </array>
    <key>WorkingDirectory</key>
    <string>/Users/mac/HeyIm/frontend</string>
    <key>StandardOutPath</key>
    <string>/Users/mac/HeyIm/logs/frontend.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/mac/HeyIm/logs/frontend-error.log</string>
    <key>KeepAlive</key>
    <true/>
    <key>RunAtLoad</key>
    <true/>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PORT</key>
        <string>5859</string>
        <key>NODE_ENV</key>
        <string>production</string>
    </dict>
</dict>
</plist>
```

**Load daemons:**

```bash
sudo launchctl load /Library/LaunchDaemons/com.heyim.backend.plist
sudo launchctl load /Library/LaunchDaemons/com.heyim.frontend.plist
```

### 4. Verify Services

```bash
# Check if processes are running
ps aux | grep HeyImServer
ps aux | grep "next start"

# Test backend
curl http://localhost:5858/health

# Test frontend
curl http://localhost:5859
```

## Cloudflare Tunnel Setup

### 1. Install Cloudflare Tunnel

```bash
brew install cloudflare/cloudflare/cloudflared
```

### 2. Login to Cloudflare

```bash
cloudflared tunnel login
```

### 3. Create Tunnel

```bash
cloudflared tunnel create heyim
```

### 4. Configure Tunnel

Edit `~/.cloudflared/config.yml`:

```yaml
tunnel: <your-tunnel-id>
credentials-file: /Users/mac/.cloudflared/<your-tunnel-id>.json

ingress:
  - hostname: heyim.yourdomain.com
    service: http://localhost:5859
  - service: http_status:404
```

### 5. Route DNS

```bash
cloudflared tunnel route dns heyim heyim.yourdomain.com
```

### 6. Run Tunnel

```bash
cloudflared tunnel run heyim
```

**Or install as service:**

```bash
sudo cloudflared service install
sudo launchctl start com.cloudflare.cloudflared
```

## Nginx Reverse Proxy (Alternative)

If you prefer Nginx over Cloudflare Tunnel:

### 1. Install Nginx

```bash
brew install nginx
```

### 2. Configure Nginx

Edit `/usr/local/etc/nginx/nginx.conf`:

```nginx
http {
    upstream backend {
        server localhost:5858;
    }
    
    upstream frontend {
        server localhost:5859;
    }
    
    server {
        listen 80;
        server_name heyim.yourdomain.com;
        
        # Frontend
        location / {
            proxy_pass http://frontend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
        }
        
        # Backend API
        location /api/ {
            proxy_pass http://backend/api/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            
            # Increase timeouts for long-running generations
            proxy_read_timeout 120s;
            proxy_send_timeout 120s;
        }
    }
}
```

### 3. Start Nginx

```bash
sudo nginx
# or with brew services
brew services start nginx
```

## SSL/HTTPS Setup

### With Cloudflare Tunnel

SSL is automatic with Cloudflare Tunnel. Just ensure:
- DNS points to Cloudflare
- SSL mode is "Full" or "Full (Strict)"

### With Nginx + Let's Encrypt

```bash
# Install certbot
brew install certbot

# Get certificate
sudo certbot certonly --webroot -w /usr/local/var/www -d heyim.yourdomain.com

# Update Nginx config to use SSL
server {
    listen 443 ssl http2;
    server_name heyim.yourdomain.com;
    
    ssl_certificate /etc/letsencrypt/live/heyim.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/heyim.yourdomain.com/privkey.pem;
    
    # ... rest of config
}
```

## Monitoring & Logs

### View Logs

```bash
# Backend logs
tail -f ~/HeyIm/logs/backend.log
tail -f ~/HeyIm/logs/backend-error.log

# Frontend logs
tail -f ~/HeyIm/logs/frontend.log
tail -f ~/HeyIm/logs/frontend-error.log
```

### Log Rotation

Create `/etc/newsyslog.d/heyim.conf`:

```
/Users/mac/HeyIm/logs/*.log    644  7    100  *    GZ
```

### Health Checks

Create a monitoring script:

```bash
#!/bin/bash
# /Users/mac/HeyIm/scripts/health_check.sh

BACKEND_URL="http://localhost:5858/health"
FRONTEND_URL="http://localhost:5859"

if ! curl -sf $BACKEND_URL > /dev/null; then
    echo "Backend is down!" | mail -s "HeyIm Alert" admin@yourdomain.com
fi

if ! curl -sf $FRONTEND_URL > /dev/null; then
    echo "Frontend is down!" | mail -s "HeyIm Alert" admin@yourdomain.com
fi
```

Add to crontab:
```bash
*/5 * * * * /Users/mac/HeyIm/scripts/health_check.sh
```

## Maintenance

### Updating the Application

```bash
cd ~/HeyIm
git pull

# Rebuild backend
cd backend
swift build -c release

# Rebuild frontend
cd ../frontend
npm install
npm run build

# Restart services
sudo launchctl stop com.heyim.backend
sudo launchctl stop com.heyim.frontend
sleep 2
sudo launchctl start com.heyim.backend
sudo launchctl start com.heyim.frontend
```

### Backup Important Data

```bash
# Backup script
#!/bin/bash
BACKUP_DIR="/Users/mac/backups/heyim-$(date +%Y%m%d)"
mkdir -p $BACKUP_DIR

# Backup config files
cp /Library/LaunchDaemons/com.heyim.*.plist $BACKUP_DIR/
cp ~/.cloudflared/config.yml $BACKUP_DIR/ 2>/dev/null || true

# Backup logs (last 7 days)
find ~/HeyIm/logs -mtime -7 -type f -exec cp {} $BACKUP_DIR/ \;

# Create tarball
tar -czf ${BACKUP_DIR}.tar.gz $BACKUP_DIR
rm -rf $BACKUP_DIR
```

## Troubleshooting

### Services Won't Start

```bash
# Check daemon status
sudo launchctl list | grep heyim

# Check for errors
sudo launchctl error com.heyim.backend
sudo launchctl error com.heyim.frontend

# Reload daemons
sudo launchctl unload /Library/LaunchDaemons/com.heyim.backend.plist
sudo launchctl load /Library/LaunchDaemons/com.heyim.backend.plist
```

### High Memory Usage

```bash
# Monitor memory
top -o MEM

# Restart services if needed
sudo launchctl stop com.heyim.backend
sleep 5
sudo launchctl start com.heyim.backend
```

### Port Already in Use

```bash
# Find process using port
lsof -ti:5858
lsof -ti:5859

# Kill if necessary
kill -9 $(lsof -ti:5858)
```

## Security Considerations

1. **Firewall**: Only expose ports 80/443 externally
2. **Rate Limiting**: Implement rate limiting in Nginx
3. **Authentication**: Add auth layer for production use
4. **Model Security**: Keep model files read-only
5. **Log Sanitization**: Don't log sensitive user data

## Performance Tuning

### For High Load

- Increase file descriptors: `ulimit -n 4096`
- Enable HTTP/2 in Nginx
- Use CDN for static assets
- Add Redis for session management

### For Low Memory

- Reduce model precision (use quantized models)
- Limit concurrent generations
- Enable swap if needed

## Further Reading

- [launchd.plist man page](https://www.manpagez.com/man/5/launchd.plist/)
- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [Nginx Documentation](https://nginx.org/en/docs/)
