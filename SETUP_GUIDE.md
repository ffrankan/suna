# Suna Setup Guide

This guide covers both development and production setups for Suna.

## 🚀 Quick Start (Production with Reverse Proxy)

**Recommended for self-hosting and production deployment**

### 1. Start with Reverse Proxy
```bash
# Use the automated script
./start-with-proxy.sh

# Or manually
docker-compose up --build -d
```

### 2. Access the Application
- **Application**: http://localhost
- **API Health**: http://localhost/health

### 3. For Different IP/Domain
No code changes needed! Just access via your server's IP:
- http://192.168.1.100
- http://your-domain.com

## 🛠️ Development Setup

**For development and debugging**

### 1. Start Backend Only
```bash
cd backend
# Install dependencies and start
uvicorn api:app --host 0.0.0.0 --port 8000 --reload
```

### 2. Start Frontend with Proxy
```bash
cd frontend
npm install
npm run dev
```

The frontend dev server automatically proxies `/api/*` requests to `http://localhost:8000`.

### 3. Access Development
- **Frontend**: http://localhost:3000
- **Backend**: http://localhost:8000 (direct access)

## 🏗️ Architecture

### Production (Reverse Proxy)
```
Browser → Nginx (Port 80) → Frontend (Port 3000)
                         → Backend (Port 8000)
```

### Development
```
Browser → Next.js Dev Server (Port 3000) → Backend (Port 8000)
```

## 🔧 Configuration

### Production Environment Variables
Set in `backend/.env`:
```bash
ENV_MODE=production
# ... other variables
```

### Development Environment Variables
Set in `backend/.env`:
```bash
ENV_MODE=local
# ... other variables
```

Frontend automatically detects development mode and enables API proxy.

## 🚨 Troubleshooting

### CORS Issues
- **Production**: Should never happen with reverse proxy
- **Development**: Check that frontend dev server is running and proxying

### Services Not Starting
```bash
# Check logs
docker-compose logs

# Check specific service
docker-compose logs nginx
docker-compose logs backend
docker-compose logs frontend
```

### Port Conflicts
- **Production**: Only port 80 is exposed
- **Development**: Ensure ports 3000 and 8000 are available

## 📝 Key Benefits

### Reverse Proxy Setup:
✅ No CORS issues  
✅ Single point of access  
✅ Works with any IP/domain  
✅ Production-ready  
✅ SSL termination ready  

### Development Setup:
✅ Hot reload  
✅ Direct backend access  
✅ Automatic proxy  
✅ Debug-friendly  

## 🔄 Switching Between Setups

**From Development to Production:**
```bash
# Stop development servers
# Start with reverse proxy
./start-with-proxy.sh
```

**From Production to Development:**
```bash
# Stop reverse proxy
docker-compose down

# Start individual services
cd backend && uvicorn api:app --reload &
cd frontend && npm run dev &
```

No code changes needed - the configuration automatically adapts!