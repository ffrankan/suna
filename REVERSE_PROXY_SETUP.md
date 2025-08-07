# Reverse Proxy Setup for Suna Self-Hosting

This document explains how to set up Suna with a reverse proxy to solve CORS issues in self-hosting environments.

## Overview

The reverse proxy setup uses Nginx to serve both the frontend and backend through a single origin (port 80), eliminating CORS issues that occur when frontend and backend run on different ports.

## Architecture

```
┌─────────────────┐
│   User Browser  │
└─────────┬───────┘
          │ http://your-server/
          ▼
┌─────────────────┐
│  Nginx (Port 80)│
│  Reverse Proxy  │
└─────────┬───────┘
          │
          ├─ /api/* ──────► Backend (Port 8000)
          └─ /* ──────────► Frontend (Port 3000)
```

## Quick Start

1. **Use the startup script** (Recommended):
   ```bash
   ./start-with-proxy.sh
   ```

2. **Manual startup**:
   ```bash
   docker-compose up --build -d
   ```

3. **Access the application**:
   - Application: http://localhost
   - Health check: http://localhost/health

## Configuration Files

### nginx.conf
- **Location**: `./nginx.conf`
- **Purpose**: Configures Nginx to proxy requests to frontend and backend
- **Key features**:
  - Routes `/api/*` to backend service
  - Routes all other requests to frontend
  - Enables gzip compression
  - Adds security headers
  - Supports WebSocket connections

### docker-compose.yaml
- **Changes made**:
  - Added `nginx` service
  - Changed frontend/backend from `ports` to `expose` (no direct access)
  - Nginx exposes port 80 to host

### backend/api.py
- **CORS configuration simplified**:
  - Local development: allows all origins (`*`)
  - Staging/Production: specific domains only
  - No need for complex IP-based origins

## Self-Hosting Setup

### For Different IP Addresses

If you're hosting on a different IP (e.g., `192.168.1.100`):

1. **No code changes needed** - that's the beauty of reverse proxy!
2. Access via: `http://192.168.1.100`
3. API automatically available at: `http://192.168.1.100/api/*`

### For Custom Domains

If you have a custom domain (e.g., `my-suna.example.com`):

1. Point your domain to your server's IP
2. Update production CORS settings in `backend/api.py`:
   ```python
   elif config.ENV_MODE == EnvMode.PRODUCTION:
       allowed_origins = [
           "https://my-suna.example.com",
           "http://my-suna.example.com"  # if not using HTTPS
       ]
   ```

### HTTPS Setup

For production with HTTPS, update `nginx.conf`:

```nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com;
    
    ssl_certificate /path/to/your/cert.pem;
    ssl_certificate_key /path/to/your/key.pem;
    
    # ... rest of configuration
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}
```

## Troubleshooting

### Services Not Starting
```bash
# Check service status
docker-compose ps

# View logs
docker-compose logs nginx
docker-compose logs backend
docker-compose logs frontend
```

### Nginx Configuration Issues
```bash
# Test nginx configuration
docker-compose exec nginx nginx -t

# Reload nginx configuration
docker-compose exec nginx nginx -s reload
```

### CORS Issues Still Occurring
1. Ensure you're accessing via `http://localhost` (not `localhost:3000` or `localhost:8000`)
2. Check browser developer tools for actual request origins
3. Verify nginx is properly routing requests:
   ```bash
   curl -v http://localhost/api/health
   ```

### Health Check Failing
```bash
# Check if backend is responding
docker-compose exec nginx curl -v http://backend:8000/api/health

# Check if frontend is responding  
docker-compose exec nginx curl -v http://frontend:3000
```

## Environment Variables

No additional environment variables needed for basic reverse proxy setup. The existing `.env` files for backend and frontend work as-is.

## Performance Considerations

### Nginx Optimizations Already Included:
- Gzip compression enabled
- Static asset caching (1 hour)
- Connection keep-alive
- Buffer optimization for large responses

### For High Traffic:
- Increase worker processes in nginx.conf
- Add load balancing if running multiple backend instances
- Implement SSL termination at nginx level

## Security Features

### Headers Added:
- `X-Frame-Options: SAMEORIGIN`
- `X-Content-Type-Options: nosniff`
- `X-XSS-Protection: 1; mode=block`
- `Referrer-Policy: strict-origin-when-cross-origin`

### Additional Security (Recommended):
1. Enable fail2ban for brute force protection
2. Configure rate limiting in nginx
3. Use HTTPS in production
4. Regularly update Docker images

## Monitoring

### Health Checks:
- Nginx: `http://localhost/health`
- Direct backend: `docker-compose exec nginx curl http://backend:8000/api/health`
- Frontend: `docker-compose exec nginx curl http://frontend:3000`

### Logs:
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f nginx
docker-compose logs -f backend
docker-compose logs -f frontend
```

## Migration from Direct Access

If you were previously accessing services directly:

### Before (with CORS issues):
- Frontend: `http://localhost:3000`
- Backend: `http://localhost:8000/api/*`

### After (no CORS issues):
- Everything: `http://localhost/`
- API: `http://localhost/api/*`

### Code Changes Needed:
Update your frontend code to use relative URLs:
```javascript
// Before
const API_BASE = 'http://localhost:8000/api';

// After  
const API_BASE = '/api';
```

## Support

If you encounter issues:

1. Check this documentation
2. Review the logs: `docker-compose logs`
3. Verify all required files are present
4. Ensure Docker and docker-compose are properly installed
5. Test with the health check endpoint

For persistent issues, the reverse proxy setup eliminates most CORS-related problems that occur in self-hosting scenarios.