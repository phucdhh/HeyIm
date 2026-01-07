# Phase 4 - Deployment on Mac Mini M2

**Status:** In Progress  
**Target:** Deploy HeyIm to production with domain heyim.truyenthong.edu.vn

## Prerequisites
- ✅ Phase 1 Complete: Models converted to Core ML
- ✅ Phase 2 Complete: Backend API working (port 5858)
- ✅ Phase 3 Complete: Frontend MVP functional (port 3000)
- 🔄 Phase 4: Production deployment setup

## Deployment Architecture

```
Internet → Cloudflare Tunnel → heyim.truyenthong.edu.vn
                                 ↓
                           Mac Mini M2
                                 ↓
                        ┌────────┴────────┐
                        ↓                 ↓
                 Backend (5858)    Frontend (3000)
                   (launchd)         (launchd)
                        ↓
                  Core ML Models
                   (ANE/CPU)
```

## Phase 4 Tasks

### Week 9: Production Setup

#### 1. Cloudflare Tunnel Configuration
**Goal:** Expose heyim.truyenthong.edu.vn pointing to Mac Mini without port conflicts

**Steps:**
- [ ] Check existing cloudflared config: `~/.cloudflared/config.yml`
- [ ] Add new ingress rule for heyim subdomain
- [ ] Configure tunnel to route to localhost:3000 (Next.js frontend)
- [ ] Frontend will proxy API requests to localhost:5858
- [ ] Test tunnel connectivity
- [ ] Verify no conflicts with existing tunnels

**Commands:**
```bash
# Check existing config
cat ~/.cloudflared/config.yml

# Test new ingress rules (dry-run)
cloudflared tunnel route dns <TUNNEL_NAME> heyim.truyenthong.edu.vn

# Restart cloudflared with new config
sudo launchctl unload /Library/LaunchDaemons/com.cloudflare.cloudflared.plist
sudo launchctl load /Library/LaunchDaemons/com.cloudflare.cloudflared.plist
```

#### 2. LaunchD Daemon Setup
**Goal:** Auto-start backend and frontend on system boot, restart on crash

**Backend Daemon:** `/Library/LaunchDaemons/com.heyim.backend.plist`
- Runs as user `mac`
- Working directory: `/Users/mac/HeyIm/backend`
- Command: `.build/release/HeyImServer` (release build)
- Port: 5858
- Logs: `/Users/mac/HeyIm/logs/backend.log`

**Frontend Daemon:** `/Library/LaunchDaemons/com.heyim.frontend.plist`
- Runs as user `mac`
- Working directory: `/Users/mac/HeyIm/frontend`
- Command: `npm run start` (production build)
- Port: 3000
- Logs: `/Users/mac/HeyIm/logs/frontend.log`

**Tasks:**
- [ ] Create launchd plist files
- [ ] Build backend in release mode
- [ ] Build frontend for production (`npm run build`)
- [ ] Set up log rotation
- [ ] Test daemon auto-restart on failure
- [ ] Test daemon auto-start on reboot

#### 3. Security & Firewall
**Goal:** Lock down unnecessary ports, allow only essential traffic

**Tasks:**
- [ ] Review macOS firewall settings
- [ ] Allow incoming on port 5858 only from localhost
- [ ] Allow incoming on port 3000 only from localhost (cloudflared handles public)
- [ ] Block direct external access to 5858 and 3000
- [ ] Enable stealth mode
- [ ] Review running services: `sudo lsof -iTCP -sTCP:LISTEN`

**Firewall Commands:**
```bash
# Enable firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on

# Block incoming by default, allow established
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setblockall off

# Enable stealth mode
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
```

#### 4. Monitoring & Alerts
**Goal:** Know when service is down, monitor resource usage

**UptimeRobot Setup:**
- [ ] Create HTTP(S) monitor for https://heyim.truyenthong.edu.vn
- [ ] Check interval: 5 minutes
- [ ] Alert contacts: Email/Telegram
- [ ] Monitor /health endpoint

**Resource Monitoring:**
- [ ] Setup cron job to log CPU/RAM usage
- [ ] Alert if backend process dies
- [ ] Monitor disk space (models are ~3.6GB)

**Monitoring Script:** `/Users/mac/HeyIm/scripts/monitor.sh`

#### 5. Backup Strategy
**Goal:** Regular backups of models, configs, and user data (if any)

**Backup Items:**
- Models directory: `/Users/mac/HeyIm/models/` (~3.6GB)
- Backend config: `/Users/mac/HeyIm/backend/`
- Frontend config: `/Users/mac/HeyIm/frontend/`
- LaunchD plists
- Cloudflared config

**Schedule:**
- Daily: Log rotation
- Weekly: Full backup to external drive/cloud
- Before updates: Snapshot entire HeyIm directory

**Tasks:**
- [ ] Create backup script
- [ ] Setup cron job for weekly backups
- [ ] Test restore procedure
- [ ] Document backup locations

### Week 10: Load Testing & Optimization

#### 6. Load Testing
**Goal:** Ensure system can handle 1-2 concurrent jobs without crash

**Test Scenarios:**
1. Single user: 10 consecutive generations (30 steps each)
2. Two concurrent users: Simultaneous generation
3. Stress test: 5 rapid requests (should queue properly)
4. Memory leak test: 50 generations over 1 hour

**Tools:**
```bash
# Simple load test with curl
for i in {1..10}; do
  curl -X POST http://localhost:5858/api/generate \
    -H "Content-Type: application/json" \
    -d '{"prompt": "test", "steps": 30}' &
done
```

**Success Criteria:**
- [ ] No crashes after 10 consecutive generations
- [ ] Concurrent requests queue properly (no race conditions)
- [ ] Memory usage stable (no leaks)
- [ ] Generation time consistent (~13-15s for 30 steps)
- [ ] Queue handles overload gracefully (returns 429 or queues)

#### 7. Performance Tuning
**Goal:** Optimize for production workload

**Backend Optimizations:**
- [ ] Compile models if not already compiled
- [ ] Pre-load models on startup (warm cache)
- [ ] Set appropriate concurrency limit (1-2 jobs)
- [ ] Enable release mode optimizations

**Frontend Optimizations:**
- [ ] Production build with minification
- [ ] Enable image optimization in Next.js
- [ ] Add caching headers for static assets
- [ ] Lazy load history images

**System Optimizations:**
- [ ] Disable unnecessary background services
- [ ] Set ANE to high performance mode (if available)
- [ ] Ensure adequate swap space
- [ ] Monitor thermal throttling

#### 8. Documentation
**Goal:** Runbook for operations and troubleshooting

**Documents to Create:**
- [ ] `deploy/README.md` - Deployment guide
- [ ] `ops/RUNBOOK.md` - Operations procedures
- [ ] `ops/TROUBLESHOOTING.md` - Common issues & fixes
- [ ] `ops/ROLLBACK.md` - Rollback procedures

**Runbook Contents:**
- Starting/stopping services
- Checking logs
- Restarting after crash
- Updating models
- Emergency procedures

## Deployment Checklist

### Pre-Deployment
- [ ] Backend release build successful
- [ ] Frontend production build successful
- [ ] All tests passing
- [ ] Models compiled and optimized
- [ ] Logs directory created with proper permissions
- [ ] Backup of current state

### Deployment
- [ ] Install launchd daemons
- [ ] Start backend daemon
- [ ] Start frontend daemon
- [ ] Configure cloudflared tunnel
- [ ] Restart cloudflared
- [ ] Test internal connectivity (localhost:5858, localhost:3000)
- [ ] Test external connectivity (https://heyim.truyenthong.edu.vn)

### Post-Deployment
- [ ] Monitor logs for 30 minutes
- [ ] Run smoke tests (generate 3 images)
- [ ] Check resource usage (htop/Activity Monitor)
- [ ] Setup UptimeRobot monitoring
- [ ] Document any issues encountered
- [ ] Create first backup

### Validation
- [ ] Service accessible via domain
- [ ] Image generation works end-to-end
- [ ] History persists correctly
- [ ] Example prompts load properly
- [ ] Download works
- [ ] Regenerate with random seed works
- [ ] No errors in logs
- [ ] Memory usage stable

## Rollback Plan

If deployment fails:

1. **Stop new services:**
   ```bash
   sudo launchctl unload /Library/LaunchDaemons/com.heyim.backend.plist
   sudo launchctl unload /Library/LaunchDaemons/com.heyim.frontend.plist
   ```

2. **Restore cloudflared config:**
   ```bash
   cp ~/.cloudflared/config.yml.backup ~/.cloudflared/config.yml
   sudo launchctl unload /Library/LaunchDaemons/com.cloudflare.cloudflared.plist
   sudo launchctl load /Library/LaunchDaemons/com.cloudflare.cloudflared.plist
   ```

3. **Restart in dev mode:**
   ```bash
   cd /Users/mac/HeyIm/backend && swift run &
   cd /Users/mac/HeyIm/frontend && npm run dev &
   ```

4. **Investigate logs:**
   ```bash
   tail -100 /Users/mac/HeyIm/logs/backend.log
   tail -100 /Users/mac/HeyIm/logs/frontend.log
   ```

## Success Metrics

### Performance
- [ ] Generation time ≤ 15s (30 steps, 512x512)
- [ ] API response time ≤ 100ms (non-generation endpoints)
- [ ] Page load time ≤ 2s
- [ ] No memory leaks after 24h

### Reliability
- [ ] Uptime ≥ 99% (monitored by UptimeRobot)
- [ ] Auto-restart works (test by killing process)
- [ ] No crashes after 100 generations
- [ ] Queue handles concurrent requests

### User Experience
- [ ] Domain resolves correctly
- [ ] HTTPS works (via Cloudflare)
- [ ] Image generation succeeds consistently
- [ ] Error messages are helpful
- [ ] UI responsive on mobile/desktop

## Timeline

**Week 9 (Days 1-7):**
- Days 1-2: Cloudflared tunnel + LaunchD setup
- Days 3-4: Security & monitoring setup
- Days 5-6: Backup strategy + documentation
- Day 7: Initial deployment + testing

**Week 10 (Days 1-7):**
- Days 1-3: Load testing + optimization
- Days 4-5: 24h stability test
- Day 6: Final documentation
- Day 7: Go-live + monitoring

## Next Steps

1. **Immediate (Now):**
   - Review existing cloudflared config
   - Create launchd plist files
   - Build backend in release mode
   - Build frontend for production

2. **Short-term (This Week):**
   - Deploy to production
   - Setup monitoring
   - Run smoke tests
   - Document issues

3. **Medium-term (Next Week):**
   - Load testing
   - Performance tuning
   - 24h stability test
   - Final documentation

## Notes

- Mac Mini M2 runs headless, so launchd daemons are essential
- Cloudflare tunnel provides HTTPS without exposing ports
- Keep existing cloudflared services intact
- Test thoroughly before announcing to users
- Have rollback plan ready at all times

---

**Last Updated:** January 1, 2026  
**Status:** Ready to begin deployment
