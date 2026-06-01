# VPS Deployment Handbook (Ubuntu Server Deployment)

This manual provides clean, step-by-step instructions for deploying the **Parkir Kampus** backend and Redis services to an Ubuntu VPS using Git, Docker Compose, and Nginx.

---

## 1. Prerequisites Installation (Ubuntu)

Run the following commands on your VPS terminal to update system packages and install Docker + Docker Compose.

```bash
# Update package database
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y curl git apt-transport-https ca-certificates curl software-properties-common nginx

# Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up the stable Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Enable and start Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Add your user to the docker group (optional, to run docker without sudo)
sudo usermod -aG docker $USER
```

---

## 2. Deploy Workspace Repository

Clone the project repository to your VPS directory and populate the environment variables configuration.

```bash
# Clone the repository
cd /var/www
git clone https://github.com/rahmatnug/parkir-kampus.git
cd parkir-kampus

# Create and configure the backend environment file
cp backend/.env.example backend/.env
nano backend/.env
```

Ensure your `backend/.env` file contains accurate production values:
```env
DB_HOST=your-database-host-url
DB_USER=your-database-username
DB_PASSWORD=your-database-password
DB_NAME=your-database-name
DB_PORT=5432
DB_SSLMODE=require

REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=

JWT_SECRET=your-secure-jwt-random-secret-key
```

---

## 3. Launching Application Containers

Use Docker Compose to build the optimized multi-stage backend image and spin up the Redis container in the background.

```bash
# Build and run the containers in detached (background) mode
docker compose up -d --build

# Verify container statuses
docker compose ps

# Inspect logs to ensure successful database and Redis initializations
docker compose logs -f backend
```

---

## 4. Nginx Reverse Proxy & WebSocket Configuration

To safely expose our backend on port `80` (HTTP) or `443` (HTTPS) and allow our real-time WebSockets to communicate without CORS blockers, configure Nginx as a reverse proxy.

Create a new Nginx block:
```bash
sudo nano /etc/nginx/sites-available/parkirkampus
```

Paste the following production configuration:
```nginx
server {
    listen 80;
    server_name your-domain-or-vps-ip.com;

    # Backend HTTP Endpoints
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Real-Time WebSocket Connections
    location /api/v1/ws/connect {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }
}
```

Enable the configuration and restart Nginx:
```bash
# Link to enabled sites
sudo ln -s /etc/nginx/sites-available/parkirkampus /etc/nginx/sites-enabled/

# Test Nginx syntax
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
```

---

## 5. SSL / HTTPS Setup (Certbot Let's Encrypt)

Secure your server traffic with Let's Encrypt SSL certificates.

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Obtain and install SSL Certificate (Automatic Nginx configuration adjustment)
sudo certbot --nginx -d your-domain-or-vps-ip.com

# Verify renewal daemon status
sudo systemctl status certbot.timer
```
