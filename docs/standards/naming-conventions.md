# Naming Conventions for Cross-Component Elements

## Overview

This document establishes consistent naming conventions across all Supacrypt components to ensure interoperability and maintainability between the backend service, PKCS#11 provider, Windows CSP/KSP, and macOS CTK implementations.

## gRPC Services and Methods

### Service Naming Patterns
- Services use PascalCase with descriptive names
- Core service: `SupacryptService` (already established in protobuf)
- Management services follow pattern: `[Domain]ManagementService`

```protobuf
service SupacryptService {
  // Core cryptographic operations
}

service KeyManagementService {
  // Key lifecycle management
}

service CertificateManagementService {
  // Certificate operations
}
```

### Method Naming Consistency
- Methods use PascalCase verbs describing the action
- Follow CRUD pattern: Create, Get, Update, Delete
- Async operations include operation type in name

```protobuf
service SupacryptService {
  // Key operations
  rpc GenerateKey(GenerateKeyRequest) returns (GenerateKeyResponse);
  rpc GetKey(GetKeyRequest) returns (GetKeyResponse);
  rpc DeleteKey(DeleteKeyRequest) returns (DeleteKeyResponse);
  
  // Cryptographic operations
  rpc SignData(SignRequest) returns (SignResponse);
  rpc VerifySignature(VerifyRequest) returns (VerifyResponse);
  rpc EncryptData(EncryptRequest) returns (EncryptResponse);
  rpc DecryptData(DecryptRequest) returns (DecryptResponse);
  
  // Bulk operations
  rpc ListKeys(ListKeysRequest) returns (ListKeysResponse);
  rpc ImportKeys(ImportKeysRequest) returns (ImportKeysResponse);
}
```

### Request/Response Message Naming
- Request messages: `[MethodName]Request`
- Response messages: `[MethodName]Response`
- Common data structures: `[EntityName]Info` or `[EntityName]Data`

```protobuf
message GenerateKeyRequest {
  string key_id = 1;
  KeyType key_type = 2;
  uint32 key_size = 3;
}

message GenerateKeyResponse {
  bool success = 1;
  string key_id = 2;
  bytes public_key = 3;
  ErrorInfo error = 4;
}

message KeyInfo {
  string id = 1;
  KeyType type = 2;
  uint32 size = 3;
  int64 created_at = 4;
}
```

## Configuration Parameters

### Environment Variable Naming
- All environment variables prefixed with `SUPACRYPT_`
- Use SCREAMING_SNAKE_CASE for environment variables
- Organize by component and function

```bash
# Core configuration
SUPACRYPT_LOG_LEVEL=Information
SUPACRYPT_ENVIRONMENT=Production

# Backend service
SUPACRYPT_BACKEND_HOST=0.0.0.0
SUPACRYPT_BACKEND_PORT=50051
SUPACRYPT_BACKEND_USE_TLS=true

# Azure Key Vault
SUPACRYPT_KEYVAULT_URL=https://example.vault.azure.net/
SUPACRYPT_KEYVAULT_CLIENT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
SUPACRYPT_KEYVAULT_CLIENT_SECRET=xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
SUPACRYPT_KEYVAULT_TENANT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# Provider configuration
SUPACRYPT_PROVIDER_TIMEOUT_MS=30000
SUPACRYPT_PROVIDER_RETRY_ATTEMPTS=3
SUPACRYPT_PROVIDER_CACHE_TTL_SECONDS=300

# Security settings
SUPACRYPT_CRYPTO_DEFAULT_KEY_SIZE=2048
SUPACRYPT_CRYPTO_SUPPORTED_ALGORITHMS=RSA-PSS,ECDSA-P256,ECDSA-P384

# Observability
SUPACRYPT_TELEMETRY_ENDPOINT=http://localhost:4317
SUPACRYPT_TELEMETRY_SERVICE_NAME=supacrypt-backend
SUPACRYPT_METRICS_EXPORT_INTERVAL_MS=5000
```

### Configuration File Section Naming
- Use PascalCase for configuration sections
- Mirror environment variable structure without prefix

```json
{
  "Supacrypt": {
    "Backend": {
      "Host": "0.0.0.0",
      "Port": 50051,
      "UseTls": true
    },
    "KeyVault": {
      "Url": "https://example.vault.azure.net/",
      "ClientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      "TenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    },
    "Provider": {
      "TimeoutMs": 30000,
      "RetryAttempts": 3,
      "CacheTtlSeconds": 300
    }
  }
}
```

### Secret and Credential Naming
- Secrets follow pattern: `SUPACRYPT_[COMPONENT]_[TYPE]_[PURPOSE]`
- Use specific descriptive names for different credential types

```bash
# Azure credentials
SUPACRYPT_KEYVAULT_CLIENT_SECRET=xxxxx
SUPACRYPT_KEYVAULT_CERTIFICATE_PATH=/path/to/cert.pfx
SUPACRYPT_KEYVAULT_CERTIFICATE_PASSWORD=xxxxx

# Database credentials
SUPACRYPT_DATABASE_CONNECTION_STRING=xxxxx
SUPACRYPT_DATABASE_ENCRYPTION_KEY=xxxxx

# API credentials
SUPACRYPT_API_AUTHENTICATION_TOKEN=xxxxx
SUPACRYPT_API_SIGNING_KEY=xxxxx

# TLS credentials
SUPACRYPT_TLS_CERTIFICATE_PATH=/path/to/tls.crt
SUPACRYPT_TLS_PRIVATE_KEY_PATH=/path/to/tls.key
```

## OpenTelemetry Metrics and Traces

### Metric Naming Conventions
- Use dot notation: `supacrypt.[component].[metric_type].[name]`
- Include units in metric name where appropriate
- Use consistent naming patterns across components

```csharp
// Operation counters
supacrypt.operations.count
supacrypt.operations.duration_ms
supacrypt.operations.errors_total

// Key management metrics
supacrypt.keys.generated_total
supacrypt.keys.active_count
supacrypt.keys.cache_hits_total
supacrypt.keys.cache_misses_total

// Provider-specific metrics
supacrypt.backend.requests_total
supacrypt.backend.response_time_ms
supacrypt.pkcs11.operations_total
supacrypt.csp.operations_total
supacrypt.ksp.operations_total
supacrypt.ctk.operations_total

// Azure Key Vault metrics
supacrypt.keyvault.requests_total
supacrypt.keyvault.response_time_ms
supacrypt.keyvault.throttled_requests_total

// System metrics
supacrypt.memory.usage_bytes
supacrypt.cpu.usage_percent
supacrypt.connections.active_count
```

### Trace Span Naming Patterns
- Use hierarchical naming: `[component].[operation].[sub_operation]`
- Start with verb describing the action
- Include context information in span names

```csharp
// Service operations
SupacryptService.GenerateKey
SupacryptService.SignData
SupacryptService.EncryptData

// Internal operations
KeyManager.CreateRsaKey
KeyManager.ValidateKeyParameters
CryptoProvider.ExecuteSignOperation

// External service calls
AzureKeyVault.GenerateKey
AzureKeyVault.GetKey
AzureKeyVault.SignData

// Provider operations
PKCS11Provider.C_GenerateKeyPair
WindowsCSP.CPGenKey
WindowsKSP.NCryptCreatePersistedKey
MacOSCTK.GenerateKeyPair
```

### Attribute Naming Standards
- Use snake_case for attribute names
- Include standard attributes for correlation
- Provide context-specific attributes

```csharp
// Standard attributes
operation_id = "op_12345"
correlation_id = "corr_67890"
user_id = "user_abcde"
request_id = "req_xyz123"

// Cryptographic operation attributes
key_id = "key_rsa2048_001"
key_type = "RSA"
key_size = 2048
algorithm = "RSA-PSS"
operation_type = "sign"

// Provider-specific attributes
provider_type = "pkcs11" | "csp" | "ksp" | "ctk"
provider_name = "Supacrypt PKCS#11 Provider"
token_id = "token_001"
slot_id = "slot_001"

// Performance attributes
duration_ms = 150
cache_hit = true
retry_attempt = 2

// Error attributes
error_code = 2001
error_message = "Invalid key size"
error_category = "validation" | "cryptographic" | "system"
```

### Tag Conventions for Components
- Use consistent tag naming across all components
- Include component identification and version information

```yaml
# Common tags for all components
component: "supacrypt-backend" | "supacrypt-pkcs11" | "supacrypt-csp" | "supacrypt-ksp" | "supacrypt-ctk"
version: "1.0.0"
environment: "development" | "staging" | "production"
service_name: "supacrypt"

# Backend service specific tags
service_type: "grpc"
deployment_region: "us-east-1"
instance_id: "backend-001"

# Provider specific tags
provider_platform: "windows" | "macos" | "linux"
crypto_backend: "azure_keyvault" | "local_hsm" | "software"
security_level: "hardware" | "software"

# Azure Key Vault tags
keyvault_name: "supacrypt-prod-kv"
keyvault_region: "eastus"
hsm_type: "standard" | "premium"
```

## Component-Specific Naming

### PKCS#11 Provider Naming
- Follow PKCS#11 specification naming conventions
- Use descriptive manufacturer and library names

```c
// Library identification
CK_INFO libraryInfo = {
    .cryptokiVersion = {2, 40},
    .manufacturerID = "Supacrypt Project       ", // 32 chars, padded
    .flags = 0,
    .libraryDescription = "Supacrypt PKCS#11 Provider  ", // 32 chars, padded
    .libraryVersion = {1, 0}
};

// Token information
CK_TOKEN_INFO tokenInfo = {
    .label = "Supacrypt Token         ", // 32 chars, padded
    .manufacturerID = "Supacrypt Project       ", // 32 chars, padded
    .model = "SupToken        ", // 16 chars, padded
    .serialNumber = "0000000000000001", // 16 chars
    .flags = CKF_TOKEN_INITIALIZED | CKF_WRITE_PROTECTED,
    .ulMaxSessionCount = CK_EFFECTIVELY_INFINITE,
    .ulSessionCount = 0,
    .ulMaxRwSessionCount = CK_EFFECTIVELY_INFINITE,
    .ulRwSessionCount = 0,
    .ulMaxPinLen = 255,
    .ulMinPinLen = 4,
    .ulTotalPublicMemory = CK_UNAVAILABLE_INFORMATION,
    .ulFreePublicMemory = CK_UNAVAILABLE_INFORMATION,
    .ulTotalPrivateMemory = CK_UNAVAILABLE_INFORMATION,
    .ulFreePrivateMemory = CK_UNAVAILABLE_INFORMATION,
    .hardwareVersion = {1, 0},
    .firmwareVersion = {1, 0},
    .utcTime = ""
};
```

### Windows CSP/KSP Naming
- Follow Microsoft naming conventions
- Use descriptive provider names and types

```c
// CSP Provider registration
#define SUPACRYPT_CSP_NAME L"Supacrypt Cryptographic Provider"
#define SUPACRYPT_CSP_TYPE PROV_RSA_FULL
#define SUPACRYPT_CSP_VERSION 0x00010000

// KSP Provider registration
#define SUPACRYPT_KSP_NAME L"Supacrypt Key Storage Provider"
#define SUPACRYPT_KSP_VERSION BCRYPT_MAKE_INTERFACE_VERSION(1, 0)

// Registry keys
#define SUPACRYPT_CSP_REGISTRY_PATH L"SOFTWARE\\Microsoft\\Cryptography\\Defaults\\Provider\\Supacrypt Cryptographic Provider"
#define SUPACRYPT_KSP_REGISTRY_PATH L"SOFTWARE\\Microsoft\\Cryptography\\CNGKeyStorageProviders\\Supacrypt Key Storage Provider"
```

### macOS CTK Provider Naming
- Follow Apple naming conventions
- Use reverse DNS notation for bundle identifiers

```objc
// Bundle identification
#define SUPACRYPT_CTK_BUNDLE_ID @"com.supacrypt.cryptotoken"
#define SUPACRYPT_CTK_VERSION @"1.0.0"

// Token information
#define SUPACRYPT_TOKEN_NAME @"Supacrypt Token"
#define SUPACRYPT_TOKEN_INSTANCE_ID @"com.supacrypt.token.instance.001"

// Keychain attributes
#define SUPACRYPT_KEYCHAIN_ACCESS_GROUP @"com.supacrypt.keychain"
#define SUPACRYPT_KEY_TAG_PREFIX @"com.supacrypt.key."
```

## File and Directory Naming

### Source Code Organization
- Use consistent directory structure across components
- Follow language-specific conventions

```
supacrypt-backend/
├── src/
│   ├── Supacrypt.Backend.Api/
│   ├── Supacrypt.Backend.Services/
│   ├── Supacrypt.Backend.Common/
│   └── Supacrypt.Backend.Tests/
├── docs/
└── scripts/

supacrypt-pkcs11/
├── src/
│   ├── supacrypt/
│   │   ├── pkcs11/
│   │   ├── common/
│   │   └── platform/
├── include/
│   └── supacrypt/
├── tests/
└── docs/

supacrypt-csp/
├── src/
│   ├── csp/
│   ├── common/
│   └── registry/
├── include/
└── tests/

supacrypt-ksp/
├── src/
│   ├── ksp/
│   ├── common/
│   └── registry/
├── include/
└── tests/

supacrypt-ctk/
├── src/
│   ├── ctk/
│   ├── common/
│   └── keychain/
├── include/
└── tests/
```

### Binary and Library Naming
- Use consistent naming across platforms
- Include version information where appropriate

```bash
# Shared libraries
libsupacrypt-pkcs11.so.1.0.0    # Linux
libsupacrypt-pkcs11.1.0.0.dylib # macOS
supacrypt-pkcs11.dll             # Windows

# Provider libraries
supacrypt-csp.dll                # Windows CSP
supacrypt-ksp.dll                # Windows KSP
SupacryptToken.appex             # macOS CTK Extension

# Executables
supacrypt-backend                # Backend service
supacrypt-cli                    # Command line tool
supacrypt-test                   # Test utilities
```

## API Versioning

### Version Scheme
- Use semantic versioning (SemVer) for all components
- Include API version in protobuf package names
- Maintain backwards compatibility

```protobuf
// Current version
package supacrypt.v1;

// Future versions
package supacrypt.v2;
package supacrypt.v1beta1;
```

### Compatibility Naming
- Use version-specific naming for breaking changes
- Maintain legacy support where required

```csharp
// Version-specific interfaces
public interface ISupacryptServiceV1
{
    Task<GenerateKeyResponse> GenerateKeyAsync(GenerateKeyRequest request);
}

public interface ISupacryptServiceV2
{
    Task<GenerateKeyResponseV2> GenerateKeyAsync(GenerateKeyRequestV2 request);
}

// Backwards compatibility
[Obsolete("Use ISupacryptServiceV2", false)]
public interface ISupacryptService : ISupacryptServiceV1
{
}
```

## Documentation Naming

### File Naming Conventions
- Use kebab-case for documentation files
- Include component prefix for component-specific docs

```
docs/
├── api/
│   ├── grpc-service-reference.md
│   ├── error-codes-reference.md
│   └── authentication-guide.md
├── guides/
│   ├── getting-started.md
│   ├── deployment-guide.md
│   └── troubleshooting-guide.md
├── components/
│   ├── backend-service-guide.md
│   ├── pkcs11-provider-guide.md
│   ├── windows-csp-guide.md
│   ├── windows-ksp-guide.md
│   └── macos-ctk-guide.md
└── standards/
    ├── cpp-coding-standards.md
    ├── csharp-coding-standards.md
    └── naming-conventions.md
```

## Best Practices

### Consistency Rules
1. Always use the established naming pattern for the context
2. Include component identification in cross-component communications
3. Use descriptive names that convey purpose and context
4. Follow platform conventions while maintaining cross-platform consistency

### Validation Guidelines
- Validate naming conventions in CI/CD pipelines
- Use linting tools to enforce naming standards
- Document exceptions to naming rules with justification

### Evolution Strategy
- Plan for future naming needs
- Maintain backwards compatibility during transitions
- Use deprecation warnings for naming changes
- Document naming evolution in change logs

## References

- [gRPC Style Guide](https://developers.google.com/protocol-buffers/docs/style)
- [OpenTelemetry Semantic Conventions](https://opentelemetry.io/docs/specs/otel/resource/semantic_conventions/)
- [Microsoft Naming Guidelines](https://docs.microsoft.com/en-us/dotnet/standard/design-guidelines/naming-guidelines)
- [PKCS #11 v3.0 Specification](http://docs.oasis-open.org/pkcs11/pkcs11-spec/v3.0/pkcs11-spec-v3.0.html)
- [Apple CryptoTokenKit Documentation](https://developer.apple.com/documentation/cryptotokenkit)
- [Semantic Versioning](https://semver.org/)