# Docker Setup for Dharma Backend

This guide explains how to run the Dharma backend using Docker.

## Prerequisites

- Docker installed on your system
- Docker Compose (optional, for easier management)

## Quick Start

### Option 1: Using Docker Compose (Recommended)

1. **Set environment variables**:
   ```bash
   export GEMINI_API_KEY=your_gemini_api_key_here
   ```

2. **Build and run**:
   ```bash
   docker-compose up --build
   ```

3. **Run in detached mode**:
   ```bash
   docker-compose up -d
   ```

4. **View logs**:
   ```bash
   docker-compose logs -f
   ```

5. **Stop the container**:
   ```bash
   docker-compose down
   ```

### Option 2: Using Docker directly

1. **Build the image**:
   ```bash
   docker build -t dharma-backend .
   ```

2. **Run the container**:
   ```bash
   docker run -d \
     --name dharma-backend \
     -p 8080:8080 \
     -e GEMINI_API_KEY=your_gemini_api_key_here \
     -e PORT=8080 \
     -v $(pwd)/generated_reports:/app/generated_reports \
     dharma-backend
   ```

3. **View logs**:
   ```bash
   docker logs -f dharma-backend
   ```

4. **Stop the container**:
   ```bash
   docker stop dharma-backend
   docker rm dharma-backend
   ```

## Environment Variables

### Required

- `GEMINI_API_KEY`: Your Google Gemini API key for AI features
- `GEMINI_API_KEY_INVESTIGATION`: Investigation-specific Gemini API key (optional, falls back to GEMINI_API_KEY)
- `GEMINI_API_KEY_LEGAL_SUGGESTIONS`: Legal suggestions Gemini API key (optional, falls back to GEMINI_API_KEY)

### Optional

- `PORT`: Server port (default: `8080`)
- `INVESTIGATION_REPORTS_DIR`: Directory for generated reports (default: `generated_reports`)

## Volumes

The `generated_reports` directory is mounted as a volume to persist generated PDF reports across container restarts.

## Health Check

The container includes a health check that monitors the `/api/health` endpoint. You can check the health status with:

```bash
docker ps
```

## Production Deployment

For production, consider:

1. **Use environment file**:
   ```bash
   docker-compose --env-file .env.prod up -d
   ```

2. **Add reverse proxy** (nginx/traefik) in front of the container

3. **Use secrets management** for sensitive environment variables

4. **Set resource limits**:
   ```yaml
   deploy:
     resources:
       limits:
         cpus: '1'
         memory: 1G
   ```

5. **Enable logging**:
   ```yaml
   logging:
     driver: "json-file"
     options:
       max-size: "10m"
       max-file: "3"
   ```

## Troubleshooting

### Container won't start

Check logs:
```bash
docker logs dharma-backend
```

### Port already in use

Change the port mapping:
```bash
docker run -p 8081:8080 ...
```

### Permission issues with volumes

Ensure the `generated_reports` directory has proper permissions:
```bash
mkdir -p generated_reports/investigation_reports
chmod 755 generated_reports
```

## Development

For development with hot-reload, mount the code:

```yaml
volumes:
  - ./:/app
  - ./generated_reports:/app/generated_reports
```

Then use:
```bash
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up
```

