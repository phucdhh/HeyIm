# HeyIm Deployment Guide

## Quick Start

### 1. Deploy Services

```bash
cd /Users/mac/HeyIm/deploy
./deploy.sh
```

This will:
- ✅ Check if builds exist
- ✅ Stop existing dev servers
- ✅ Install launchd daemons
- ✅ Start backend (port 5858) and frontend (port 3000)
- ✅ Run health checks

### 2. Configure Cloudflare Tunnel

**Backup current config:**
```bash
cp ~/.cloudflared/config.yml ~/.cloudflared/config.yml.backup
```

**Edit config:**
```bash
nano ~/.cloudflared/config.yml
```

Add this **BEFORE** the catch-all (`- service: http_status:404`):

```yaml
  # HeyIm AI Image Generation
  - hostname: heyim.truyenthong.edu.vn
    service: http://127.0.0.1:3000
    originRequest:
      noTLSVerify: false
      connectTimeout: 120s
      http2Origin: true
      keepAliveTimeout: 90s
      keepAliveConnections: 100
```

**Create DNS record:**
```bash
cloudflared tunnel route dns aithink heyim.truyenthong.edu.vn
```

**Restart cloudflared:**
```bash
sudo launchctl unload /Library/LaunchDaemons/com.cloudflare.cloudflared.plist
sudo launchctl load /Library/LaunchDaemons/com.cloudflare.cloudflared.plist
```

### 3. Test Deployment

**Check service status:**
```bash
./status.sh
```

**Test locally:**
```bash
curl http://localhost:5858/health
curl http://localhost:3000
```

**Test public domain:**
```bash
curl https://heyim.truyenthong.edu.vn
```

**Test image generation:**
```bash
curl -X POST http://localhost:5858/api/generate \
  -H "Content-Type: application/json" \
  -d '{"prompt": "a beautiful sunset", "steps": 30}'
```

## Management Commands

### Start Services
```bash
sudo launchctl load /Library/LaunchDaemons/com.heyim.backend.plist
sudo launchctl load /Library/LaunchDaemons/com.heyim.frontend.plist
```

### Stop Services
```bash
./stop.sh
# or manually:
sudo launchctl unload /Library/LaunchDaemons/com.heyim.backend.plist
sudo launchctl unload /Library/LaunchDaemons/com.heyim.frontend.plist
```

### Restart Services
```bash
./restart.sh
```

### Check Status
```bash
./status.sh
```

### View Logs
```bash
# Backend logs
tail -f /Users/mac/HeyIm/logs/backend.log
tail -f /Users/mac/HeyIm/logs/backend-error.log

# Frontend logs
tail -f /Users/mac/HeyIm/logs/frontend.log
tail -f /Users/mac/HeyIm/logs/frontend-error.log

# All logs
tail -f /Users/mac/HeyIm/logs/*.log
```

## Troubleshooting

### Backend Won't Start

**Check logs:**
```bash
cat /Users/mac/HeyIm/logs/backend-error.log
```

**Common issues:**
- Models not found: Check MODEL_PATH in plist
- Port 5858 in use: `lsof -i :5858`
- Permission denied: Check file permissions

**Manual test:**
```bash
cd /Users/mac/HeyIm/backend
.build/release/HeyImServer
```

### Frontend Won't Start

**Check logs:**
```bash
cat /Users/mac/HeyIm/logs/frontend-error.log
```

**Common issues:**
- Build missing: Run `npm run build`
- Port 3000 in use: `lsof -i :3000`
- Node not found: Check PATH in plist

**Manual test:**
```bash
cd /Users/mac/HeyIm/frontend
npm run start
```

### Services Keep Restarting

**Check crash logs:**
```bash
grep -i "error" /Users/mac/HeyIm/logs/*.log
```

**Disable auto-restart temporarily:**
```bash
# Remove KeepAlive from plist, then:
sudo launchctl unload /Library/LaunchDaemons/com.heyim.backend.plist
sudo launchctl load /Library/LaunchDaemons/com.heyim.backend.plist
```

### Cloudflare Tunnel Issues

**Check tunnel status:**
```bash
cloudflared tunnel info aithink
```

**Check DNS:**
```bash
nslookup heyim.truyenthong.edu.vn
```

**Check cloudflared logs:**
```bash
sudo tail -f /var/log/cloudflared.log
# or
sudo launchctl list | grep cloudflare
```

## Rollback

If deployment fails:

**1. Stop new services:**
```bash
./stop.sh
```

**2. Restore cloudflared config:**
```bash
cp ~/.cloudflared/config.yml.backup ~/.cloudflared/config.yml
sudo launchctl unload /Library/LaunchDaemons/com.cloudflare.cloudflared.plist
sudo launchctl load /Library/LaunchDaemons/com.cloudflare.cloudflared.plist
```

**3. Start dev servers:**
```bash
cd /Users/mac/HeyIm/backend && swift run &
cd /Users/mac/HeyIm/frontend && npm run dev &
```

## Updates

### Update Backend Code

```bash
cd /Users/mac/HeyIm/backend

# Pull changes
git pull

# Rebuild
swift build -c release

# Restart service
cd /Users/mac/HeyIm/deploy
./restart.sh
```

### Update Frontend Code

```bash
cd /Users/mac/HeyIm/frontend

# Pull changes
git pull

# Rebuild
npm run build

# Restart service
cd /Users/mac/HeyIm/deploy
./restart.sh
```

### Update Models

```bash
# Stop services
cd /Users/mac/HeyIm/deploy
./stop.sh

# Replace models
cp -r /path/to/new/models/* /Users/mac/HeyIm/models/

# Start services
./restart.sh
```

## Monitoring

### Setup UptimeRobot

1. Go to https://uptimerobot.com
2. Add new monitor:
   - Type: HTTPS
   - URL: https://heyim.truyenthong.edu.vn
   - Interval: 5 minutes
   - Alert contacts: Your email

### Resource Monitoring

**Check memory usage:**
```bash
ps aux | grep -E "(HeyImServer|next start)" | grep -v grep
```

**Check disk space:**
```bash
df -h /Users/mac/HeyIm
```

**Check model files:**
```bash
du -sh /Users/mac/HeyIm/models/*
```

## Performance Tuning

### Backend Optimizations

- Models are pre-compiled to .mlmodelc
- Release build has optimizations enabled
- Process priority set to -10 (higher priority)

### Frontend Optimizations

- Production build minified
- Static pages pre-rendered
- Image optimization enabled

### System Optimizations

**Disable unnecessary services:**
```bash
sudo launchctl list | grep -v com.apple | grep -v com.heyim
```

**Check thermal throttling:**
```bash
sudo powermetrics --samplers smc -i 1 -n 1
```

## Security

### Firewall Rules

Backend and frontend only accessible from localhost. Cloudflare tunnel handles external traffic.

**Check firewall:**
```bash
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
```

### Access Control

Add rate limiting in Cloudflare dashboard:
- Rate Limiting: 30 requests/min per IP
- DDoS protection: Auto-enabled

## Backup

### Manual Backup

```bash
# Backup everything
tar -czf ~/heyim-backup-$(date +%Y%m%d).tar.gz \
  /Users/mac/HeyIm/models \
  /Users/mac/HeyIm/backend \
  /Users/mac/HeyIm/frontend \
  /Users/mac/HeyIm/deploy \
  ~/.cloudflared/config.yml
```

### Automated Backup (TODO)

Create cron job for weekly backups.

## Production Checklist

- [x] Backend release build complete
- [x] Frontend production build complete
- [x] LaunchD daemons created
- [x] Logs directory created
- [x] Management scripts executable
- [ ] Services deployed and running
- [ ] Cloudflare tunnel configured
- [ ] DNS record created
- [ ] Public domain accessible
- [ ] Health checks passing
- [ ] UptimeRobot monitoring setup
- [ ] Backup strategy implemented

## Support

Check these resources:
- Project docs: /Users/mac/HeyIm/docs/
- Planning doc: /Users/mac/HeyIm/PLANNING.md
- Phase 4 doc: /Users/mac/HeyIm/docs/PHASE4_DEPLOYMENT.md
- Future features: /Users/mac/HeyIm/FUTURE_FEATURES.md

---

**Last Updated:** January 1, 2026
