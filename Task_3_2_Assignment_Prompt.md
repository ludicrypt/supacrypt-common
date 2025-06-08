# Task Assignment: PKCS#11 Core Implementation

## Agent Profile
**Type:** Implementation Agent - PKCS#11 Specialist  
**Expertise Required:** PKCS#11 Specification, C/C++ Systems Programming, Cryptographic APIs, Multi-threading, State Management

## Task Overview
Implement the core PKCS#11 v2.40 interface functions that bridge the standard PKCS#11 C API with the Supacrypt gRPC backend service. Create a fully functional PKCS#11 provider that delegates all cryptographic operations to the backend while maintaining complete PKCS#11 compatibility.

## Context
- **Repository:** `supacrypt-pkcs11`
- **Current State:** CMake build system complete with stub implementations
- **Target:** Production-ready PKCS#11 provider with backend delegation
- **Integration:** Must connect to supacrypt-backend-akv via gRPC with mTLS

## Detailed Requirements

### 1. Core Initialization Functions

#### C_Initialize Implementation
```cpp
// src/core/pkcs11_init.cpp
CK_RV C_Initialize(CK_VOID_PTR pInitArgs) {
    // Implementation requirements:
    // 1. Parse CK_C_INITIALIZE_ARGS if provided
    // 2. Initialize global state manager
    // 3. Set up gRPC channel to backend
    // 4. Load configuration from environment/files
    // 5. Initialize OpenTelemetry if enabled
    // 6. Set up thread safety mechanisms
    // 7. Return CKR_OK or appropriate error
}

CK_RV C_Finalize(CK_VOID_PTR pReserved) {
    // Implementation requirements:
    // 1. Close all active sessions
    // 2. Shut down gRPC channels gracefully
    // 3. Clean up global state
    // 4. Release all resources
    // 5. Ensure thread-safe cleanup
}
```

#### Configuration Management
```cpp
// Configuration structure for backend connection
struct SupacryptConfig {
    std::string backendEndpoint = "localhost:5000";
    std::string clientCertPath;
    std::string clientKeyPath;
    std::string caCertPath;
    bool useMtls = true;
    std::chrono::seconds connectionTimeout{30};
    uint32_t maxRetries = 3;
};

// Supacrypt-specific extension
CK_RV SC_Configure(CK_UTF8CHAR_PTR configJson) {
    // Parse JSON configuration
    // Update backend connection settings
    // Reconnect if necessary
}
```

### 2. Session Management Implementation

#### Session State Architecture
```cpp
// src/core/session_state.h
class SessionState {
public:
    enum class OperationType {
        None,
        Sign,
        Verify,
        Encrypt,
        Decrypt,
        Digest
    };

    struct OperationContext {
        OperationType type = OperationType::None;
        CK_MECHANISM mechanism;
        std::string keyId;  // Backend key identifier
        std::vector<uint8_t> accumulatedData;
        bool isMultiPart = false;
    };

private:
    CK_SESSION_HANDLE handle;
    CK_FLAGS flags;
    CK_STATE state;
    OperationContext activeOperation;
    std::shared_mutex mutex;
    
public:
    // Thread-safe session operations
    CK_RV beginOperation(OperationType type, CK_MECHANISM_PTR pMechanism, const std::string& keyId);
    CK_RV updateOperation(CK_BYTE_PTR pData, CK_ULONG dataLen);
    CK_RV finalizeOperation(CK_BYTE_PTR pSignature, CK_ULONG_PTR pSignatureLen);
    void cancelOperation();
};
```

#### Session Functions
```cpp
// src/core/pkcs11_session.cpp
CK_RV C_OpenSession(
    CK_SLOT_ID slotID,
    CK_FLAGS flags,
    CK_VOID_PTR pApplication,
    CK_NOTIFY Notify,
    CK_SESSION_HANDLE_PTR phSession
) {
    // 1. Validate slot ID (we support single slot: 1)
    // 2. Create new session with unique handle
    // 3. Store session in global session manager
    // 4. Initialize session state
    // 5. Return session handle
}

CK_RV C_CloseSession(CK_SESSION_HANDLE hSession) {
    // 1. Find session in manager
    // 2. Cancel any active operations
    // 3. Clean up session resources
    // 4. Remove from session manager
}

CK_RV C_GetSessionInfo(CK_SESSION_HANDLE hSession, CK_SESSION_INFO_PTR pInfo) {
    // Return session state, flags, device info
}
```

### 3. Key Management Implementation

#### Key Generation
```cpp
// src/core/pkcs11_key.cpp
CK_RV C_GenerateKeyPair(
    CK_SESSION_HANDLE hSession,
    CK_MECHANISM_PTR pMechanism,
    CK_ATTRIBUTE_PTR pPublicKeyTemplate,
    CK_ULONG ulPublicKeyAttributeCount,
    CK_ATTRIBUTE_PTR pPrivateKeyTemplate,
    CK_ULONG ulPrivateKeyAttributeCount,
    CK_OBJECT_HANDLE_PTR phPublicKey,
    CK_OBJECT_HANDLE_PTR phPrivateKey
) {
    // 1. Validate session and mechanism
    // 2. Parse key attributes (size, label, ID)
    // 3. Map to GenerateKeyRequest protobuf
    // 4. Call backend gRPC GenerateKey
    // 5. Create local object entries
    // 6. Return object handles
    
    // Example attribute parsing:
    KeyAlgorithm algorithm;
    uint32_t keySize = 0;
    std::string label;
    
    for (size_t i = 0; i < ulPublicKeyAttributeCount; ++i) {
        switch (pPublicKeyTemplate[i].type) {
            case CKA_KEY_TYPE:
                // Map CKK_RSA -> KEY_ALGORITHM_RSA_2048/4096
                // Map CKK_EC -> KEY_ALGORITHM_ECC_P256/P384
                break;
            case CKA_MODULUS_BITS:
                keySize = *((CK_ULONG*)pPublicKeyTemplate[i].pValue);
                break;
            case CKA_LABEL:
                label.assign((char*)pPublicKeyTemplate[i].pValue, 
                           pPublicKeyTemplate[i].ulValueLen);
                break;
        }
    }
}
```

#### Object Management
```cpp
// src/core/pkcs11_object.cpp
class ObjectCache {
private:
    struct ObjectEntry {
        CK_OBJECT_HANDLE handle;
        std::string backendKeyId;
        CK_OBJECT_CLASS objectClass;
        std::map<CK_ATTRIBUTE_TYPE, std::vector<uint8_t>> attributes;
    };
    
    std::shared_mutex cacheMutex;
    std::unordered_map<CK_OBJECT_HANDLE, ObjectEntry> objects;
    std::atomic<CK_OBJECT_HANDLE> nextHandle{1000};
    
public:
    CK_OBJECT_HANDLE addObject(const std::string& keyId, CK_OBJECT_CLASS objClass);
    bool getObject(CK_OBJECT_HANDLE handle, ObjectEntry& entry);
    std::vector<CK_OBJECT_HANDLE> findObjects(CK_ATTRIBUTE_PTR pTemplate, CK_ULONG count);
};

CK_RV C_FindObjectsInit(
    CK_SESSION_HANDLE hSession,
    CK_ATTRIBUTE_PTR pTemplate,
    CK_ULONG ulCount
) {
    // 1. Store search criteria in session
    // 2. Optionally fetch key list from backend
    // 3. Prepare filtered results
}
```

### 4. Cryptographic Operations

#### Signing Implementation
```cpp
// src/core/pkcs11_crypto.cpp
CK_RV C_SignInit(
    CK_SESSION_HANDLE hSession,
    CK_MECHANISM_PTR pMechanism,
    CK_OBJECT_HANDLE hKey
) {
    // 1. Validate session and mechanism
    // 2. Map mechanism to SignatureAlgorithm
    // 3. Get key ID from object cache
    // 4. Initialize operation in session state
    
    // Mechanism mapping:
    switch (pMechanism->mechanism) {
        case CKM_RSA_PKCS:
            algorithm = SIGNATURE_ALGORITHM_RSA_PKCS1;
            break;
        case CKM_RSA_PKCS_PSS:
            algorithm = SIGNATURE_ALGORITHM_RSA_PSS;
            break;
        case CKM_ECDSA:
            algorithm = SIGNATURE_ALGORITHM_ECDSA_P256;
            break;
        // Add more mechanisms
    }
}

CK_RV C_Sign(
    CK_SESSION_HANDLE hSession,
    CK_BYTE_PTR pData,
    CK_ULONG ulDataLen,
    CK_BYTE_PTR pSignature,
    CK_ULONG_PTR pulSignatureLen
) {
    // 1. Get session and verify operation state
    // 2. Create SignDataRequest protobuf
    // 3. Call backend gRPC SignData
    // 4. Handle size query (pSignature == NULL)
    // 5. Copy signature to output buffer
    // 6. Clear operation state
    
    if (pSignature == nullptr) {
        // Return required signature size
        *pulSignatureLen = getSignatureSize(session->mechanism);
        return CKR_OK;
    }
}

// Multi-part operations
CK_RV C_SignUpdate(
    CK_SESSION_HANDLE hSession,
    CK_BYTE_PTR pPart,
    CK_ULONG ulPartLen
) {
    // Accumulate data in session state
}

CK_RV C_SignFinal(
    CK_SESSION_HANDLE hSession,
    CK_BYTE_PTR pSignature,
    CK_ULONG_PTR pulSignatureLen
) {
    // Sign accumulated data
}
```

### 5. gRPC Client Implementation

#### Connection Management
```cpp
// src/grpc/grpc_client.cpp
class GrpcConnectionPool {
private:
    struct Connection {
        std::shared_ptr<grpc::Channel> channel;
        std::unique_ptr<SupacryptService::Stub> stub;
        std::chrono::steady_clock::time_point lastUsed;
    };
    
    std::vector<Connection> connections;
    std::mutex poolMutex;
    SupacryptConfig config;
    
public:
    std::shared_ptr<SupacryptService::Stub> getConnection();
    void returnConnection(std::shared_ptr<SupacryptService::Stub> stub);
    
private:
    std::shared_ptr<grpc::Channel> createSecureChannel();
};

// Create mTLS channel
std::shared_ptr<grpc::Channel> createSecureChannel() {
    grpc::SslCredentialsOptions sslOpts;
    sslOpts.pem_root_certs = readFile(config.caCertPath);
    sslOpts.pem_private_key = readFile(config.clientKeyPath);
    sslOpts.pem_cert_chain = readFile(config.clientCertPath);
    
    auto creds = grpc::SslCredentials(sslOpts);
    grpc::ChannelArguments args;
    args.SetMaxReceiveMessageSize(4 * 1024 * 1024); // 4MB
    
    return grpc::CreateCustomChannel(config.backendEndpoint, creds, args);
}
```

#### RPC Wrapper with Error Handling
```cpp
template<typename RequestType, typename ResponseType>
CK_RV executeRpc(
    const std::string& operationName,
    const RequestType& request,
    ResponseType& response,
    std::function<grpc::Status(SupacryptService::Stub*, grpc::ClientContext*, 
                               const RequestType&, ResponseType*)> rpcCall
) {
    auto stub = connectionPool.getConnection();
    grpc::ClientContext context;
    
    // Add timeout
    context.set_deadline(std::chrono::system_clock::now() + config.connectionTimeout);
    
    // Add metadata for tracing
    context.AddMetadata("x-operation-id", generateOperationId());
    
    // Execute with retry
    for (uint32_t attempt = 0; attempt <= config.maxRetries; ++attempt) {
        grpc::Status status = rpcCall(stub.get(), &context, request, &response);
        
        if (status.ok()) {
            return CKR_OK;
        }
        
        // Map gRPC status to PKCS#11 error
        if (status.error_code() == grpc::StatusCode::NOT_FOUND) {
            return CKR_KEY_HANDLE_INVALID;
        }
        
        if (!isRetryable(status) || attempt == config.maxRetries) {
            return mapGrpcError(status);
        }
        
        // Exponential backoff
        std::this_thread::sleep_for(std::chrono::milliseconds(100 * (1 << attempt)));
    }
    
    return CKR_FUNCTION_FAILED;
}
```

### 6. Error Handling and Mapping

#### Error Translation
```cpp
// src/utils/error_mapping.cpp
CK_RV mapGrpcError(const grpc::Status& status) {
    if (status.ok()) return CKR_OK;
    
    // Parse error details from status
    ErrorResponse errorResponse;
    for (const auto& detail : status.error_details()) {
        if (detail.Is<ErrorResponse>()) {
            detail.UnpackTo(&errorResponse);
            break;
        }
    }
    
    // Map error codes
    switch (errorResponse.code()) {
        case ErrorCode::ERROR_CODE_KEY_NOT_FOUND:
            return CKR_KEY_HANDLE_INVALID;
        case ErrorCode::ERROR_CODE_PERMISSION_DENIED:
            return CKR_KEY_FUNCTION_NOT_PERMITTED;
        case ErrorCode::ERROR_CODE_INVALID_KEY_SIZE:
            return CKR_KEY_SIZE_RANGE;
        case ErrorCode::ERROR_CODE_UNSUPPORTED_ALGORITHM:
            return CKR_MECHANISM_INVALID;
        case ErrorCode::ERROR_CODE_RATE_LIMITED:
            return CKR_DEVICE_ERROR; // With logging
        default:
            return CKR_GENERAL_ERROR;
    }
}

// Supacrypt extension for detailed errors
CK_RV SC_GetErrorString(CK_RV errorCode, CK_UTF8CHAR_PTR buffer, CK_ULONG_PTR bufferLen) {
    // Return human-readable error description
}
```

### 7. Thread Safety Implementation

#### Global State Manager
```cpp
// src/core/state_manager.h
class StateManager {
private:
    static StateManager* instance;
    static std::once_flag initFlag;
    
    std::shared_mutex sessionMutex;
    std::unordered_map<CK_SESSION_HANDLE, std::unique_ptr<SessionState>> sessions;
    
    std::atomic<CK_SESSION_HANDLE> nextSessionHandle{1};
    std::atomic<bool> initialized{false};
    
    ObjectCache objectCache;
    GrpcConnectionPool connectionPool;
    
    StateManager() = default;
    
public:
    static StateManager& getInstance();
    
    // Thread-safe operations
    CK_RV createSession(CK_FLAGS flags, CK_SESSION_HANDLE_PTR phSession);
    CK_RV getSession(CK_SESSION_HANDLE hSession, SessionState** ppSession);
    CK_RV removeSession(CK_SESSION_HANDLE hSession);
    
    // Object operations
    ObjectCache& getObjectCache() { return objectCache; }
    
    // Connection operations
    GrpcConnectionPool& getConnectionPool() { return connectionPool; }
};
```

### 8. Observability Integration

#### Metrics and Tracing
```cpp
// src/observability/metrics.cpp
class PkcsMetrics {
private:
    opentelemetry::metrics::Counter* operationCounter;
    opentelemetry::metrics::Histogram* operationLatency;
    
public:
    void recordOperation(const std::string& operation, CK_RV result, 
                        std::chrono::microseconds duration) {
        operationCounter->Add(1, {
            {"operation", operation},
            {"result", resultToString(result)}
        });
        
        operationLatency->Record(duration.count(), {
            {"operation", operation}
        });
    }
};

// Usage in operations
class OperationTimer {
    std::chrono::steady_clock::time_point start;
    std::string operation;
    
public:
    OperationTimer(const std::string& op) : operation(op), 
        start(std::chrono::steady_clock::now()) {}
    
    ~OperationTimer() {
        auto duration = std::chrono::duration_cast<std::chrono::microseconds>(
            std::chrono::steady_clock::now() - start);
        metrics.recordOperation(operation, result, duration);
    }
};
```

### 9. Security Considerations

#### Secure Memory Handling
```cpp
// src/security/secure_memory.cpp
template<typename T>
class SecureVector {
private:
    std::vector<T> data;
    
public:
    ~SecureVector() {
        // Zero memory before deallocation
        if (!data.empty()) {
            volatile T* p = data.data();
            std::fill(p, p + data.size(), T{});
        }
    }
    
    // Prevent copying
    SecureVector(const SecureVector&) = delete;
    SecureVector& operator=(const SecureVector&) = delete;
    
    // Allow moving
    SecureVector(SecureVector&&) = default;
    SecureVector& operator=(SecureVector&&) = default;
};
```

### 10. Testing Implementation

#### Unit Test Structure
```cpp
// tests/unit/test_pkcs11_init.cpp
TEST(Pkcs11Init, InitializeWithNullArgs) {
    CK_RV rv = C_Initialize(nullptr);
    EXPECT_EQ(rv, CKR_OK);
    
    // Verify initialized state
    CK_INFO info;
    rv = C_GetInfo(&info);
    EXPECT_EQ(rv, CKR_OK);
    
    rv = C_Finalize(nullptr);
    EXPECT_EQ(rv, CKR_OK);
}

TEST(Pkcs11Init, DoubleInitializeFails) {
    CK_RV rv = C_Initialize(nullptr);
    EXPECT_EQ(rv, CKR_OK);
    
    rv = C_Initialize(nullptr);
    EXPECT_EQ(rv, CKR_CRYPTOKI_ALREADY_INITIALIZED);
    
    rv = C_Finalize(nullptr);
    EXPECT_EQ(rv, CKR_OK);
}
```

## Implementation Steps

1. **Core Infrastructure**
   - Implement StateManager singleton
   - Set up gRPC connection pool
   - Create error mapping utilities

2. **Basic Operations**
   - C_Initialize/C_Finalize
   - C_GetInfo/C_GetSlotList
   - Basic session management

3. **Key Operations**
   - C_GenerateKeyPair for RSA/ECC
   - Object cache implementation
   - C_FindObjects functionality

4. **Cryptographic Functions**
   - Sign/Verify operations
   - Single and multi-part support
   - Mechanism validation

5. **Advanced Features**
   - Thread safety verification
   - Performance optimization
   - Observability integration

## Validation Criteria
Your implementation will be considered complete when:
1. ✅ All core PKCS#11 functions implemented and functional
2. ✅ gRPC client successfully communicates with backend
3. ✅ Proper error handling and mapping in place
4. ✅ Thread safety verified with concurrent tests
5. ✅ Session and object management working correctly
6. ✅ Cryptographic operations (generate, sign, verify) functional
7. ✅ Unit tests achieve >80% code coverage
8. ✅ Integration tests pass with mock backend
9. ✅ Memory safety verified (no leaks, secure cleanup)
10. ✅ Performance meets baseline (<10ms for local operations)

## Important Notes
- Follow PKCS#11 v2.40 specification exactly for binary compatibility
- Use existing protobuf definitions from supacrypt-common
- Implement proper cleanup in all error paths
- Document any deviations or limitations
- Consider future extensibility for new mechanisms

## Memory Bank Logging
Document your work in `supacrypt-common/Memory/Phase_3_PKCS11_Provider/Task_3_2_Core_Implementation_Log.md` following the established format. Include:
- Implementation decisions and rationale
- Performance characteristics
- Security considerations addressed
- Testing coverage achieved
- Any limitations or known issues

Begin by implementing the core initialization and session management functions.