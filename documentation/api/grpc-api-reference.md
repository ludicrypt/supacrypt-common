# Supacrypt gRPC API Reference

## Overview

The Supacrypt gRPC API provides the core interface for all cryptographic operations in the Supacrypt suite. This API is used by all cryptographic providers (PKCS#11, CSP, KSP, CTK) and can also be used directly by applications requiring cryptographic services.

## Service Definition

### SupacryptService

The main service interface providing all cryptographic operations.

```protobuf
syntax = "proto3";

package supacrypt.v1;

service SupacryptService {
  // Key Management Operations
  rpc GenerateKey(GenerateKeyRequest) returns (GenerateKeyResponse);
  rpc GetKey(GetKeyRequest) returns (GetKeyResponse);
  rpc ListKeys(ListKeysRequest) returns (ListKeysResponse);
  rpc DeleteKey(DeleteKeyRequest) returns (DeleteKeyResponse);
  
  // Cryptographic Operations
  rpc SignData(SignDataRequest) returns (SignDataResponse);
  rpc VerifySignature(VerifySignatureRequest) returns (VerifySignatureResponse);
  rpc EncryptData(EncryptDataRequest) returns (EncryptDataResponse);
  rpc DecryptData(DecryptDataRequest) returns (DecryptDataResponse);
  
  // Health and Status
  rpc HealthCheck(HealthCheckRequest) returns (HealthCheckResponse);
  rpc GetVersion(GetVersionRequest) returns (GetVersionResponse);
}
```

## Message Definitions

### Key Management Messages

#### GenerateKeyRequest
```protobuf
message GenerateKeyRequest {
  string key_id = 1;                    // Unique identifier for the key
  KeyType key_type = 2;                 // Type of key to generate
  uint32 key_size = 3;                  // Key size in bits
  KeyUsage key_usage = 4;               // Intended usage for the key
  map<string, string> attributes = 5;   // Additional key attributes
  string client_id = 6;                 // Client identifier for audit
}

enum KeyType {
  KEY_TYPE_UNSPECIFIED = 0;
  KEY_TYPE_RSA = 1;
  KEY_TYPE_ECDSA = 2;
  KEY_TYPE_AES = 3;
  KEY_TYPE_HMAC = 4;
}

enum KeyUsage {
  KEY_USAGE_UNSPECIFIED = 0;
  KEY_USAGE_SIGNING = 1;
  KEY_USAGE_ENCRYPTION = 2;
  KEY_USAGE_BOTH = 3;
}
```

#### GenerateKeyResponse
```protobuf
message GenerateKeyResponse {
  string key_id = 1;                    // Generated key identifier
  bytes public_key = 2;                 // Public key (for asymmetric keys)
  KeyMetadata metadata = 3;             // Key metadata
  OperationStatus status = 4;           // Operation result status
}

message KeyMetadata {
  string key_id = 1;
  KeyType key_type = 2;
  uint32 key_size = 3;
  KeyUsage key_usage = 4;
  google.protobuf.Timestamp created_at = 5;
  google.protobuf.Timestamp expires_at = 6;
  map<string, string> attributes = 7;
  string azure_key_vault_id = 8;       // Azure Key Vault reference
}
```

#### GetKeyRequest / GetKeyResponse
```protobuf
message GetKeyRequest {
  string key_id = 1;                    // Key identifier to retrieve
  string client_id = 2;                 // Client identifier for audit
}

message GetKeyResponse {
  KeyMetadata metadata = 1;             // Key metadata
  bytes public_key = 2;                 // Public key (if applicable)
  OperationStatus status = 3;           // Operation result status
}
```

#### ListKeysRequest / ListKeysResponse
```protobuf
message ListKeysRequest {
  string client_id = 1;                 // Client identifier
  KeyType key_type_filter = 2;          // Optional filter by key type
  KeyUsage key_usage_filter = 3;        // Optional filter by usage
  uint32 page_size = 4;                 // Number of keys per page
  string page_token = 5;                // Token for pagination
}

message ListKeysResponse {
  repeated KeyMetadata keys = 1;        // List of key metadata
  string next_page_token = 2;           // Token for next page
  uint32 total_count = 3;               // Total number of keys
  OperationStatus status = 4;           // Operation result status
}
```

#### DeleteKeyRequest / DeleteKeyResponse
```protobuf
message DeleteKeyRequest {
  string key_id = 1;                    // Key identifier to delete
  string client_id = 2;                 // Client identifier for audit
  bool force_delete = 3;                // Force deletion even if key is in use
}

message DeleteKeyResponse {
  string key_id = 1;                    // Deleted key identifier
  OperationStatus status = 2;           // Operation result status
}
```

### Cryptographic Operation Messages

#### SignDataRequest / SignDataResponse
```protobuf
message SignDataRequest {
  string key_id = 1;                    // Key to use for signing
  bytes data = 2;                       // Data to sign
  SignatureAlgorithm algorithm = 3;     // Signature algorithm
  string client_id = 4;                 // Client identifier for audit
}

enum SignatureAlgorithm {
  SIGNATURE_ALGORITHM_UNSPECIFIED = 0;
  SIGNATURE_ALGORITHM_RSA_PSS_SHA256 = 1;
  SIGNATURE_ALGORITHM_RSA_PKCS1_SHA256 = 2;
  SIGNATURE_ALGORITHM_ECDSA_SHA256 = 3;
  SIGNATURE_ALGORITHM_ECDSA_SHA384 = 4;
  SIGNATURE_ALGORITHM_ECDSA_SHA512 = 5;
}

message SignDataResponse {
  bytes signature = 1;                  // Generated signature
  SignatureAlgorithm algorithm = 2;     // Algorithm used
  OperationStatus status = 3;           // Operation result status
}
```

#### VerifySignatureRequest / VerifySignatureResponse
```protobuf
message VerifySignatureRequest {
  string key_id = 1;                    // Key to use for verification
  bytes data = 2;                       // Original data
  bytes signature = 3;                  // Signature to verify
  SignatureAlgorithm algorithm = 4;     // Signature algorithm
  string client_id = 5;                 // Client identifier for audit
}

message VerifySignatureResponse {
  bool is_valid = 1;                    // Verification result
  OperationStatus status = 2;           // Operation result status
}
```

#### EncryptDataRequest / EncryptDataResponse
```protobuf
message EncryptDataRequest {
  string key_id = 1;                    // Key to use for encryption
  bytes plaintext = 2;                  // Data to encrypt
  EncryptionAlgorithm algorithm = 3;    // Encryption algorithm
  bytes initialization_vector = 4;      // IV (for symmetric encryption)
  string client_id = 5;                 // Client identifier for audit
}

enum EncryptionAlgorithm {
  ENCRYPTION_ALGORITHM_UNSPECIFIED = 0;
  ENCRYPTION_ALGORITHM_RSA_OAEP = 1;
  ENCRYPTION_ALGORITHM_RSA_PKCS1 = 2;
  ENCRYPTION_ALGORITHM_AES_GCM = 3;
  ENCRYPTION_ALGORITHM_AES_CBC = 4;
}

message EncryptDataResponse {
  bytes ciphertext = 1;                 // Encrypted data
  bytes initialization_vector = 2;      // IV used (if generated)
  EncryptionAlgorithm algorithm = 3;    // Algorithm used
  OperationStatus status = 4;           // Operation result status
}
```

#### DecryptDataRequest / DecryptDataResponse
```protobuf
message DecryptDataRequest {
  string key_id = 1;                    // Key to use for decryption
  bytes ciphertext = 2;                 // Data to decrypt
  EncryptionAlgorithm algorithm = 3;    // Encryption algorithm
  bytes initialization_vector = 4;      // IV (for symmetric encryption)
  string client_id = 5;                 // Client identifier for audit
}

message DecryptDataResponse {
  bytes plaintext = 1;                  // Decrypted data
  OperationStatus status = 2;           // Operation result status
}
```

### Status and Health Messages

#### OperationStatus
```protobuf
message OperationStatus {
  StatusCode code = 1;                  // Operation result code
  string message = 2;                   // Human-readable message
  map<string, string> details = 3;      // Additional status details
}

enum StatusCode {
  STATUS_CODE_UNSPECIFIED = 0;
  STATUS_CODE_SUCCESS = 1;
  STATUS_CODE_INVALID_ARGUMENT = 2;
  STATUS_CODE_NOT_FOUND = 3;
  STATUS_CODE_PERMISSION_DENIED = 4;
  STATUS_CODE_ALREADY_EXISTS = 5;
  STATUS_CODE_INTERNAL_ERROR = 6;
  STATUS_CODE_UNAVAILABLE = 7;
  STATUS_CODE_UNAUTHENTICATED = 8;
}
```

#### HealthCheckRequest / HealthCheckResponse
```protobuf
message HealthCheckRequest {
  string service = 1;                   // Service to check (optional)
}

message HealthCheckResponse {
  HealthStatus status = 1;              // Overall health status
  map<string, HealthStatus> services = 2; // Per-service status
  string version = 3;                   // Service version
  google.protobuf.Timestamp timestamp = 4; // Check timestamp
}

enum HealthStatus {
  HEALTH_STATUS_UNKNOWN = 0;
  HEALTH_STATUS_SERVING = 1;
  HEALTH_STATUS_NOT_SERVING = 2;
  HEALTH_STATUS_SERVICE_UNKNOWN = 3;
}
```

## Authentication

### Client Certificate Authentication

All gRPC calls require client certificate authentication:

```go
// Example Go client setup
conn, err := grpc.Dial("supacrypt-backend:5051", 
    grpc.WithTransportCredentials(credentials.NewTLS(&tls.Config{
        Certificates: []tls.Certificate{clientCert},
        RootCAs:      rootCAs,
    })))
```

### Authentication Metadata

Include client identification in gRPC metadata:

```go
ctx := metadata.AppendToOutgoingContext(context.Background(),
    "client-id", "my-application",
    "client-version", "1.0.0")
```

## Error Handling

### Standard Error Codes

| gRPC Status | StatusCode | Description |
|-------------|------------|-------------|
| OK | STATUS_CODE_SUCCESS | Operation completed successfully |
| INVALID_ARGUMENT | STATUS_CODE_INVALID_ARGUMENT | Invalid request parameters |
| NOT_FOUND | STATUS_CODE_NOT_FOUND | Requested key or resource not found |
| PERMISSION_DENIED | STATUS_CODE_PERMISSION_DENIED | Insufficient permissions |
| ALREADY_EXISTS | STATUS_CODE_ALREADY_EXISTS | Resource already exists |
| INTERNAL | STATUS_CODE_INTERNAL_ERROR | Internal server error |
| UNAVAILABLE | STATUS_CODE_UNAVAILABLE | Service temporarily unavailable |
| UNAUTHENTICATED | STATUS_CODE_UNAUTHENTICATED | Authentication failed |

### Error Response Example

```json
{
  "status": {
    "code": "STATUS_CODE_NOT_FOUND",
    "message": "Key with ID 'my-key-123' not found",
    "details": {
      "key_id": "my-key-123",
      "client_id": "my-application",
      "timestamp": "2025-01-06T10:30:00Z"
    }
  }
}
```

## Usage Examples

### Key Generation Example

```go
client := supacrypt.NewSupacryptServiceClient(conn)

request := &supacrypt.GenerateKeyRequest{
    KeyId:    "my-rsa-key-001",
    KeyType:  supacrypt.KeyType_KEY_TYPE_RSA,
    KeySize:  2048,
    KeyUsage: supacrypt.KeyUsage_KEY_USAGE_SIGNING,
    ClientId: "my-application",
    Attributes: map[string]string{
        "purpose": "document-signing",
        "department": "legal",
    },
}

response, err := client.GenerateKey(ctx, request)
if err != nil {
    log.Fatalf("Key generation failed: %v", err)
}

if response.Status.Code != supacrypt.StatusCode_STATUS_CODE_SUCCESS {
    log.Fatalf("Operation failed: %s", response.Status.Message)
}

fmt.Printf("Generated key: %s\n", response.KeyId)
```

### Digital Signature Example

```go
// Sign data
signRequest := &supacrypt.SignDataRequest{
    KeyId:     "my-rsa-key-001",
    Data:      []byte("Important document content"),
    Algorithm: supacrypt.SignatureAlgorithm_SIGNATURE_ALGORITHM_RSA_PSS_SHA256,
    ClientId:  "my-application",
}

signResponse, err := client.SignData(ctx, signRequest)
if err != nil {
    log.Fatalf("Signing failed: %v", err)
}

signature := signResponse.Signature

// Verify signature
verifyRequest := &supacrypt.VerifySignatureRequest{
    KeyId:     "my-rsa-key-001",
    Data:      []byte("Important document content"),
    Signature: signature,
    Algorithm: supacrypt.SignatureAlgorithm_SIGNATURE_ALGORITHM_RSA_PSS_SHA256,
    ClientId:  "my-application",
}

verifyResponse, err := client.VerifySignature(ctx, verifyRequest)
if err != nil {
    log.Fatalf("Verification failed: %v", err)
}

if verifyResponse.IsValid {
    fmt.Println("Signature is valid")
} else {
    fmt.Println("Signature is invalid")
}
```

## Performance Considerations

### Connection Management
- Use connection pooling for multiple concurrent operations
- Reuse gRPC connections when possible
- Implement proper connection lifecycle management

### Request Optimization
- Batch operations when possible
- Use streaming for large data operations
- Implement proper timeout handling

### Error Retry Logic
```go
func retryWithBackoff(operation func() error) error {
    backoff := time.Second
    maxRetries := 3
    
    for i := 0; i < maxRetries; i++ {
        err := operation()
        if err == nil {
            return nil
        }
        
        if status.Code(err) == codes.Unavailable {
            time.Sleep(backoff)
            backoff *= 2
            continue
        }
        
        return err // Don't retry non-transient errors
    }
    
    return fmt.Errorf("operation failed after %d retries", maxRetries)
}
```

## Security Considerations

### Input Validation
- All inputs are validated server-side
- Maximum payload sizes enforced
- Malformed requests rejected with appropriate errors

### Audit Logging
- All operations are logged with client identification
- Sensitive data (keys, plaintext) never logged
- Comprehensive audit trail for compliance

### Rate Limiting
- Per-client rate limiting implemented
- Burst capacity for legitimate high-volume operations
- DDoS protection through connection limits

## Client SDKs

### Supported Languages
- **Go**: Native gRPC support with generated client
- **C#/.NET**: Full integration with .NET ecosystem
- **Python**: Generated client with async support
- **Java**: Generated client with Spring Boot integration
- **C/C++**: Generated client for native applications

### SDK Installation
```bash
# Go
go get github.com/supacrypt/go-client

# .NET
dotnet add package Supacrypt.Client

# Python
pip install supacrypt-client
```

This gRPC API provides a comprehensive, secure, and high-performance interface for all cryptographic operations in the Supacrypt suite, with full support for authentication, error handling, and observability.