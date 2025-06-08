# Task Assignment: Implement mTLS Security

## Agent Profile
**Type:** Implementation Agent - Security Engineer  
**Expertise Required:** .NET 9, Kestrel, X.509 Certificates, mTLS, gRPC Security, ASP.NET Core Security

## Task Overview
Configure and implement mutual TLS (mTLS) authentication for the gRPC service. This will ensure secure, authenticated communication between all crypto providers and the backend service using client certificates.

## Context
- **Repository:** `supacrypt-backend-akv`
- **Current State:** gRPC service operational with Azure Key Vault integration
- **Target:** Production-ready mTLS implementation with flexible certificate management
- **Security Requirement:** All communication must be mutually authenticated

## Detailed Requirements

### 1. Kestrel Configuration for mTLS

#### Update Kestrel Settings
Configure Kestrel to require client certificates:
```csharp
public static IHostBuilder CreateHostBuilder(string[] args) =>
    Host.CreateDefaultBuilder(args)
        .ConfigureWebHostDefaults(webBuilder =>
        {
            webBuilder.ConfigureKestrel(serverOptions =>
            {
                serverOptions.ConfigureHttpsDefaults(listenOptions =>
                {
                    listenOptions.ClientCertificateMode = ClientCertificateMode.RequireCertificate;
                    listenOptions.CheckCertificateRevocation = true;
                });
            });
        });
```

#### Enhanced Security Options
Update `SecurityOptions.cs`:
```csharp
public class SecurityOptions
{
    public MtlsOptions Mtls { get; set; } = new();
    public CertificateOptions ServerCertificate { get; set; } = new();
    public AuthorizationOptions Authorization { get; set; } = new();
}

public class MtlsOptions
{
    public bool Enabled { get; set; } = true;
    public bool RequireClientCertificate { get; set; } = true;
    public ClientCertificateMode Mode { get; set; } = ClientCertificateMode.RequireCertificate;
    public bool CheckCertificateRevocation { get; set; } = true;
    public List<string> AllowedThumbprints { get; set; } = new();
    public List<string> AllowedIssuers { get; set; } = new();
    public bool ValidateChain { get; set; } = true;
    public X509RevocationMode RevocationMode { get; set; } = X509RevocationMode.Online;
}

public class CertificateOptions
{
    public string Source { get; set; } = "File"; // File, Store, KeyVault
    public string Path { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string Subject { get; set; } = string.Empty;
    public string StoreName { get; set; } = "My";
    public string StoreLocation { get; set; } = "CurrentUser";
    public string KeyVaultName { get; set; } = string.Empty;
    public string CertificateName { get; set; } = string.Empty;
}
```

### 2. Certificate Validation Service

#### Create ICertificateValidationService
```csharp
public interface ICertificateValidationService
{
    Task<CertificateValidationResult> ValidateClientCertificateAsync(
        X509Certificate2 certificate, 
        X509Chain chain, 
        SslPolicyErrors sslPolicyErrors);
}

public class CertificateValidationResult
{
    public bool IsValid { get; set; }
    public string? Subject { get; set; }
    public string? Thumbprint { get; set; }
    public List<string> Errors { get; set; } = new();
    public Dictionary<string, string> Claims { get; set; } = new();
}
```

#### Implement CertificateValidationService
Comprehensive validation including:
- Certificate expiry checking
- Chain validation
- Thumbprint allowlist checking
- Issuer validation
- Subject Alternative Name (SAN) validation
- Certificate purpose validation (client authentication)
- Revocation checking (CRL/OCSP)

### 3. Certificate Management Utilities

#### Create CertificateLoader
Support multiple certificate sources:
```csharp
public interface ICertificateLoader
{
    Task<X509Certificate2> LoadServerCertificateAsync(CertificateOptions options);
    Task<X509Certificate2> LoadCertificateFromFileAsync(string path, string? password);
    Task<X509Certificate2> LoadCertificateFromStoreAsync(string subject, StoreName storeName, StoreLocation storeLocation);
    Task<X509Certificate2> LoadCertificateFromKeyVaultAsync(string vaultName, string certificateName);
}
```

### 4. Authentication Middleware

#### Create ClientCertificateAuthenticationMiddleware
```csharp
public class ClientCertificateAuthenticationMiddleware
{
    public async Task InvokeAsync(HttpContext context)
    {
        if (context.Connection.ClientCertificate != null)
        {
            var validationResult = await _validationService.ValidateClientCertificateAsync(
                context.Connection.ClientCertificate,
                null, // Chain will be built internally
                SslPolicyErrors.None);

            if (validationResult.IsValid)
            {
                // Create claims principal
                var claims = new List<Claim>
                {
                    new Claim(ClaimTypes.NameIdentifier, validationResult.Thumbprint!),
                    new Claim(ClaimTypes.Name, validationResult.Subject!),
                    new Claim("CertificateThumbprint", validationResult.Thumbprint!)
                };

                // Add custom claims from certificate
                foreach (var claim in validationResult.Claims)
                {
                    claims.Add(new Claim(claim.Key, claim.Value));
                }

                var identity = new ClaimsIdentity(claims, "Certificate");
                context.User = new ClaimsPrincipal(identity);
            }
            else
            {
                context.Response.StatusCode = 403;
                await context.Response.WriteAsync("Invalid client certificate");
                return;
            }
        }

        await _next(context);
    }
}
```

### 5. gRPC Service Authorization

#### Implement Authorization Policies
```csharp
services.AddAuthorization(options =>
{
    options.AddPolicy("RequireValidCertificate", policy =>
        policy.RequireAuthenticatedUser());

    options.AddPolicy("RequireSpecificProvider", policy =>
        policy.RequireClaim("Provider", "PKCS11", "CSP", "KSP", "CTK"));

    options.AddPolicy("RequireAdminCertificate", policy =>
        policy.RequireClaim("CertificateRole", "Admin"));
});
```

#### Apply Authorization to gRPC Service
```csharp
[Authorize(Policy = "RequireValidCertificate")]
public class SupacryptGrpcService : SupacryptService.SupacryptServiceBase
{
    // Existing service implementation
}
```

### 6. Certificate Generation Procedures

#### Create Development Certificate Scripts
Provide scripts for generating development certificates:
```bash
# scripts/generate-dev-certs.sh
#!/bin/bash

# Root CA
openssl req -x509 -newkey rsa:4096 -days 365 -nodes \
    -keyout ca-key.pem -out ca-cert.pem \
    -subj "/C=US/ST=State/L=City/O=Supacrypt/CN=Supacrypt Dev CA"

# Server Certificate
openssl req -newkey rsa:4096 -nodes -keyout server-key.pem \
    -out server-req.pem \
    -subj "/C=US/ST=State/L=City/O=Supacrypt/CN=localhost"

# Client Certificate Template
generate_client_cert() {
    local provider=$1
    openssl req -newkey rsa:4096 -nodes -keyout ${provider}-key.pem \
        -out ${provider}-req.pem \
        -subj "/C=US/ST=State/L=City/O=Supacrypt/CN=${provider}"
    
    openssl x509 -req -in ${provider}-req.pem -days 365 \
        -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial \
        -out ${provider}-cert.pem \
        -extfile <(echo "extendedKeyUsage = clientAuth")
}
```

### 7. Security Event Logging

#### Implement Security Event Logger
```csharp
public interface ISecurityEventLogger
{
    void LogCertificateValidationSuccess(CertificateValidationResult result);
    void LogCertificateValidationFailure(CertificateValidationResult result);
    void LogUnauthorizedAccess(string? thumbprint, string operation);
    void LogSecurityConfigurationChange(string setting, string oldValue, string newValue);
}
```

### 8. Health Checks

#### Create CertificateHealthCheck
```csharp
public class CertificateHealthCheck : IHealthCheck
{
    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        try
        {
            // Check server certificate
            var serverCert = await _certificateLoader.LoadServerCertificateAsync(_options.ServerCertificate);
            
            var data = new Dictionary<string, object>
            {
                ["ServerCertificateSubject"] = serverCert.Subject,
                ["ServerCertificateExpiry"] = serverCert.NotAfter,
                ["DaysUntilExpiry"] = (serverCert.NotAfter - DateTime.UtcNow).Days,
                ["MtlsEnabled"] = _options.Mtls.Enabled,
                ["RequireClientCertificate"] = _options.Mtls.RequireClientCertificate
            };

            if ((serverCert.NotAfter - DateTime.UtcNow).Days < 30)
            {
                return HealthCheckResult.Degraded("Server certificate expiring soon", data: data);
            }

            return HealthCheckResult.Healthy("Certificate configuration is healthy", data: data);
        }
        catch (Exception ex)
        {
            return HealthCheckResult.Unhealthy("Certificate configuration error", ex);
        }
    }
}
```

### 9. Configuration Examples

#### Production appsettings.json
```json
{
  "Security": {
    "Mtls": {
      "Enabled": true,
      "RequireClientCertificate": true,
      "CheckCertificateRevocation": true,
      "AllowedIssuers": [
        "CN=Supacrypt Production CA, O=Supacrypt, C=US"
      ],
      "ValidateChain": true,
      "RevocationMode": "Online"
    },
    "ServerCertificate": {
      "Source": "KeyVault",
      "KeyVaultName": "supacrypt-prod-kv",
      "CertificateName": "supacrypt-server"
    }
  }
}
```

#### Development appsettings.Development.json
```json
{
  "Security": {
    "Mtls": {
      "Enabled": false, // Can disable for local testing
      "CheckCertificateRevocation": false,
      "AllowedThumbprints": [
        "AABBCCDDEE..." // Development certificate thumbprints
      ]
    },
    "ServerCertificate": {
      "Source": "File",
      "Path": "certs/localhost.pfx",
      "Password": "" // Should use user secrets in practice
    }
  }
}
```

### 10. Integration with Existing Services

#### Update ServiceCollectionExtensions
```csharp
public static IServiceCollection AddSupacryptSecurity(
    this IServiceCollection services,
    IConfiguration configuration)
{
    services.Configure<SecurityOptions>(configuration.GetSection("Security"));
    
    services.AddSingleton<ICertificateLoader, CertificateLoader>();
    services.AddScoped<ICertificateValidationService, CertificateValidationService>();
    services.AddSingleton<ISecurityEventLogger, SecurityEventLogger>();
    
    services.AddAuthentication(CertificateAuthenticationDefaults.AuthenticationScheme)
        .AddCertificate(options =>
        {
            options.Events = new CertificateAuthenticationEvents
            {
                OnCertificateValidated = context =>
                {
                    // Additional validation logic
                    return Task.CompletedTask;
                }
            };
        });
    
    return services;
}
```

## Implementation Steps

1. **Create Security Infrastructure**
   - Implement certificate validation service
   - Create certificate loader with multiple sources
   - Add security event logging

2. **Configure Kestrel**
   - Update Program.cs with mTLS configuration
   - Add certificate authentication middleware
   - Configure authorization policies

3. **Implement Certificate Management**
   - Create certificate generation scripts
   - Document certificate deployment procedures
   - Add certificate rotation guidance

4. **Update Service Layer**
   - Add authorization attributes to gRPC service
   - Implement certificate-based identity mapping
   - Add security context to logging

5. **Testing and Validation**
   - Create unit tests for certificate validation
   - Test with self-signed certificates
   - Verify revocation checking works

## Validation Criteria
Your implementation will be considered complete when:
1. ✅ mTLS enforced for all gRPC endpoints
2. ✅ Certificate validation service fully implemented
3. ✅ Multiple certificate sources supported (file, store, Key Vault)
4. ✅ Authorization policies configured and applied
5. ✅ Security event logging operational
6. ✅ Health checks for certificate configuration
7. ✅ Development certificate generation scripts provided
8. ✅ Configuration supports both production and development scenarios
9. ✅ All security tests passing

## Important Security Considerations
- Never commit private keys or passwords to source control
- Use Azure Key Vault for production certificate storage
- Implement proper certificate rotation procedures
- Consider certificate pinning for additional security
- Enable audit logging for all security events
- Test certificate revocation in production-like environment

## Memory Bank Logging
Document your work in `supacrypt-common/Memory/Phase_2_Backend_Service/Task_2_4_Security_Implementation_Log.md` following the established format. Include:
- Security decisions and rationale
- Certificate validation approach
- Performance impact of mTLS
- Testing procedures
- Production deployment considerations

Begin by reviewing the current security configuration and planning the certificate infrastructure.