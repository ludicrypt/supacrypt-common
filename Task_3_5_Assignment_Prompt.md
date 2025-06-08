# Task Assignment: Documentation and Examples

## Agent Profile
**Type:** Implementation Agent - Technical Writer  
**Expertise Required:** Technical Documentation, PKCS#11 Specification, API Documentation, Cross-Platform Systems, Cryptographic Concepts

## Task Overview
Create comprehensive documentation and examples for the supacrypt-pkcs11 provider, including user guides, API reference, installation instructions, configuration documentation, troubleshooting guides, and working code examples for all major use cases.

## Context
- **Repository:** `supacrypt-pkcs11`
- **Current State:** Fully implemented and tested PKCS#11 provider with gRPC backend
- **Target:** Production-ready documentation for users, developers, and integrators
- **Audience:** System administrators, developers, security engineers

## Detailed Requirements

### 1. Main README Documentation

#### README.md
```markdown
# Supacrypt PKCS#11 Provider

[![Build Status](https://github.com/supacrypt/supacrypt-pkcs11/workflows/CI/badge.svg)](https://github.com/supacrypt/supacrypt-pkcs11/actions)
[![Coverage](https://codecov.io/gh/supacrypt/supacrypt-pkcs11/branch/main/graph/badge.svg)](https://codecov.io/gh/supacrypt/supacrypt-pkcs11)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A high-performance PKCS#11 cryptographic provider that delegates operations to a secure backend service via gRPC.

## Features

- 🔐 **PKCS#11 v2.40 Compliant** - Full compatibility with industry standards
- 🚀 **High Performance** - <50ms signing operations with connection pooling
- 🔒 **Secure Backend** - All cryptographic operations performed in Azure Key Vault
- 🌐 **Cross-Platform** - Windows, Linux, and macOS support
- 🛡️ **mTLS Authentication** - Mutual TLS for secure backend communication
- 📊 **Observable** - Built-in metrics and distributed tracing support
- 🔄 **Resilient** - Circuit breaker pattern for fault tolerance

## Quick Start

### Prerequisites
- Supacrypt backend service running (see [backend setup](https://github.com/supacrypt/supacrypt-backend-akv))
- Client certificates for mTLS authentication
- C++ runtime for your platform

### Basic Usage

```cpp
#include <pkcs11.h>
#include <supacrypt/pkcs11/supacrypt_pkcs11.h>

// Configure backend connection
supacrypt_config_t config = {
    .backend_endpoint = "backend.supacrypt.local:5000",
    .client_cert_path = "/path/to/client.crt",
    .client_key_path = "/path/to/client.key",
    .ca_cert_path = "/path/to/ca.crt",
    .use_tls = true
};

// Initialize the library
SC_Configure(&config);
C_Initialize(NULL);

// Open a session
CK_SESSION_HANDLE hSession;
C_OpenSession(1, CKF_SERIAL_SESSION, NULL, NULL, &hSession);

// Generate RSA key pair
CK_MECHANISM mechanism = {CKM_RSA_PKCS_KEY_PAIR_GEN, NULL, 0};
CK_ULONG modulusBits = 2048;
CK_ATTRIBUTE publicTemplate[] = {
    {CKA_MODULUS_BITS, &modulusBits, sizeof(modulusBits)}
};

CK_OBJECT_HANDLE hPublicKey, hPrivateKey;
C_GenerateKeyPair(hSession, &mechanism, 
                  publicTemplate, 1, NULL, 0,
                  &hPublicKey, &hPrivateKey);

// Use the keys for signing...
```

## Installation

### Linux
```bash
# Install from package
sudo apt install supacrypt-pkcs11

# Or build from source
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make && sudo make install

# Configure p11-kit
echo "module: /usr/lib/supacrypt-pkcs11.so" > /etc/pkcs11/modules/supacrypt.module
```

### Windows
```powershell
# Install using installer
supacrypt-pkcs11-setup.exe

# Or use vcpkg
vcpkg install supacrypt-pkcs11
```

### macOS
```bash
# Install using Homebrew
brew tap supacrypt/crypto
brew install supacrypt-pkcs11

# Or build from source
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make && sudo make install
```

## Documentation

- [User Guide](docs/user-guide.md) - Comprehensive usage instructions
- [API Reference](docs/api-reference.md) - Detailed function documentation
- [Installation Guide](docs/installation/) - Platform-specific setup
- [Configuration Guide](docs/configuration.md) - Backend and provider settings
- [Examples](docs/examples/) - Working code samples
- [Troubleshooting](docs/troubleshooting.md) - Common issues and solutions

## Supported Algorithms

### Key Generation
- RSA: 2048, 3072, 4096 bits
- ECC: NIST P-256, P-384

### Signing/Verification
- RSA-PKCS#1 v1.5
- RSA-PSS
- ECDSA

### Hashing
- SHA-256
- SHA-384
- SHA-512

## Performance

Operation | Target | Actual
----------|--------|-------
RSA-2048 Sign | <50ms | 45ms
RSA-2048 Verify | <20ms | 18ms
ECC P-256 Sign | <30ms | 25ms
Key Generation | <2s | 1.8s

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup and guidelines.
```

### 2. User Guide Documentation

#### docs/user-guide.md
```markdown
# Supacrypt PKCS#11 User Guide

## Table of Contents
1. [Introduction](#introduction)
2. [Architecture Overview](#architecture-overview)
3. [Installation](#installation)
4. [Configuration](#configuration)
5. [Basic Operations](#basic-operations)
6. [Advanced Usage](#advanced-usage)
7. [Security Considerations](#security-considerations)
8. [Performance Tuning](#performance-tuning)

## Introduction

The Supacrypt PKCS#11 provider is a cryptographic module that implements the PKCS#11 v2.40 standard while delegating actual cryptographic operations to a secure backend service. This architecture provides:

- **Centralized key management** - Keys never leave the secure backend
- **Consistent cryptography** - All operations use backend algorithms
- **Audit trail** - All operations are logged centrally
- **High availability** - Backend can be clustered

## Architecture Overview

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│                 │     │                  │     │                 │
│  Application    │────▶│  PKCS#11 Provider│────▶│  Backend Service│
│                 │     │                  │     │                 │
└─────────────────┘     └──────────────────┘     └─────────────────┘
        │                       │                         │
        │                       │                         │
        ▼                       ▼                         ▼
   PKCS#11 API            gRPC + mTLS              Azure Key Vault
```

## Installation

### System Requirements

- **Operating System**: 
  - Linux: Ubuntu 20.04+, RHEL 8+, Debian 10+
  - Windows: Windows 10/11, Server 2019+
  - macOS: 11.0+ (Big Sur or later)
- **Architecture**: x64, ARM64
- **Dependencies**: 
  - OpenSSL 1.1.1+
  - glibc 2.27+ (Linux)
  - Visual C++ Runtime 2019+ (Windows)

### Linux Installation

#### Ubuntu/Debian
```bash
# Add Supacrypt repository
curl -fsSL https://apt.supacrypt.io/gpg | sudo apt-key add -
echo "deb https://apt.supacrypt.io stable main" | sudo tee /etc/apt/sources.list.d/supacrypt.list

# Install package
sudo apt update
sudo apt install supacrypt-pkcs11

# Verify installation
pkcs11-tool --module /usr/lib/supacrypt-pkcs11.so -I
```

#### RHEL/CentOS
```bash
# Add repository
sudo dnf config-manager --add-repo https://rpm.supacrypt.io/supacrypt.repo

# Install package
sudo dnf install supacrypt-pkcs11

# SELinux configuration (if enabled)
sudo semanage fcontext -a -t lib_t "/usr/lib64/supacrypt-pkcs11.so"
sudo restorecon -v /usr/lib64/supacrypt-pkcs11.so
```

### Windows Installation

#### Using Installer
1. Download `supacrypt-pkcs11-setup.exe` from releases
2. Run installer as Administrator
3. Choose installation directory (default: `C:\Program Files\Supacrypt`)
4. Registry entries are created automatically

#### Manual Installation
```powershell
# Copy files
Copy-Item supacrypt-pkcs11.dll "C:\Windows\System32\"

# Register in registry
New-ItemProperty -Path "HKLM:\SOFTWARE\Supacrypt\PKCS11" `
    -Name "Path" -Value "C:\Windows\System32\supacrypt-pkcs11.dll"
```

### macOS Installation

```bash
# Using Homebrew
brew tap supacrypt/crypto
brew install supacrypt-pkcs11

# Verify code signing
codesign -dv /usr/local/lib/supacrypt-pkcs11.dylib

# Allow in Security & Privacy if needed
sudo spctl --add /usr/local/lib/supacrypt-pkcs11.dylib
```

## Configuration

### Backend Connection

Configuration can be provided via:
1. Configuration file
2. Environment variables
3. Programmatic API

#### Configuration File
Create `/etc/supacrypt/pkcs11.conf` (Linux/macOS) or `%PROGRAMDATA%\Supacrypt\pkcs11.conf` (Windows):

```json
{
  "backend": {
    "endpoint": "backend.supacrypt.local:5000",
    "tls": {
      "enabled": true,
      "client_cert": "/etc/supacrypt/client.crt",
      "client_key": "/etc/supacrypt/client.key",
      "ca_cert": "/etc/supacrypt/ca.crt",
      "verify_hostname": true
    },
    "connection": {
      "timeout_ms": 30000,
      "retry_count": 3,
      "retry_delay_ms": 1000,
      "pool_size": 4
    }
  },
  "logging": {
    "enabled": true,
    "level": "info",
    "file": "/var/log/supacrypt/pkcs11.log"
  },
  "performance": {
    "cache_enabled": true,
    "cache_ttl_seconds": 300
  }
}
```

#### Environment Variables
```bash
export SUPACRYPT_BACKEND_ENDPOINT="backend.supacrypt.local:5000"
export SUPACRYPT_CLIENT_CERT="/path/to/client.crt"
export SUPACRYPT_CLIENT_KEY="/path/to/client.key"
export SUPACRYPT_CA_CERT="/path/to/ca.crt"
export SUPACRYPT_USE_TLS="true"
export SUPACRYPT_LOG_LEVEL="debug"
```

#### Programmatic Configuration
```cpp
supacrypt_config_t config = {0};
strncpy(config.backend_endpoint, "backend.supacrypt.local:5000", 
        sizeof(config.backend_endpoint));
strncpy(config.client_cert_path, "/etc/supacrypt/client.crt", 
        sizeof(config.client_cert_path));
config.use_tls = true;
config.request_timeout_ms = 30000;

CK_RV rv = SC_Configure(&config);
```

### Application Integration

#### OpenSSL Engine
```bash
# Install OpenSSL engine
openssl engine -t -c pkcs11

# Configure engine
cat > /etc/ssl/openssl.cnf <<EOF
[openssl_init]
engines = engine_section

[engine_section]
pkcs11 = pkcs11_section

[pkcs11_section]
engine_id = pkcs11
dynamic_path = /usr/lib/engines-1.1/pkcs11.so
MODULE_PATH = /usr/lib/supacrypt-pkcs11.so
init = 0
EOF

# Test
openssl pkeyutl -engine pkcs11 -sign -keyform engine \
    -inkey "pkcs11:token=Supacrypt;object=MyKey" \
    -in data.txt -out signature.bin
```

#### NSS Integration
```bash
# Add module to NSS
modutil -add "Supacrypt" -libfile /usr/lib/supacrypt-pkcs11.so \
    -dbdir sql:/etc/pki/nssdb

# List tokens
certutil -L -d sql:/etc/pki/nssdb -h "Supacrypt"
```

## Basic Operations

### Initialize and Open Session
```cpp
// Initialize library
CK_C_INITIALIZE_ARGS initArgs = {0};
initArgs.flags = CKF_OS_LOCKING_OK;
CK_RV rv = C_Initialize(&initArgs);

// Get slot list
CK_ULONG slotCount;
rv = C_GetSlotList(CK_TRUE, NULL, &slotCount);

CK_SLOT_ID_PTR pSlotList = malloc(sizeof(CK_SLOT_ID) * slotCount);
rv = C_GetSlotList(CK_TRUE, pSlotList, &slotCount);

// Open session
CK_SESSION_HANDLE hSession;
rv = C_OpenSession(pSlotList[0], CKF_SERIAL_SESSION | CKF_RW_SESSION,
                   NULL, NULL, &hSession);
```

### Generate Key Pair
```cpp
// RSA key generation
CK_MECHANISM mechanism = {CKM_RSA_PKCS_KEY_PAIR_GEN, NULL, 0};
CK_ULONG modulusBits = 2048;
CK_BYTE publicExponent[] = {0x01, 0x00, 0x01}; // 65537
CK_BBOOL true = CK_TRUE;
CK_BBOOL false = CK_FALSE;

CK_ATTRIBUTE publicTemplate[] = {
    {CKA_TOKEN, &true, sizeof(true)},
    {CKA_PRIVATE, &false, sizeof(false)},
    {CKA_MODULUS_BITS, &modulusBits, sizeof(modulusBits)},
    {CKA_PUBLIC_EXPONENT, publicExponent, sizeof(publicExponent)},
    {CKA_VERIFY, &true, sizeof(true)},
    {CKA_LABEL, "RSA Public Key", 14}
};

CK_ATTRIBUTE privateTemplate[] = {
    {CKA_TOKEN, &true, sizeof(true)},
    {CKA_PRIVATE, &true, sizeof(true)},
    {CKA_SIGN, &true, sizeof(true)},
    {CKA_LABEL, "RSA Private Key", 15}
};

CK_OBJECT_HANDLE hPublicKey, hPrivateKey;
rv = C_GenerateKeyPair(hSession, &mechanism,
                       publicTemplate, 6,
                       privateTemplate, 4,
                       &hPublicKey, &hPrivateKey);
```

### Sign Data
```cpp
// Initialize signing
CK_MECHANISM signMechanism = {CKM_RSA_PKCS, NULL, 0};
rv = C_SignInit(hSession, &signMechanism, hPrivateKey);

// Sign data
CK_BYTE data[] = "Message to sign";
CK_BYTE signature[256];
CK_ULONG signatureLen = sizeof(signature);

rv = C_Sign(hSession, data, sizeof(data) - 1, 
            signature, &signatureLen);
```

### Multi-part Operations
```cpp
// Initialize multi-part signing
rv = C_SignInit(hSession, &signMechanism, hPrivateKey);

// Process data in chunks
CK_BYTE chunk1[] = "First part of ";
CK_BYTE chunk2[] = "the message to ";
CK_BYTE chunk3[] = "be signed";

rv = C_SignUpdate(hSession, chunk1, sizeof(chunk1) - 1);
rv = C_SignUpdate(hSession, chunk2, sizeof(chunk2) - 1);
rv = C_SignUpdate(hSession, chunk3, sizeof(chunk3) - 1);

// Get final signature
CK_BYTE signature[256];
CK_ULONG signatureLen = sizeof(signature);
rv = C_SignFinal(hSession, signature, &signatureLen);
```

## Advanced Usage

### Object Management
```cpp
// Find objects by template
CK_OBJECT_CLASS keyClass = CKO_PRIVATE_KEY;
CK_KEY_TYPE keyType = CKK_RSA;
CK_ATTRIBUTE findTemplate[] = {
    {CKA_CLASS, &keyClass, sizeof(keyClass)},
    {CKA_KEY_TYPE, &keyType, sizeof(keyType)}
};

rv = C_FindObjectsInit(hSession, findTemplate, 2);

CK_OBJECT_HANDLE objects[10];
CK_ULONG objectCount;
rv = C_FindObjects(hSession, objects, 10, &objectCount);

rv = C_FindObjectsFinal(hSession);

// Get object attributes
CK_BYTE label[256];
CK_ATTRIBUTE getTemplate[] = {
    {CKA_LABEL, label, sizeof(label)}
};

rv = C_GetAttributeValue(hSession, objects[0], getTemplate, 1);
```

### Error Handling
```cpp
CK_RV handleError(CK_RV rv) {
    if (rv != CKR_OK) {
        // Get detailed error message
        char errorMsg[256];
        SC_GetErrorString(rv, errorMsg, sizeof(errorMsg));
        fprintf(stderr, "PKCS#11 Error: %s (0x%08X)\n", errorMsg, rv);
        
        // Check for specific errors
        switch (rv) {
            case CKR_DEVICE_ERROR:
                // Backend connection issue
                reconnectBackend();
                break;
            case CKR_KEY_HANDLE_INVALID:
                // Key not found
                refreshKeyCache();
                break;
            default:
                break;
        }
    }
    return rv;
}
```

### Performance Optimization
```cpp
// Enable connection pooling
supacrypt_config_t config = {0};
config.connection_pool_size = 8;  // Increase for high concurrency
config.request_timeout_ms = 5000; // Reduce for faster failure detection

// Use session pooling
typedef struct {
    CK_SESSION_HANDLE handle;
    bool inUse;
} SessionPool;

SessionPool sessions[MAX_SESSIONS];

CK_SESSION_HANDLE getSession() {
    for (int i = 0; i < MAX_SESSIONS; i++) {
        if (!sessions[i].inUse) {
            sessions[i].inUse = true;
            return sessions[i].handle;
        }
    }
    return CK_INVALID_HANDLE;
}
```

## Security Considerations

### Certificate Management
- Store certificates in protected locations
- Use appropriate file permissions (600 on Linux/macOS)
- Rotate certificates regularly
- Monitor certificate expiration

### Key Usage
- Keys are never exported from the backend
- All operations occur in the secure backend
- Key handles are session-specific
- Implement proper access controls

### Audit Logging
```cpp
// Enable detailed logging
CK_BBOOL enableLogging = CK_TRUE;
SC_SetLogging(enableLogging, LOG_LEVEL_DEBUG, "/var/log/supacrypt/audit.log");

// Log entries include:
// - Timestamp
// - Operation type
// - Key identifier
// - Result code
// - Session information
```

## Performance Tuning

### Connection Pool Sizing
```cpp
// Calculate optimal pool size
int optimalPoolSize = min(
    numberOfConcurrentThreads,
    backendMaxConnections / numberOfClients
);

config.connection_pool_size = optimalPoolSize;
```

### Caching Strategy
- Object attributes are cached for 5 minutes
- Mechanism lists are cached indefinitely
- Key handles are session-specific

### Batch Operations
```cpp
// Use multi-part operations for large data
const size_t CHUNK_SIZE = 8192;
for (size_t offset = 0; offset < dataLen; offset += CHUNK_SIZE) {
    size_t chunkLen = min(CHUNK_SIZE, dataLen - offset);
    rv = C_SignUpdate(hSession, data + offset, chunkLen);
}
```

## Troubleshooting

See [Troubleshooting Guide](troubleshooting.md) for common issues and solutions.
```

### 3. API Reference Documentation

#### docs/api-reference.md
```markdown
# Supacrypt PKCS#11 API Reference

## Overview

This document provides detailed information about all PKCS#11 functions implemented by the Supacrypt provider, including function signatures, parameters, return values, and usage examples.

## Function Categories

1. [General Purpose Functions](#general-purpose-functions)
2. [Slot and Token Management](#slot-and-token-management)
3. [Session Management](#session-management)
4. [Object Management](#object-management)
5. [Cryptographic Operations](#cryptographic-operations)
6. [Supacrypt Extensions](#supacrypt-extensions)

## General Purpose Functions

### C_Initialize

Initializes the PKCS#11 library.

```c
CK_RV C_Initialize(CK_VOID_PTR pInitArgs);
```

**Parameters:**
- `pInitArgs` - Pointer to CK_C_INITIALIZE_ARGS structure or NULL

**Returns:**
- `CKR_OK` - Success
- `CKR_CRYPTOKI_ALREADY_INITIALIZED` - Library already initialized
- `CKR_ARGUMENTS_BAD` - Invalid arguments
- `CKR_GENERAL_ERROR` - General failure

**Thread Safety:** This function is not thread-safe. Only one thread should call C_Initialize.

**Example:**
```c
CK_C_INITIALIZE_ARGS initArgs = {
    .CreateMutex = NULL,
    .DestroyMutex = NULL,
    .LockMutex = NULL,
    .UnlockMutex = NULL,
    .flags = CKF_OS_LOCKING_OK,
    .pReserved = NULL
};

CK_RV rv = C_Initialize(&initArgs);
if (rv != CKR_OK) {
    printf("Failed to initialize: 0x%08X\n", rv);
}
```

### C_Finalize

Finalizes the PKCS#11 library.

```c
CK_RV C_Finalize(CK_VOID_PTR pReserved);
```

**Parameters:**
- `pReserved` - Must be NULL

**Returns:**
- `CKR_OK` - Success
- `CKR_CRYPTOKI_NOT_INITIALIZED` - Library not initialized
- `CKR_ARGUMENTS_BAD` - pReserved is not NULL

**Notes:**
- Closes all sessions
- Releases all resources
- Disconnects from backend

### C_GetInfo

Gets general information about the PKCS#11 library.

```c
CK_RV C_GetInfo(CK_INFO_PTR pInfo);
```

**Parameters:**
- `pInfo` - Pointer to CK_INFO structure to receive information

**Returns:**
- `CKR_OK` - Success
- `CKR_CRYPTOKI_NOT_INITIALIZED` - Library not initialized
- `CKR_ARGUMENTS_BAD` - pInfo is NULL

**Info Structure:**
```c
typedef struct CK_INFO {
    CK_VERSION cryptokiVersion;  // PKCS#11 version (2.40)
    CK_UTF8CHAR manufacturerID[32];  // "Supacrypt"
    CK_FLAGS flags;  // 0
    CK_UTF8CHAR libraryDescription[32];  // "Supacrypt PKCS#11"
    CK_VERSION libraryVersion;  // Provider version
} CK_INFO;
```

## Slot and Token Management

### C_GetSlotList

Gets list of available slots.

```c
CK_RV C_GetSlotList(
    CK_BBOOL tokenPresent,
    CK_SLOT_ID_PTR pSlotList,
    CK_ULONG_PTR pulCount
);
```

**Parameters:**
- `tokenPresent` - CK_TRUE to list only slots with tokens
- `pSlotList` - Array to receive slot IDs (can be NULL)
- `pulCount` - Pointer to number of slots

**Returns:**
- `CKR_OK` - Success
- `CKR_BUFFER_TOO_SMALL` - Provided buffer too small
- `CKR_CRYPTOKI_NOT_INITIALIZED` - Library not initialized

**Notes:**
- Supacrypt provides exactly one slot (ID = 1)
- Token is always present when backend is connected

### C_GetSlotInfo

Gets information about a specific slot.

```c
CK_RV C_GetSlotInfo(
    CK_SLOT_ID slotID,
    CK_SLOT_INFO_PTR pInfo
);
```

**Slot Info Structure:**
```c
typedef struct CK_SLOT_INFO {
    CK_UTF8CHAR slotDescription[64];  // "Supacrypt Remote HSM Slot"
    CK_UTF8CHAR manufacturerID[32];   // "Supacrypt"
    CK_FLAGS flags;  // CKF_TOKEN_PRESENT | CKF_HW_SLOT
    CK_VERSION hardwareVersion;  // 1.0
    CK_VERSION firmwareVersion;  // 1.0
} CK_SLOT_INFO;
```

## Session Management

### C_OpenSession

Opens a session between an application and a token.

```c
CK_RV C_OpenSession(
    CK_SLOT_ID slotID,
    CK_FLAGS flags,
    CK_VOID_PTR pApplication,
    CK_NOTIFY Notify,
    CK_SESSION_HANDLE_PTR phSession
);
```

**Parameters:**
- `slotID` - ID of the token's slot
- `flags` - Session flags (must include CKF_SERIAL_SESSION)
- `pApplication` - Application-defined pointer (can be NULL)
- `Notify` - Callback function (can be NULL)
- `phSession` - Pointer to receive session handle

**Flags:**
- `CKF_SERIAL_SESSION` - Required
- `CKF_RW_SESSION` - Read/write session (optional)

**Returns:**
- `CKR_OK` - Success
- `CKR_SLOT_ID_INVALID` - Invalid slot ID
- `CKR_SESSION_PARALLEL_NOT_SUPPORTED` - Missing CKF_SERIAL_SESSION
- `CKR_DEVICE_ERROR` - Backend connection failed

**Example:**
```c
CK_SESSION_HANDLE hSession;
CK_RV rv = C_OpenSession(1, CKF_SERIAL_SESSION | CKF_RW_SESSION,
                         NULL, NULL, &hSession);
```

### C_CloseSession

Closes a session.

```c
CK_RV C_CloseSession(CK_SESSION_HANDLE hSession);
```

**Notes:**
- Cancels any active operations
- Releases session resources
- Thread-safe

### C_GetSessionInfo

Gets information about a session.

```c
CK_RV C_GetSessionInfo(
    CK_SESSION_HANDLE hSession,
    CK_SESSION_INFO_PTR pInfo
);
```

**Session Info Structure:**
```c
typedef struct CK_SESSION_INFO {
    CK_SLOT_ID slotID;  // Always 1
    CK_STATE state;     // Session state
    CK_FLAGS flags;     // Session flags
    CK_ULONG ulDeviceError;  // Device-specific error code
} CK_SESSION_INFO;
```

## Object Management

### C_FindObjectsInit

Initializes object search.

```c
CK_RV C_FindObjectsInit(
    CK_SESSION_HANDLE hSession,
    CK_ATTRIBUTE_PTR pTemplate,
    CK_ULONG ulCount
);
```

**Search Examples:**
```c
// Find all RSA private keys
CK_OBJECT_CLASS keyClass = CKO_PRIVATE_KEY;
CK_KEY_TYPE keyType = CKK_RSA;
CK_ATTRIBUTE template[] = {
    {CKA_CLASS, &keyClass, sizeof(keyClass)},
    {CKA_KEY_TYPE, &keyType, sizeof(keyType)}
};

rv = C_FindObjectsInit(hSession, template, 2);
```

### C_FindObjects

Continues object search.

```c
CK_RV C_FindObjects(
    CK_SESSION_HANDLE hSession,
    CK_OBJECT_HANDLE_PTR phObject,
    CK_ULONG ulMaxObjectCount,
    CK_ULONG_PTR pulObjectCount
);
```

### C_FindObjectsFinal

Finishes object search.

```c
CK_RV C_FindObjectsFinal(CK_SESSION_HANDLE hSession);
```

## Cryptographic Operations

### Key Generation

#### C_GenerateKeyPair

Generates a public/private key pair.

```c
CK_RV C_GenerateKeyPair(
    CK_SESSION_HANDLE hSession,
    CK_MECHANISM_PTR pMechanism,
    CK_ATTRIBUTE_PTR pPublicKeyTemplate,
    CK_ULONG ulPublicKeyAttributeCount,
    CK_ATTRIBUTE_PTR pPrivateKeyTemplate,
    CK_ULONG ulPrivateKeyAttributeCount,
    CK_OBJECT_HANDLE_PTR phPublicKey,
    CK_OBJECT_HANDLE_PTR phPrivateKey
);
```

**Supported Mechanisms:**
- `CKM_RSA_PKCS_KEY_PAIR_GEN` - RSA key generation
- `CKM_EC_KEY_PAIR_GEN` - ECC key generation

**RSA Example:**
```c
CK_MECHANISM mechanism = {CKM_RSA_PKCS_KEY_PAIR_GEN, NULL, 0};
CK_ULONG modulusBits = 2048;
CK_BYTE publicExponent[] = {0x01, 0x00, 0x01};

CK_ATTRIBUTE publicTemplate[] = {
    {CKA_MODULUS_BITS, &modulusBits, sizeof(modulusBits)},
    {CKA_PUBLIC_EXPONENT, publicExponent, sizeof(publicExponent)},
    {CKA_TOKEN, &ckTrue, sizeof(ckTrue)},
    {CKA_VERIFY, &ckTrue, sizeof(ckTrue)}
};

CK_ATTRIBUTE privateTemplate[] = {
    {CKA_TOKEN, &ckTrue, sizeof(ckTrue)},
    {CKA_PRIVATE, &ckTrue, sizeof(ckTrue)},
    {CKA_SIGN, &ckTrue, sizeof(ckTrue)}
};
```

**ECC Example:**
```c
CK_MECHANISM mechanism = {CKM_EC_KEY_PAIR_GEN, NULL, 0};
CK_BYTE ecParams[] = {0x06, 0x08, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x03, 0x01, 0x07}; // P-256

CK_ATTRIBUTE publicTemplate[] = {
    {CKA_EC_PARAMS, ecParams, sizeof(ecParams)},
    {CKA_TOKEN, &ckTrue, sizeof(ckTrue)},
    {CKA_VERIFY, &ckTrue, sizeof(ckTrue)}
};
```

### Signing Operations

#### C_SignInit

Initializes a signature operation.

```c
CK_RV C_SignInit(
    CK_SESSION_HANDLE hSession,
    CK_MECHANISM_PTR pMechanism,
    CK_OBJECT_HANDLE hKey
);
```

**Supported Mechanisms:**
- `CKM_RSA_PKCS` - RSA PKCS#1 v1.5
- `CKM_RSA_PKCS_PSS` - RSA PSS
- `CKM_ECDSA` - ECDSA
- `CKM_ECDSA_SHA256` - ECDSA with SHA-256

#### C_Sign

Signs data in a single operation.

```c
CK_RV C_Sign(
    CK_SESSION_HANDLE hSession,
    CK_BYTE_PTR pData,
    CK_ULONG ulDataLen,
    CK_BYTE_PTR pSignature,
    CK_ULONG_PTR pulSignatureLen
);
```

**Size Query:**
```c
// First call to get size
CK_ULONG signatureLen;
rv = C_Sign(hSession, data, dataLen, NULL, &signatureLen);

// Allocate buffer and sign
CK_BYTE_PTR signature = malloc(signatureLen);
rv = C_Sign(hSession, data, dataLen, signature, &signatureLen);
```

#### C_SignUpdate

Continues multi-part signature.

```c
CK_RV C_SignUpdate(
    CK_SESSION_HANDLE hSession,
    CK_BYTE_PTR pPart,
    CK_ULONG ulPartLen
);
```

#### C_SignFinal

Finishes multi-part signature.

```c
CK_RV C_SignFinal(
    CK_SESSION_HANDLE hSession,
    CK_BYTE_PTR pSignature,
    CK_ULONG_PTR pulSignatureLen
);
```

### Verification Operations

#### C_VerifyInit

Initializes verification operation.

```c
CK_RV C_VerifyInit(
    CK_SESSION_HANDLE hSession,
    CK_MECHANISM_PTR pMechanism,
    CK_OBJECT_HANDLE hKey
);
```

#### C_Verify

Verifies a signature.

```c
CK_RV C_Verify(
    CK_SESSION_HANDLE hSession,
    CK_BYTE_PTR pData,
    CK_ULONG ulDataLen,
    CK_BYTE_PTR pSignature,
    CK_ULONG ulSignatureLen
);
```

**Returns:**
- `CKR_OK` - Signature valid
- `CKR_SIGNATURE_INVALID` - Signature invalid
- `CKR_SIGNATURE_LEN_RANGE` - Wrong signature length

## Supacrypt Extensions

### SC_Configure

Configures backend connection before initialization.

```c
CK_RV SC_Configure(const supacrypt_config_t* config);
```

**Configuration Structure:**
```c
typedef struct supacrypt_config {
    char backend_endpoint[256];
    char client_cert_path[256];
    char client_key_path[256];
    char ca_cert_path[256];
    CK_BBOOL use_tls;
    uint32_t request_timeout_ms;
    uint32_t retry_count;
    uint32_t connection_pool_size;
} supacrypt_config_t;
```

### SC_GetConfiguration

Gets current configuration.

```c
CK_RV SC_GetConfiguration(supacrypt_config_t* config);
```

### SC_GetErrorString

Gets human-readable error message.

```c
CK_RV SC_GetErrorString(
    CK_RV error_code,
    char* buffer,
    size_t buffer_size
);
```

**Example:**
```c
char errorMsg[256];
SC_GetErrorString(rv, errorMsg, sizeof(errorMsg));
printf("Error: %s\n", errorMsg);
```

### SC_SetLogging

Configures logging.

```c
CK_RV SC_SetLogging(
    CK_BBOOL enable,
    int log_level,
    const char* log_file
);
```

**Log Levels:**
- 0 - ERROR
- 1 - WARNING
- 2 - INFO
- 3 - DEBUG

### SC_GetStatistics

Gets performance statistics.

```c
CK_RV SC_GetStatistics(void* stats);
```

## Return Codes

### Standard PKCS#11 Return Codes

Code | Value | Description
-----|-------|------------
CKR_OK | 0x00000000 | Success
CKR_CANCEL | 0x00000001 | Operation cancelled
CKR_HOST_MEMORY | 0x00000002 | Memory allocation failed
CKR_SLOT_ID_INVALID | 0x00000003 | Invalid slot ID
CKR_GENERAL_ERROR | 0x00000005 | General error
CKR_FUNCTION_FAILED | 0x00000006 | Function failed
CKR_ARGUMENTS_BAD | 0x00000007 | Invalid arguments
CKR_ATTRIBUTE_TYPE_INVALID | 0x00000012 | Invalid attribute type
CKR_ATTRIBUTE_VALUE_INVALID | 0x00000013 | Invalid attribute value
CKR_DEVICE_ERROR | 0x00000030 | Device/backend error
CKR_DEVICE_MEMORY | 0x00000031 | Device memory error
CKR_DEVICE_REMOVED | 0x00000032 | Device disconnected
CKR_KEY_HANDLE_INVALID | 0x00000060 | Invalid key handle
CKR_KEY_SIZE_RANGE | 0x00000062 | Key size not supported
CKR_KEY_TYPE_INCONSISTENT | 0x00000063 | Key type mismatch
CKR_KEY_FUNCTION_NOT_PERMITTED | 0x00000068 | Operation not allowed
CKR_MECHANISM_INVALID | 0x00000070 | Invalid mechanism
CKR_MECHANISM_PARAM_INVALID | 0x00000071 | Invalid mechanism parameter
CKR_OBJECT_HANDLE_INVALID | 0x00000082 | Invalid object handle
CKR_OPERATION_ACTIVE | 0x00000090 | Another operation active
CKR_OPERATION_NOT_INITIALIZED | 0x00000091 | Operation not initialized
CKR_SESSION_CLOSED | 0x000000B0 | Session closed
CKR_SESSION_HANDLE_INVALID | 0x000000B3 | Invalid session handle
CKR_SIGNATURE_INVALID | 0x000000C0 | Invalid signature
CKR_SIGNATURE_LEN_RANGE | 0x000000C1 | Wrong signature length
CKR_BUFFER_TOO_SMALL | 0x00000150 | Output buffer too small
CKR_CRYPTOKI_NOT_INITIALIZED | 0x00000190 | Library not initialized
CKR_CRYPTOKI_ALREADY_INITIALIZED | 0x00000191 | Already initialized

### Backend-Specific Error Mappings

Backend Error | PKCS#11 Return Code | Description
--------------|-------------------|-------------
KEY_NOT_FOUND | CKR_KEY_HANDLE_INVALID | Key doesn't exist
PERMISSION_DENIED | CKR_KEY_FUNCTION_NOT_PERMITTED | Access denied
INVALID_KEY_SIZE | CKR_KEY_SIZE_RANGE | Unsupported size
UNSUPPORTED_ALGORITHM | CKR_MECHANISM_INVALID | Algorithm not supported
RATE_LIMITED | CKR_DEVICE_ERROR | Too many requests
NETWORK_ERROR | CKR_DEVICE_ERROR | Connection failed

## Thread Safety

### Thread-Safe Functions
- All functions except C_Initialize and C_Finalize
- Multiple threads can use different sessions
- Object handles are globally valid

### Thread-Unsafe Functions
- C_Initialize - Single thread only
- C_Finalize - Single thread only

### Best Practices
```c
// Use separate sessions per thread
void* worker_thread(void* arg) {
    CK_SESSION_HANDLE hSession;
    CK_RV rv = C_OpenSession(1, CKF_SERIAL_SESSION, 
                             NULL, NULL, &hSession);
    
    // Use session for operations...
    
    C_CloseSession(hSession);
    return NULL;
}
```

## Performance Characteristics

Operation | Typical Latency | Notes
----------|-----------------|-------
C_Initialize | 100-500ms | Backend connection
C_OpenSession | <1ms | Local operation
C_GenerateKeyPair | 1-2s | Backend operation
C_Sign (RSA-2048) | 40-50ms | Including network
C_Verify (RSA-2048) | 15-20ms | Including network
C_FindObjects | 10-50ms | Depends on count

## Migration Guide

### From SoftHSM
```c
// SoftHSM
C_Initialize(NULL);

// Supacrypt - configure first
supacrypt_config_t config = {0};
// ... set config ...
SC_Configure(&config);
C_Initialize(NULL);
```

### From OpenSC
- Replace module path in opensc.conf
- Update slot references (always use slot 1)
- No PIN required for Supacrypt

### From AWS CloudHSM
- Similar architecture (remote HSM)
- Update connection configuration
- Adjust for different mechanism support
```

### 4. Platform-Specific Installation Guides

#### docs/installation/linux.md
```markdown
# Linux Installation Guide

## Supported Distributions

- Ubuntu 20.04 LTS, 22.04 LTS, 24.04 LTS
- Debian 10 (Buster), 11 (Bullseye), 12 (Bookworm)
- RHEL 8, 9
- CentOS Stream 8, 9
- Fedora 38+
- openSUSE Leap 15.5+
- Arch Linux (current)

## Installation Methods

### Package Manager Installation

#### APT (Debian/Ubuntu)
```bash
# Add Supacrypt repository key
wget -qO - https://apt.supacrypt.io/gpg | sudo apt-key add -

# Add repository
echo "deb https://apt.supacrypt.io stable main" | \
    sudo tee /etc/apt/sources.list.d/supacrypt.list

# Update and install
sudo apt update
sudo apt install supacrypt-pkcs11

# Optional: development headers
sudo apt install supacrypt-pkcs11-dev
```

#### YUM/DNF (RHEL/Fedora)
```bash
# Add repository
sudo dnf config-manager --add-repo https://rpm.supacrypt.io/supacrypt.repo

# Install
sudo dnf install supacrypt-pkcs11

# For RHEL 8
sudo yum install supacrypt-pkcs11
```

#### Zypper (openSUSE)
```bash
# Add repository
sudo zypper addrepo https://rpm.supacrypt.io/opensuse/ supacrypt

# Install
sudo zypper install supacrypt-pkcs11
```

#### Pacman (Arch)
```bash
# From AUR
yay -S supacrypt-pkcs11

# Or manually
git clone https://aur.archlinux.org/supacrypt-pkcs11.git
cd supacrypt-pkcs11
makepkg -si
```

### Manual Installation

#### From Binary Package
```bash
# Download package
wget https://github.com/supacrypt/supacrypt-pkcs11/releases/download/v1.0.0/supacrypt-pkcs11-1.0.0-linux-x64.tar.gz

# Extract
sudo tar -xzf supacrypt-pkcs11-1.0.0-linux-x64.tar.gz -C /

# Update library cache
sudo ldconfig

# Verify installation
pkcs11-tool --module /usr/lib/supacrypt-pkcs11.so -I
```

#### From Source
```bash
# Install dependencies
sudo apt install build-essential cmake git libssl-dev

# Clone repository
git clone https://github.com/supacrypt/supacrypt-pkcs11.git
cd supacrypt-pkcs11

# Build
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
make -j$(nproc)

# Test
make test

# Install
sudo make install
sudo ldconfig
```

## Configuration

### System-Wide Configuration

Create `/etc/supacrypt/pkcs11.conf`:
```json
{
  "backend": {
    "endpoint": "backend.supacrypt.local:5000",
    "tls": {
      "enabled": true,
      "client_cert": "/etc/supacrypt/certs/client.crt",
      "client_key": "/etc/supacrypt/certs/client.key",
      "ca_cert": "/etc/supacrypt/certs/ca.crt"
    }
  },
  "logging": {
    "enabled": true,
    "level": "info",
    "file": "/var/log/supacrypt/pkcs11.log"
  }
}
```

### User Configuration

Create `~/.config/supacrypt/pkcs11.conf` for user-specific settings.

### Certificate Setup
```bash
# Create certificate directory
sudo mkdir -p /etc/supacrypt/certs
sudo chmod 755 /etc/supacrypt/certs

# Copy certificates
sudo cp client.crt client.key ca.crt /etc/supacrypt/certs/
sudo chmod 644 /etc/supacrypt/certs/*.crt
sudo chmod 600 /etc/supacrypt/certs/*.key

# Set ownership
sudo chown -R root:root /etc/supacrypt/certs
```

## Application Integration

### p11-kit Integration
```bash
# Create module configuration
sudo tee /usr/share/p11-kit/modules/supacrypt.module <<EOF
module: /usr/lib/supacrypt-pkcs11.so
trust-policy: yes
EOF

# List modules
p11-kit list-modules

# Test
p11tool --list-all
```

### NSS Integration
```bash
# Add to NSS database
modutil -add "Supacrypt PKCS#11" \
    -libfile /usr/lib/supacrypt-pkcs11.so \
    -dbdir sql:$HOME/.pki/nssdb

# Verify
modutil -list -dbdir sql:$HOME/.pki/nssdb

# Use with Chrome/Firefox
export NSS_DEFAULT_DB_TYPE=sql
```

### OpenSSL Integration
```bash
# Install engine
sudo apt install libengine-pkcs11-openssl

# Configure OpenSSL
cat >> ~/.openssl.cnf <<EOF
[openssl_init]
engines = engine_section

[engine_section]
pkcs11 = pkcs11_section

[pkcs11_section]
engine_id = pkcs11
dynamic_path = /usr/lib/x86_64-linux-gnu/engines-1.1/libpkcs11.so
MODULE_PATH = /usr/lib/supacrypt-pkcs11.so
init = 0
EOF

# Test
openssl engine pkcs11 -t
```

### SSH Integration
```bash
# Find SSH key
ssh-keygen -D /usr/lib/supacrypt-pkcs11.so

# Add to SSH agent
ssh-add -s /usr/lib/supacrypt-pkcs11.so

# Use for authentication
ssh -I /usr/lib/supacrypt-pkcs11.so user@host
```

### Java Integration
```java
// Configure provider
String configName = "/etc/supacrypt/java.cfg";
Provider p = new sun.security.pkcs11.SunPKCS11(configName);
Security.addProvider(p);

// java.cfg content:
name = Supacrypt
library = /usr/lib/supacrypt-pkcs11.so
```

## Permissions and Security

### SELinux Configuration (RHEL/Fedora)
```bash
# Set context
sudo semanage fcontext -a -t lib_t "/usr/lib/supacrypt-pkcs11.so"
sudo restorecon -v /usr/lib/supacrypt-pkcs11.so

# Allow access
sudo setsebool -P httpd_can_network_connect 1  # For web servers
```

### AppArmor Configuration (Ubuntu)
```bash
# Add to /etc/apparmor.d/local/usr.bin.application
/usr/lib/supacrypt-pkcs11.so mr,
/etc/supacrypt/** r,
```

### File Permissions
```bash
# Library permissions
-rwxr-xr-x /usr/lib/supacrypt-pkcs11.so

# Configuration permissions
-rw-r--r-- /etc/supacrypt/pkcs11.conf
-rw-r--r-- /etc/supacrypt/certs/ca.crt
-rw-r--r-- /etc/supacrypt/certs/client.crt
-rw------- /etc/supacrypt/certs/client.key
```

## Logging

### System Logging
```bash
# View logs
sudo journalctl -u supacrypt-pkcs11

# Tail logs
sudo tail -f /var/log/supacrypt/pkcs11.log

# Log rotation
cat > /etc/logrotate.d/supacrypt <<EOF
/var/log/supacrypt/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
}
EOF
```

### Debug Logging
```bash
# Enable debug logging
export SUPACRYPT_LOG_LEVEL=debug
export SUPACRYPT_LOG_FILE=/tmp/supacrypt-debug.log

# Run application
your-application

# View debug output
cat /tmp/supacrypt-debug.log
```

## Performance Tuning

### System Limits
```bash
# Increase file descriptors
echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 65536" >> /etc/security/limits.conf

# Apply immediately
ulimit -n 65536
```

### Network Optimization
```bash
# TCP keepalive
echo "net.ipv4.tcp_keepalive_time = 60" >> /etc/sysctl.conf
echo "net.ipv4.tcp_keepalive_intvl = 10" >> /etc/sysctl.conf
echo "net.ipv4.tcp_keepalive_probes = 6" >> /etc/sysctl.conf

# Apply
sudo sysctl -p
```

## Troubleshooting

### Common Issues

#### Library Not Found
```bash
# Check library path
ldconfig -p | grep supacrypt

# Add to library path
echo "/usr/lib" | sudo tee /etc/ld.so.conf.d/supacrypt.conf
sudo ldconfig
```

#### Permission Denied
```bash
# Check SELinux
getenforce
sudo setenforce 0  # Temporary disable for testing

# Check file permissions
ls -la /usr/lib/supacrypt-pkcs11.so
ls -la /etc/supacrypt/
```

#### Backend Connection Failed
```bash
# Test connectivity
nc -zv backend.supacrypt.local 5000

# Check DNS
nslookup backend.supacrypt.local

# Verify certificates
openssl s_client -connect backend.supacrypt.local:5000 \
    -cert /etc/supacrypt/certs/client.crt \
    -key /etc/supacrypt/certs/client.key \
    -CAfile /etc/supacrypt/certs/ca.crt
```

### Debug Tools
```bash
# PKCS#11 tool
pkcs11-tool --module /usr/lib/supacrypt-pkcs11.so -L

# strace
strace -e openat your-application 2>&1 | grep supacrypt

# ldd
ldd /usr/lib/supacrypt-pkcs11.so
```

## Uninstallation

### Package Manager
```bash
# Debian/Ubuntu
sudo apt remove supacrypt-pkcs11
sudo apt purge supacrypt-pkcs11  # Also removes config

# RHEL/Fedora
sudo dnf remove supacrypt-pkcs11
```

### Manual Cleanup
```bash
# Remove library
sudo rm /usr/lib/supacrypt-pkcs11.so

# Remove configuration
sudo rm -rf /etc/supacrypt

# Remove logs
sudo rm -rf /var/log/supacrypt

# Update library cache
sudo ldconfig
```
```

### 5. Code Examples

#### docs/examples/basic_usage.cpp
```cpp
/**
 * @file basic_usage.cpp
 * @brief Basic PKCS#11 usage example demonstrating key generation and signing
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <pkcs11.h>
#include <supacrypt/pkcs11/supacrypt_pkcs11.h>

// Helper function to check return values
void check_rv(CK_RV rv, const char* operation) {
    if (rv != CKR_OK) {
        char errorMsg[256];
        SC_GetErrorString(rv, errorMsg, sizeof(errorMsg));
        fprintf(stderr, "%s failed: %s (0x%08lX)\n", operation, errorMsg, rv);
        exit(1);
    }
}

int main() {
    CK_RV rv;
    
    // Configure backend connection
    printf("Configuring Supacrypt PKCS#11...\n");
    supacrypt_config_t config = {0};
    strncpy(config.backend_endpoint, "localhost:5000", sizeof(config.backend_endpoint));
    strncpy(config.client_cert_path, "/etc/supacrypt/client.crt", sizeof(config.client_cert_path));
    strncpy(config.client_key_path, "/etc/supacrypt/client.key", sizeof(config.client_key_path));
    strncpy(config.ca_cert_path, "/etc/supacrypt/ca.crt", sizeof(config.ca_cert_path));
    config.use_tls = CK_TRUE;
    
    rv = SC_Configure(&config);
    check_rv(rv, "SC_Configure");
    
    // Initialize PKCS#11
    printf("Initializing PKCS#11...\n");
    rv = C_Initialize(NULL);
    check_rv(rv, "C_Initialize");
    
    // Get library info
    CK_INFO info;
    rv = C_GetInfo(&info);
    check_rv(rv, "C_GetInfo");
    
    printf("PKCS#11 Provider: %.32s\n", info.manufacturerID);
    printf("Library Version: %d.%d\n", 
           info.libraryVersion.major, info.libraryVersion.minor);
    
    // Get slot list
    CK_ULONG slotCount;
    rv = C_GetSlotList(CK_TRUE, NULL, &slotCount);
    check_rv(rv, "C_GetSlotList (count)");
    printf("Found %lu slot(s)\n", slotCount);
    
    CK_SLOT_ID_PTR pSlotList = malloc(sizeof(CK_SLOT_ID) * slotCount);
    rv = C_GetSlotList(CK_TRUE, pSlotList, &slotCount);
    check_rv(rv, "C_GetSlotList");
    
    // Open session
    printf("Opening session...\n");
    CK_SESSION_HANDLE hSession;
    rv = C_OpenSession(pSlotList[0], CKF_SERIAL_SESSION | CKF_RW_SESSION,
                       NULL, NULL, &hSession);
    check_rv(rv, "C_OpenSession");
    
    // Generate RSA key pair
    printf("Generating RSA-2048 key pair...\n");
    CK_MECHANISM keyGenMech = {CKM_RSA_PKCS_KEY_PAIR_GEN, NULL, 0};
    
    CK_ULONG modulusBits = 2048;
    CK_BYTE publicExponent[] = {0x01, 0x00, 0x01}; // 65537
    CK_BBOOL ckTrue = CK_TRUE;
    CK_BBOOL ckFalse = CK_FALSE;
    CK_UTF8CHAR pubLabel[] = "Example RSA Public Key";
    CK_UTF8CHAR privLabel[] = "Example RSA Private Key";
    
    CK_ATTRIBUTE publicKeyTemplate[] = {
        {CKA_TOKEN, &ckTrue, sizeof(ckTrue)},
        {CKA_PRIVATE, &ckFalse, sizeof(ckFalse)},
        {CKA_MODULUS_BITS, &modulusBits, sizeof(modulusBits)},
        {CKA_PUBLIC_EXPONENT, publicExponent, sizeof(publicExponent)},
        {CKA_VERIFY, &ckTrue, sizeof(ckTrue)},
        {CKA_LABEL, pubLabel, sizeof(pubLabel) - 1}
    };
    
    CK_ATTRIBUTE privateKeyTemplate[] = {
        {CKA_TOKEN, &ckTrue, sizeof(ckTrue)},
        {CKA_PRIVATE, &ckTrue, sizeof(ckTrue)},
        {CKA_SIGN, &ckTrue, sizeof(ckTrue)},
        {CKA_LABEL, privLabel, sizeof(privLabel) - 1}
    };
    
    CK_OBJECT_HANDLE hPublicKey, hPrivateKey;
    rv = C_GenerateKeyPair(hSession, &keyGenMech,
                          publicKeyTemplate, 6,
                          privateKeyTemplate, 4,
                          &hPublicKey, &hPrivateKey);
    check_rv(rv, "C_GenerateKeyPair");
    printf("Key pair generated successfully\n");
    
    // Sign some data
    printf("Signing data...\n");
    CK_MECHANISM signMech = {CKM_RSA_PKCS, NULL, 0};
    rv = C_SignInit(hSession, &signMech, hPrivateKey);
    check_rv(rv, "C_SignInit");
    
    CK_BYTE data[] = "Hello, PKCS#11 World!";
    CK_BYTE signature[256];
    CK_ULONG signatureLen = sizeof(signature);
    
    rv = C_Sign(hSession, data, strlen((char*)data), signature, &signatureLen);
    check_rv(rv, "C_Sign");
    printf("Data signed, signature length: %lu bytes\n", signatureLen);
    
    // Verify signature
    printf("Verifying signature...\n");
    rv = C_VerifyInit(hSession, &signMech, hPublicKey);
    check_rv(rv, "C_VerifyInit");
    
    rv = C_Verify(hSession, data, strlen((char*)data), signature, signatureLen);
    check_rv(rv, "C_Verify");
    printf("Signature verified successfully\n");
    
    // Clean up
    printf("Cleaning up...\n");
    C_CloseSession(hSession);
    C_Finalize(NULL);
    free(pSlotList);
    
    printf("Example completed successfully!\n");
    return 0;
}
```

#### docs/examples/CMakeLists.txt
```cmake
# Build examples
cmake_minimum_required(VERSION 3.10)

find_package(PkgConfig REQUIRED)
pkg_check_modules(SUPACRYPT_PKCS11 REQUIRED supacrypt-pkcs11)

# Basic usage example
add_executable(basic_usage basic_usage.cpp)
target_link_libraries(basic_usage ${SUPACRYPT_PKCS11_LIBRARIES})
target_include_directories(basic_usage PUBLIC ${SUPACRYPT_PKCS11_INCLUDE_DIRS})

# Other examples...
add_executable(multi_threading multi_threading.cpp)
target_link_libraries(multi_threading ${SUPACRYPT_PKCS11_LIBRARIES} pthread)

add_executable(key_management key_management.cpp)
target_link_libraries(key_management ${SUPACRYPT_PKCS11_LIBRARIES})

add_executable(error_handling error_handling.cpp)
target_link_libraries(error_handling ${SUPACRYPT_PKCS11_LIBRARIES})
```

### 6. Troubleshooting Guide

#### docs/troubleshooting.md
```markdown
# Supacrypt PKCS#11 Troubleshooting Guide

## Common Issues and Solutions

### Connection Issues

#### Error: CKR_DEVICE_ERROR during C_Initialize

**Symptoms:**
- C_Initialize returns CKR_DEVICE_ERROR
- "Backend connection failed" in logs

**Causes:**
1. Backend service not running
2. Network connectivity issues
3. Incorrect endpoint configuration
4. Firewall blocking connection

**Solutions:**
```bash
# 1. Check backend status
curl -k https://backend.supacrypt.local:5000/health

# 2. Test network connectivity
ping backend.supacrypt.local
nc -zv backend.supacrypt.local 5000

# 3. Verify configuration
cat /etc/supacrypt/pkcs11.conf | jq .backend.endpoint

# 4. Check firewall
sudo iptables -L -n | grep 5000
```

#### Error: Certificate Verification Failed

**Symptoms:**
- "TLS handshake failed" in logs
- CKR_DEVICE_ERROR with SSL errors

**Solutions:**
```bash
# Verify certificate validity
openssl x509 -in /etc/supacrypt/client.crt -text -noout

# Check certificate chain
openssl verify -CAfile /etc/supacrypt/ca.crt /etc/supacrypt/client.crt

# Test mTLS connection
openssl s_client -connect backend:5000 \
    -cert /etc/supacrypt/client.crt \
    -key /etc/supacrypt/client.key \
    -CAfile /etc/supacrypt/ca.crt
```

### Library Loading Issues

#### Error: Library Not Found

**Symptoms:**
- "cannot open shared object file"
- Application fails to load PKCS#11 module

**Solutions:**
```bash
# Update library cache
sudo ldconfig

# Check library dependencies
ldd /usr/lib/supacrypt-pkcs11.so

# Add to LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/usr/lib:$LD_LIBRARY_PATH

# Verify library architecture
file /usr/lib/supacrypt-pkcs11.so
```

#### Error: Symbol Not Found

**Symptoms:**
- "undefined symbol" errors
- C_GetFunctionList not found

**Solutions:**
```bash
# Check exported symbols
nm -D /usr/lib/supacrypt-pkcs11.so | grep C_GetFunctionList

# Verify library version
strings /usr/lib/supacrypt-pkcs11.so | grep VERSION

# Rebuild with proper flags
cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON
```

### Operational Issues

#### Error: CKR_OPERATION_ACTIVE

**Symptoms:**
- Cannot start new operation
- Previous operation not completed

**Solutions:**
```c
// Cancel any active operation
C_SignInit(hSession, NULL, 0);  // Cancel signing
C_VerifyInit(hSession, NULL, 0); // Cancel verify

// Or close and reopen session
C_CloseSession(hSession);
C_OpenSession(slot, flags, NULL, NULL, &hSession);
```

#### Error: CKR_KEY_HANDLE_INVALID

**Symptoms:**
- Key not found errors
- Object handle invalid

**Causes:**
1. Key deleted on backend
2. Session closed
3. Handle corruption

**Solutions:**
```c
// Re-find the key
CK_ATTRIBUTE template[] = {
    {CKA_LABEL, label, labelLen}
};
C_FindObjectsInit(hSession, template, 1);
C_FindObjects(hSession, &hKey, 1, &count);
C_FindObjectsFinal(hSession);
```

### Performance Issues

#### Slow Operations

**Symptoms:**
- Operations taking >100ms
- Timeouts during signing

**Solutions:**
```bash
# 1. Check network latency
ping -c 10 backend.supacrypt.local

# 2. Increase connection pool
export SUPACRYPT_POOL_SIZE=8

# 3. Enable connection keepalive
echo "net.ipv4.tcp_keepalive_time = 60" | sudo tee -a /etc/sysctl.conf

# 4. Check backend load
curl https://backend:5000/metrics
```

#### Memory Leaks

**Symptoms:**
- Increasing memory usage
- Application crash after extended use

**Solutions:**
```bash
# Use valgrind to detect leaks
valgrind --leak-check=full --show-leak-kinds=all \
    ./your-application

# Common fixes:
# - Always call C_Finalize
# - Close all sessions
# - Free allocated buffers
```

### Platform-Specific Issues

#### Linux: SELinux Denials

```bash
# Check SELinux denials
sudo ausearch -m avc -ts recent

# Create policy module
sudo audit2allow -M supacrypt-pkcs11
sudo semodule -i supacrypt-pkcs11.pp
```

#### Windows: DLL Loading Failed

```powershell
# Check dependencies
dumpbin /dependents supacrypt-pkcs11.dll

# Install Visual C++ Runtime
# Download from Microsoft

# Register DLL
regsvr32 supacrypt-pkcs11.dll
```

#### macOS: Code Signing Issues

```bash
# Check code signature
codesign -vvv /usr/local/lib/supacrypt-pkcs11.dylib

# Allow unsigned library (development only)
sudo spctl --add /usr/local/lib/supacrypt-pkcs11.dylib
```

## Debug Techniques

### Enable Debug Logging

```c
// In code
SC_SetLogging(CK_TRUE, 3, "/tmp/pkcs11-debug.log");

// Via environment
export SUPACRYPT_LOG_LEVEL=debug
export SUPACRYPT_LOG_FILE=/tmp/pkcs11-debug.log
```

### Use PKCS#11 Spy

```bash
# Install pkcs11-spy
export PKCS11SPY=/usr/lib/supacrypt-pkcs11.so
export PKCS11SPY_OUTPUT=/tmp/pkcs11-spy.log

# Use spy library
pkcs11-tool --module /usr/lib/pkcs11-spy.so -L
```

### Network Tracing

```bash
# Capture gRPC traffic
sudo tcpdump -i any -w pkcs11.pcap host backend.supacrypt.local

# Analyze with Wireshark
wireshark pkcs11.pcap
# Filter: grpc
```

### Core Dumps

```bash
# Enable core dumps
ulimit -c unlimited
echo "/tmp/core.%e.%p" | sudo tee /proc/sys/kernel/core_pattern

# Analyze core
gdb /usr/lib/supacrypt-pkcs11.so /tmp/core.pkcs11.12345
(gdb) bt full
(gdb) info threads
```

## Performance Optimization

### Connection Pooling
```c
// Increase pool size for concurrent operations
config.connection_pool_size = 16;
```

### Session Caching
```c
// Reuse sessions across operations
static CK_SESSION_HANDLE cached_session = CK_INVALID_HANDLE;

CK_SESSION_HANDLE get_session() {
    if (cached_session == CK_INVALID_HANDLE) {
        C_OpenSession(1, CKF_SERIAL_SESSION, NULL, NULL, &cached_session);
    }
    return cached_session;
}
```

### Batch Operations
```c
// Use multi-part operations for large data
C_SignInit(hSession, &mech, hKey);
for (size_t i = 0; i < data_len; i += CHUNK_SIZE) {
    C_SignUpdate(hSession, data + i, MIN(CHUNK_SIZE, data_len - i));
}
C_SignFinal(hSession, signature, &sig_len);
```

## Getting Help

### Log Collection Script
```bash
#!/bin/bash
# collect-logs.sh

echo "Collecting Supacrypt PKCS#11 diagnostics..."

# Create report directory
REPORT_DIR="/tmp/supacrypt-report-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$REPORT_DIR"

# System info
uname -a > "$REPORT_DIR/system.txt"
lsb_release -a >> "$REPORT_DIR/system.txt" 2>/dev/null

# Library info
ldd /usr/lib/supacrypt-pkcs11.so > "$REPORT_DIR/library-deps.txt"
nm -D /usr/lib/supacrypt-pkcs11.so > "$REPORT_DIR/library-symbols.txt"

# Configuration
cp /etc/supacrypt/pkcs11.conf "$REPORT_DIR/" 2>/dev/null

# Recent logs
journalctl -u supacrypt-pkcs11 --since "1 hour ago" > "$REPORT_DIR/journal.log"
cp /var/log/supacrypt/pkcs11.log "$REPORT_DIR/" 2>/dev/null

# Network test
nc -zv backend.supacrypt.local 5000 &> "$REPORT_DIR/network-test.txt"

# Create archive
tar -czf "$REPORT_DIR.tar.gz" -C /tmp "$(basename $REPORT_DIR)"
echo "Report saved to: $REPORT_DIR.tar.gz"
```

### Support Channels

- GitHub Issues: https://github.com/supacrypt/supacrypt-pkcs11/issues
- Documentation: https://docs.supacrypt.io/pkcs11
- Community Forum: https://forum.supacrypt.io
- Email Support: support@supacrypt.io (Enterprise customers)

When reporting issues, please include:
1. OS and version
2. Supacrypt PKCS#11 version
3. Error messages and logs
4. Steps to reproduce
5. Diagnostic report from collect-logs.sh
```

### 7. Contributing Guide

#### CONTRIBUTING.md
```markdown
# Contributing to Supacrypt PKCS#11

We welcome contributions to the Supacrypt PKCS#11 provider! This guide explains how to set up your development environment and submit changes.

## Development Setup

### Prerequisites

- C++ compiler with C++20 support (GCC 10+, Clang 12+, MSVC 2019+)
- CMake 3.20+
- Git
- OpenSSL development headers
- Google Test (automatically fetched)
- Docker (for integration tests)

### Building from Source

```bash
# Clone repository
git clone https://github.com/supacrypt/supacrypt-pkcs11.git
cd supacrypt-pkcs11

# Create build directory
mkdir build && cd build

# Configure (with all optional features)
cmake .. \
    -DCMAKE_BUILD_TYPE=Debug \
    -DBUILD_TESTING=ON \
    -DBUILD_EXAMPLES=ON \
    -DBUILD_BENCHMARKS=ON \
    -DENABLE_COVERAGE=ON \
    -DENABLE_SANITIZERS=ON

# Build
make -j$(nproc)

# Run tests
make test

# Generate coverage report
make coverage
```

## Code Style

We follow the C++ Core Guidelines and use clang-format for consistency.

### Formatting

```bash
# Format all source files
find src include tests -name "*.cpp" -o -name "*.h" | \
    xargs clang-format -i

# Check formatting
find src include tests -name "*.cpp" -o -name "*.h" | \
    xargs clang-format --dry-run --Werror
```

### Naming Conventions

- Classes: `PascalCase`
- Functions: `camelCase`
- Variables: `camelCase`
- Constants: `UPPER_SNAKE_CASE`
- Files: `snake_case.cpp`

## Testing

### Unit Tests

```bash
# Run all unit tests
./tests/unit/supacrypt-pkcs11-unit-tests

# Run specific test
./tests/unit/supacrypt-pkcs11-unit-tests --gtest_filter="StateManagerTest.*"

# Run with valgrind
valgrind --leak-check=full ./tests/unit/supacrypt-pkcs11-unit-tests
```

### Integration Tests

```bash
# Start test backend
docker run -d --name test-backend \
    -p 5001:5000 \
    supacrypt/backend:test

# Run integration tests
./tests/integration/supacrypt-pkcs11-integration-tests

# Cleanup
docker stop test-backend && docker rm test-backend
```

### Performance Tests

```bash
# Run benchmarks
./tests/benchmarks/supacrypt-pkcs11-benchmarks

# Generate detailed report
./tests/benchmarks/supacrypt-pkcs11-benchmarks \
    --benchmark_format=json \
    --benchmark_out=results.json
```

## Submitting Changes

### Workflow

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Update documentation
6. Submit pull request

### Commit Messages

Follow the Conventional Commits specification:

```
type(scope): subject

body

footer
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `test`: Testing
- `perf`: Performance
- `refactor`: Code refactoring
- `ci`: CI/CD changes

Example:
```
feat(crypto): add support for RSA-PSS signing

- Implement RSA-PSS mechanism support
- Add padding parameter validation
- Update mechanism list

Closes #123
```

### Pull Request Process

1. Ensure all tests pass
2. Update relevant documentation
3. Add entry to CHANGELOG.md
4. Request review from maintainers

## Development Tips

### Debug Build

```bash
# Enable all debug features
cmake .. -DCMAKE_BUILD_TYPE=Debug \
         -DENABLE_SANITIZERS=ON \
         -DCMAKE_CXX_FLAGS="-O0 -g3"
```

### Using GDB

```bash
# Debug with GDB
gdb ./your-test-program
(gdb) set environment LD_LIBRARY_PATH=./src
(gdb) break C_Initialize
(gdb) run
```

### Memory Debugging

```bash
# AddressSanitizer
export ASAN_OPTIONS=detect_leaks=1
./tests/unit/supacrypt-pkcs11-unit-tests

# Valgrind
valgrind --tool=memcheck --leak-check=full \
         --show-leak-kinds=all ./your-program
```

## Architecture Overview

### Component Diagram

```
┌─────────────────┐
│   Application   │
└────────┬────────┘
         │ PKCS#11 API
┌────────▼────────┐
│  State Manager  │ ← Singleton, manages global state
├─────────────────┤
│ Session Manager │ ← Per-session state and operations
├─────────────────┤
│  Object Cache   │ ← Key handle management
├─────────────────┤
│ gRPC Pool       │ ← Connection management
├─────────────────┤
│ Circuit Breaker │ ← Resilience
└────────┬────────┘
         │ gRPC + mTLS
┌────────▼────────┐
│ Backend Service │
└─────────────────┘
```

### Adding New Features

1. Update protobuf if needed
2. Implement in appropriate layer
3. Add error handling
4. Update tests
5. Document changes

## Release Process

1. Update version in CMakeLists.txt
2. Update CHANGELOG.md
3. Tag release: `git tag -s v1.2.3`
4. Push tag: `git push origin v1.2.3`
5. CI builds and publishes

## Getting Help

- Discord: https://discord.gg/supacrypt
- Discussions: https://github.com/supacrypt/supacrypt-pkcs11/discussions
- Email: dev@supacrypt.io

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
```

## Implementation Steps

1. **Create Main Documentation**
   - Write comprehensive README.md
   - Create detailed user guide
   - Complete API reference

2. **Platform Guides**
   - Linux installation and integration
   - Windows setup and registry
   - macOS security and signing

3. **Code Examples**
   - Basic usage example
   - Multi-threading example
   - Error handling patterns
   - Performance optimization

4. **Support Documentation**
   - Troubleshooting guide
   - FAQ document
   - Performance tuning

5. **Developer Documentation**
   - Architecture overview
   - Contributing guidelines
   - API development guide

## Validation Criteria
Your implementation will be considered complete when:
1. ✅ README provides clear overview and quick start
2. ✅ User guide covers all major use cases
3. ✅ API reference documents all functions
4. ✅ Installation guides work for all platforms
5. ✅ Code examples compile and run correctly
6. ✅ Troubleshooting covers common issues
7. ✅ Configuration is fully documented
8. ✅ Security considerations are highlighted
9. ✅ Performance characteristics documented
10. ✅ Contributing guide enables new developers

## Important Notes
- Use clear, concise language
- Include plenty of code examples
- Test all commands and code snippets
- Keep security warnings prominent
- Update based on user feedback

## Memory Bank Logging
Document your work in `supacrypt-common/Memory/Phase_3_PKCS11_Provider/Task_3_5_Documentation_Log.md` following the established format. Include:
- Documentation structure decisions
- User feedback incorporation
- Platform-specific considerations
- Example code validation results
- Any gaps identified for future updates

Begin by creating the main README.md with comprehensive overview.