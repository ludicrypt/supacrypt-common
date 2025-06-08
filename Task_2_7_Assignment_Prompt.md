# Task Assignment: Containerization and Deployment

## Agent Profile
**Type:** Implementation Agent - DevOps Specialist  
**Expertise Required:** Docker, Container Security, .NET Container Optimization, Kubernetes, CI/CD

## Task Overview
Create production-ready container images for the backend service with multi-stage builds, security hardening, and deployment configurations for both local development and cloud environments (Docker Compose, Kubernetes, Azure Container Apps).

## Context
- **Repository:** `supacrypt-backend-akv`
- **Current State:** Fully implemented service with all features and comprehensive testing
- **Target:** Production-ready containerized deployment with security best practices
- **Deployment Targets:** Local Docker, Kubernetes, Azure Container Apps

## Detailed Requirements

### 1. Multi-Stage Dockerfile

#### Production Dockerfile
```dockerfile
# Dockerfile
# Build stage
FROM mcr.microsoft.com/dotnet/sdk:9.0-alpine AS build
WORKDIR /src

# Copy project files
COPY ["src/Supacrypt.Backend/Supacrypt.Backend.csproj", "src/Supacrypt.Backend/"]
COPY ["Directory.Build.props", "./"]
COPY ["Directory.Packages.props", "./"]

# Restore dependencies
RUN dotnet restore "src/Supacrypt.Backend/Supacrypt.Backend.csproj"

# Copy source code
COPY . .
WORKDIR "/src/src/Supacrypt.Backend"

# Build and publish
RUN dotnet publish "Supacrypt.Backend.csproj" \
    -c Release \
    -o /app/publish \
    -r linux-musl-x64 \
    --self-contained false \
    /p:PublishSingleFile=false \
    /p:PublishTrimmed=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:9.0-alpine AS runtime
RUN apk add --no-cache \
    ca-certificates \
    icu-libs \
    tzdata

# Create non-root user
RUN addgroup -g 1000 -S supacrypt && \
    adduser -u 1000 -S supacrypt -G supacrypt

WORKDIR /app

# Copy published files
COPY --from=build --chown=supacrypt:supacrypt /app/publish .

# Configure ASP.NET Core
ENV ASPNETCORE_URLS=http://+:5000 \
    ASPNETCORE_ENVIRONMENT=Production \
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:5000/health || exit 1

USER supacrypt
EXPOSE 5000

ENTRYPOINT ["dotnet", "Supacrypt.Backend.dll"]
```

#### Development Dockerfile
```dockerfile
# Dockerfile.development
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS development
WORKDIR /src

# Install development tools
RUN dotnet tool install --global dotnet-ef
ENV PATH="${PATH}:/root/.dotnet/tools"

# Keep container running for development
ENTRYPOINT ["dotnet", "watch", "run", "--no-launch-profile"]
```

### 2. Docker Compose Configuration

#### docker-compose.yml
```yaml
version: '3.8'

services:
  supacrypt-backend:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: supacrypt-backend
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
      - AzureKeyVault__VaultUri=${AZURE_KEYVAULT_URI}
      - AzureKeyVault__UseManagedIdentity=false
      - Security__Mtls__Enabled=false
      - Observability__Exporters__Otlp__Endpoint=http://otel-collector:4317
    ports:
      - "5000:5000"
    volumes:
      - ./certs:/app/certs:ro
    depends_on:
      - otel-collector
    networks:
      - supacrypt-network

  otel-collector:
    image: otel/opentelemetry-collector-contrib:latest
    container_name: otel-collector
    command: ["--config=/etc/otel-collector-config.yaml"]
    volumes:
      - ./deployment/otel-collector-config.yaml:/etc/otel-collector-config.yaml
    ports:
      - "4317:4317"   # OTLP gRPC
      - "4318:4318"   # OTLP HTTP
      - "8888:8888"   # Prometheus metrics
    networks:
      - supacrypt-network

networks:
  supacrypt-network:
    driver: bridge
```

#### docker-compose.override.yml
```yaml
version: '3.8'

services:
  supacrypt-backend:
    build:
      context: .
      dockerfile: Dockerfile.development
    volumes:
      - ./src:/src
      - ${APPDATA}/Microsoft/UserSecrets:/root/.microsoft/usersecrets:ro
      - ${APPDATA}/ASP.NET/Https:/root/.aspnet/https:ro
    environment:
      - DOTNET_USE_POLLING_FILE_WATCHER=true
      - ASPNETCORE_LOGGING__CONSOLE__DISABLECOLORS=true
```

### 3. Container Security Hardening

#### Security Scanning
```dockerfile
# Add to CI/CD pipeline
# Scan for vulnerabilities
FROM aquasec/trivy:latest AS security-scan
COPY --from=build /app/publish /scan
RUN trivy fs --exit-code 1 --severity HIGH,CRITICAL /scan
```

#### Runtime Security
- Non-root user execution
- Read-only root filesystem
- No unnecessary packages
- Minimal attack surface with Alpine Linux
- Security headers configuration

### 4. Kubernetes Deployment

#### Deployment Manifest
```yaml
# deployment/k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: supacrypt-backend
  namespace: supacrypt
  labels:
    app: supacrypt-backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: supacrypt-backend
  template:
    metadata:
      labels:
        app: supacrypt-backend
        version: v1
    spec:
      serviceAccountName: supacrypt-backend
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
      containers:
      - name: supacrypt-backend
        image: supacrypt/backend:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 5000
          name: grpc
          protocol: TCP
        env:
        - name: ASPNETCORE_ENVIRONMENT
          value: "Production"
        - name: AzureKeyVault__VaultUri
          valueFrom:
            secretKeyRef:
              name: azure-keyvault-config
              key: vault-uri
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 5000
          initialDelaySeconds: 30
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 5000
          initialDelaySeconds: 10
          periodSeconds: 10
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: tls-certs
          mountPath: /app/certs
          readOnly: true
      volumes:
      - name: tmp
        emptyDir: {}
      - name: tls-certs
        secret:
          secretName: supacrypt-tls
```

#### Service Definition
```yaml
# deployment/k8s/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: supacrypt-backend
  namespace: supacrypt
  labels:
    app: supacrypt-backend
spec:
  type: ClusterIP
  ports:
  - port: 443
    targetPort: 5000
    protocol: TCP
    name: grpc
  selector:
    app: supacrypt-backend
```

#### ConfigMap
```yaml
# deployment/k8s/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: supacrypt-backend-config
  namespace: supacrypt
data:
  appsettings.Production.json: |
    {
      "Logging": {
        "LogLevel": {
          "Default": "Information",
          "Microsoft.AspNetCore": "Warning"
        }
      },
      "Security": {
        "Mtls": {
          "Enabled": true,
          "RequireClientCertificate": true
        }
      }
    }
```

### 5. Azure Container Apps Deployment

#### Infrastructure as Code (Bicep)
```bicep
// deployment/azure/main.bicep
param location string = resourceGroup().location
param environmentName string
param containerRegistryName string
param keyVaultName string

resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: 'supacrypt-backend'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: containerAppEnvironment.id
    configuration: {
      ingress: {
        external: false
        targetPort: 5000
        transport: 'http2'
      }
      secrets: [
        {
          name: 'azure-client-secret'
          keyVaultUrl: 'https://${keyVaultName}.vault.azure.net/secrets/client-secret'
          identity: 'System'
        }
      ]
      registries: [
        {
          server: '${containerRegistryName}.azurecr.io'
          identity: 'System'
        }
      ]
    }
    template: {
      containers: [
        {
          image: '${containerRegistryName}.azurecr.io/supacrypt-backend:latest'
          name: 'supacrypt-backend'
          resources: {
            cpu: json('0.5')
            memory: '1.0Gi'
          }
          env: [
            {
              name: 'AzureKeyVault__VaultUri'
              value: 'https://${keyVaultName}.vault.azure.net/'
            }
            {
              name: 'AzureKeyVault__UseManagedIdentity'
              value: 'true'
            }
          ]
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                path: '/health'
                port: 5000
              }
            }
            {
              type: 'Readiness'
              httpGet: {
                path: '/health/ready'
                port: 5000
              }
            }
          ]
        }
      ]
      scale: {
        minReplicas: 2
        maxReplicas: 10
        rules: [
          {
            name: 'http-rule'
            http: {
              metadata: {
                concurrentRequests: '100'
              }
            }
          }
        ]
      }
    }
  }
}
```

### 6. CI/CD Pipeline Integration

#### GitHub Actions Workflow
```yaml
# .github/workflows/docker-publish.yml
name: Docker Build and Push

on:
  push:
    branches: [ main ]
    tags: [ 'v*' ]
  pull_request:
    branches: [ main ]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
      security-events: write

    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3

    - name: Log in to Container Registry
      uses: docker/login-action@v3
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}

    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v5
      with:
        images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
        tags: |
          type=ref,event=branch
          type=ref,event=pr
          type=semver,pattern={{version}}
          type=semver,pattern={{major}}.{{minor}}
          type=sha

    - name: Build and push Docker image
      uses: docker/build-push-action@v5
      with:
        context: .
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
        cache-from: type=gha
        cache-to: type=gha,mode=max
        platforms: linux/amd64,linux/arm64

    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ steps.meta.outputs.version }}
        format: 'sarif'
        output: 'trivy-results.sarif'

    - name: Upload Trivy scan results
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: 'trivy-results.sarif'
```

### 7. Container Optimization

#### Image Size Optimization
- Use Alpine Linux base images
- Multi-stage builds to exclude build dependencies
- Minimize layers
- Use .dockerignore effectively

#### .dockerignore
```
**/.classpath
**/.dockerignore
**/.env
**/.git
**/.gitignore
**/.project
**/.settings
**/.toolstarget
**/.vs
**/.vscode
**/*.*proj.user
**/*.dbmdl
**/*.jfm
**/bin
**/charts
**/docker-compose*
**/compose*
**/Dockerfile*
**/node_modules
**/npm-debug.log
**/obj
**/secrets.dev.yaml
**/values.dev.yaml
**/build
**/dist
LICENSE
README.md
tests/
docs/
.github/
```

### 8. Local Development Support

#### Makefile
```makefile
.PHONY: build run test clean

# Docker commands
build:
	docker build -t supacrypt-backend:latest .

build-dev:
	docker build -f Dockerfile.development -t supacrypt-backend:dev .

run:
	docker-compose up -d

run-dev:
	docker-compose -f docker-compose.yml -f docker-compose.override.yml up

stop:
	docker-compose down

clean:
	docker-compose down -v
	docker rmi supacrypt-backend:latest supacrypt-backend:dev

# Kubernetes commands
k8s-deploy:
	kubectl apply -k deployment/k8s/

k8s-delete:
	kubectl delete -k deployment/k8s/

# Testing
test-container:
	docker run --rm supacrypt-backend:latest dotnet test

security-scan:
	trivy image supacrypt-backend:latest
```

### 9. Documentation

#### deployment/README.md
Create comprehensive deployment documentation including:
- Container architecture overview
- Build and deployment procedures
- Environment configuration guide
- Security considerations
- Troubleshooting guide
- Performance tuning recommendations

### 10. Monitoring and Observability

#### Container Metrics
Configure Prometheus metrics exposure:
```yaml
# In Kubernetes deployment
annotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "5000"
  prometheus.io/path: "/metrics"
```

## Implementation Steps

1. **Create Dockerfile**
   - Implement multi-stage build
   - Optimize for size and security
   - Add health checks

2. **Set up Docker Compose**
   - Create development environment
   - Include observability stack
   - Configure networking

3. **Implement Kubernetes Manifests**
   - Create base deployment resources
   - Add security policies
   - Configure autoscaling

4. **Azure Container Apps**
   - Create Bicep templates
   - Configure managed identity
   - Set up scaling rules

5. **CI/CD Integration**
   - Implement build pipeline
   - Add security scanning
   - Configure automated deployment

## Validation Criteria
Your implementation will be considered complete when:
1. ✅ Multi-stage Dockerfile builds successfully
2. ✅ Container image < 200MB
3. ✅ Security scanning passes with no HIGH/CRITICAL vulnerabilities
4. ✅ Docker Compose setup works for local development
5. ✅ Kubernetes manifests deploy successfully
6. ✅ Azure Container Apps deployment template validated
7. ✅ CI/CD pipeline builds and pushes images
8. ✅ Health checks pass in all deployment targets
9. ✅ Non-root user execution verified
10. ✅ Documentation complete and accurate

## Important Notes
- Never include secrets in container images
- Always use specific version tags, not 'latest' in production
- Implement proper health checks for orchestration
- Consider multi-architecture builds (amd64, arm64)
- Test container behavior under resource constraints

## Memory Bank Logging
Document your work in `supacrypt-common/Memory/Phase_2_Backend_Service/Task_2_7_Containerization_Log.md` following the established format. Include:
- Image size optimization results
- Security scan findings and remediations
- Performance characteristics in containers
- Deployment testing results
- Any platform-specific considerations

Begin by creating the production Dockerfile with security best practices.