# Deployment

Production deployment guides for Facera applications.

---

## Web Servers

Facera is a standard Rack application compatible with all Ruby web servers.

### Puma (Recommended)

**config/puma.rb:**
```ruby
# Worker processes
workers ENV.fetch('WEB_CONCURRENCY', 2)

# Threads per worker
threads_count = ENV.fetch('RAILS_MAX_THREADS', 5)
threads threads_count, threads_count

# Port
port ENV.fetch('PORT', 9292)

# Environment
environment ENV.fetch('RACK_ENV', 'development')

# Preload app for better performance
preload_app!

# Logging
stdout_redirect 'log/puma_access.log', 'log/puma_error.log', true

# PID file
pidfile 'tmp/pids/puma.pid'

# State file
state_path 'tmp/pids/puma.state'
```

**Run:**
```bash
puma -C config/puma.rb
```

### Unicorn

**config/unicorn.rb:**
```ruby
# Worker processes
worker_processes 4

# Listen on port
listen 9292

# Timeout
timeout 30

# Preload app
preload_app true

# Logging
stdout_path 'log/unicorn_access.log'
stderr_path 'log/unicorn_error.log'

# PID file
pid 'tmp/pids/unicorn.pid'
```

**Run:**
```bash
unicorn -c config/unicorn.rb
```

### Passenger

**config/passenger.rb:**
```ruby
# Passenger configuration
PassengerEnabled on
PassengerAppRoot /var/www/facera_app
PassengerRuby /usr/bin/ruby

# Performance
PassengerMinInstances 2
PassengerMaxPoolSize 6
```

---

## Docker

### Dockerfile

```dockerfile
FROM ruby:3.2-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy Gemfile
COPY Gemfile Gemfile.lock ./

# Install gems
RUN bundle install --without development test

# Copy application
COPY . .

# Expose port
EXPOSE 9292

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
  CMD curl -f http://localhost:9292/api/v1/health || exit 1

# Run server
CMD ["puma", "-C", "config/puma.rb"]
```

### docker-compose.yml

```yaml
version: '3.8'

services:
  web:
    build: .
    ports:
      - "9292:9292"
    environment:
      - RACK_ENV=production
      - DATABASE_URL=postgresql://user:pass@db:5432/facera
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - db
      - redis
    volumes:
      - ./log:/app/log

  db:
    image: postgres:15
    environment:
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
      - POSTGRES_DB=facera
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

**Run:**
```bash
docker-compose up -d
```

---

## Environment Variables

### Required

```bash
# Database
DATABASE_URL=postgresql://user:pass@host:5432/database

# Redis (for caching, sessions)
REDIS_URL=redis://host:6379/0
```

### Optional

```bash
# Environment
RACK_ENV=production

# Server
PORT=9292
WEB_CONCURRENCY=2

# Features
ENABLE_OPERATOR_API=true
ENABLE_INTROSPECTION=false

# Secrets
SECRET_KEY_BASE=your_secret_key

# Monitoring
SENTRY_DSN=https://...
```

---

## Nginx

### Reverse Proxy

```nginx
upstream facera_app {
  server localhost:9292;
}

server {
  listen 80;
  server_name api.example.com;

  location / {
    proxy_pass http://facera_app;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }

  # Health check endpoint
  location /health {
    access_log off;
    proxy_pass http://facera_app/api/v1/health;
  }
}
```

### SSL/TLS

```nginx
server {
  listen 443 ssl http2;
  server_name api.example.com;

  ssl_certificate /etc/ssl/certs/api.example.com.crt;
  ssl_certificate_key /etc/ssl/private/api.example.com.key;

  ssl_protocols TLSv1.2 TLSv1.3;
  ssl_ciphers HIGH:!aNULL:!MD5;

  location / {
    proxy_pass http://facera_app;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto https;
  }
}
```

---

## Kubernetes

### Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: facera-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: facera-api
  template:
    metadata:
      labels:
        app: facera-api
    spec:
      containers:
      - name: facera
        image: facera-api:latest
        ports:
        - containerPort: 9292
        env:
        - name: RACK_ENV
          value: "production"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: facera-secrets
              key: database-url
        - name: REDIS_URL
          valueFrom:
            secretKeyRef:
              name: facera-secrets
              key: redis-url
        livenessProbe:
          httpGet:
            path: /api/v1/health
            port: 9292
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /api/v1/health
            port: 9292
          initialDelaySeconds: 5
          periodSeconds: 5
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
```

### Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: facera-api
spec:
  selector:
    app: facera-api
  ports:
  - protocol: TCP
    port: 80
    targetPort: 9292
  type: LoadBalancer
```

### Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: facera-api
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - api.example.com
    secretName: facera-api-tls
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: facera-api
            port:
              number: 80
```

---

## AWS

### Elastic Beanstalk

**Procfile:**
```
web: bundle exec puma -C config/puma.rb
```

**.ebextensions/01_packages.config:**
```yaml
packages:
  yum:
    git: []
    postgresql-devel: []
```

**Deploy:**
```bash
eb init -p ruby-3.2 facera-api
eb create facera-production
eb deploy
```

### ECS

**Task Definition:**
```json
{
  "family": "facera-api",
  "containerDefinitions": [
    {
      "name": "facera",
      "image": "facera-api:latest",
      "memory": 512,
      "cpu": 256,
      "essential": true,
      "portMappings": [
        {
          "containerPort": 9292,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "RACK_ENV",
          "value": "production"
        }
      ],
      "secrets": [
        {
          "name": "DATABASE_URL",
          "valueFrom": "arn:aws:secretsmanager:..."
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/facera-api",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

---

## Heroku

### Procfile

```
web: bundle exec puma -C config/puma.rb
```

### Deploy

```bash
heroku create facera-api
git push heroku main
heroku config:set RACK_ENV=production
heroku ps:scale web=2
```

---

## Monitoring

### Health Checks

```bash
curl -f http://localhost:9292/api/v1/health
```

Response:
```json
{
  "status": "ok",
  "facet": "external",
  "timestamp": "2026-03-09T10:30:00Z"
}
```

### Metrics

Use tools like:
- Prometheus + Grafana
- New Relic
- Datadog
- AppSignal

### Logging

Configure structured logging:

```ruby
# config/environments/production.rb
Facera.configure do |config|
  config.logger = Logger.new($stdout)
  config.log_level = :info
  config.log_format = :json
end
```

---

## Security Checklist

- [ ] Disable introspection in production
- [ ] Use HTTPS/TLS
- [ ] Implement rate limiting
- [ ] Enable CORS properly
- [ ] Set security headers
- [ ] Use environment variables for secrets
- [ ] Enable audit logging
- [ ] Implement authentication
- [ ] Keep dependencies updated
- [ ] Run security scanning

---

## Performance Tips

1. **Preload app** - Use `preload_app!` in Puma/Unicorn
2. **Connection pooling** - Configure database pool size
3. **Caching** - Use Redis for caching
4. **CDN** - Serve static assets via CDN
5. **Monitoring** - Track response times and errors

---

## Next Steps

- [Architecture](Architecture.md) - Understand the framework
- [Contributing](Contributing.md) - Contribute to Facera
