# Task Assignment: Complete gRPC Integration for Cryptographic Operations

## Agent Profile
**Type:** Implementation Agent - Integration Developer  
**Expertise Required:** gRPC/Protobuf, C++ Systems Programming, PKCS#11 Cryptographic Operations, Asynchronous Programming

## Task Overview
Complete the gRPC integration by generating protobuf stubs and implementing all cryptographic operations that communicate with the supacrypt-backend-akv service. Build upon the existing gRPC infrastructure from Task 3.2 to deliver fully functional PKCS#11 cryptographic operations.

## Context
- **Repository:** `supacrypt-pkcs11`
- **Current State:** Core PKCS#11 and gRPC infrastructure complete, cryptographic operations pending
- **Target:** Fully functional PKCS#11 provider with all crypto operations delegated to backend
- **Integration:** Must use existing GrpcConnectionPool and error mapping from Task 3.2

## Detailed Requirements

### 1. Protobuf Stub Generation

#### Update CMake for Protobuf Generation
```cmake
# cmake/ProtoGeneration.cmake
set(PROTO_PATH "${CMAKE_SOURCE_DIR}/../supacrypt-common/proto")
set(PROTO_FILE "${PROTO_PATH}/supacrypt.proto")

# Find protoc and grpc_cpp_plugin
find_program(PROTOC protoc)
find_program(GRPC_CPP_PLUGIN grpc_cpp_plugin)

# Generate C++ protobuf and gRPC files
set(PROTO_SRCS "${CMAKE_CURRENT_BINARY_DIR}/supacrypt.pb.cc")
set(PROTO_HDRS "${CMAKE_CURRENT_BINARY_DIR}/supacrypt.pb.h")
set(GRPC_SRCS "${CMAKE_CURRENT_BINARY_DIR}/supacrypt.grpc.pb.cc")
set(GRPC_HDRS "${CMAKE_CURRENT_BINARY_DIR}/supacrypt.grpc.pb.h")

add_custom_command(
    OUTPUT ${PROTO_SRCS} ${PROTO_HDRS} ${GRPC_SRCS} ${GRPC_HDRS}
    COMMAND ${PROTOC}
    ARGS --grpc_out "${CMAKE_CURRENT_BINARY_DIR}"
         --cpp_out "${CMAKE_CURRENT_BINARY_DIR}"
         -I "${PROTO_PATH}"
         --plugin=protoc-gen-grpc="${GRPC_CPP_PLUGIN}"
         "${PROTO_FILE}"
    DEPENDS "${PROTO_FILE}"
)

# Add generated sources to library
target_sources(supacrypt-pkcs11 PRIVATE
    ${PROTO_SRCS}
    ${GRPC_SRCS}
)

# Include generated headers
target_include_directories(supacrypt-pkcs11 PRIVATE
    ${CMAKE_CURRENT_BINARY_DIR}
)
```

#### Update GrpcConnectionPool to Use Generated Stubs
```cpp
// src/grpc/grpc_connection_pool.cpp
#include "supacrypt.grpc.pb.h"

void GrpcConnectionPool::initialize() {
    // Update connection creation to use generated stub
    for (size_t i = 0; i < poolSize; ++i) {
        Connection conn;
        conn.channel = createSecureChannel();
        conn.stub = supacrypt::SupacryptService::NewStub(conn.channel);
        conn.lastUsed = std::chrono::steady_clock::now();
        connections.push_back(std::move(conn));
    }
}
```

### 2. Cryptographic Operation Implementation

#### Key Generation
```cpp
// src/core/pkcs11_crypto.cpp
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
    try {
        if (!StateManager::getInstance().isInitialized()) {
            return CKR_CRYPTOKI_NOT_INITIALIZED;
        }
        
        // Validate session
        SessionState* session = nullptr;
        CK_RV rv = StateManager::getInstance().getSession(hSession, &session);
        if (rv != CKR_OK) return rv;
        
        // Parse key attributes
        KeyAttributes attrs = parseKeyAttributes(pPublicKeyTemplate, 
                                               ulPublicKeyAttributeCount,
                                               pPrivateKeyTemplate,
                                               ulPrivateKeyAttributeCount);
        
        // Create GenerateKeyRequest
        supacrypt::GenerateKeyRequest request;
        
        // Map key type and size
        switch (attrs.keyType) {
            case CKK_RSA:
                if (attrs.modulusBits == 2048) {
                    request.set_algorithm(supacrypt::KEY_ALGORITHM_RSA_2048);
                } else if (attrs.modulusBits == 4096) {
                    request.set_algorithm(supacrypt::KEY_ALGORITHM_RSA_4096);
                } else {
                    return CKR_KEY_SIZE_RANGE;
                }
                break;
                
            case CKK_EC:
                // Map EC curve to algorithm
                if (attrs.ecParams == EC_P256_PARAMS) {
                    request.set_algorithm(supacrypt::KEY_ALGORITHM_ECC_P256);
                } else if (attrs.ecParams == EC_P384_PARAMS) {
                    request.set_algorithm(supacrypt::KEY_ALGORITHM_ECC_P384);
                } else {
                    return CKR_DOMAIN_PARAMS_INVALID;
                }
                break;
                
            default:
                return CKR_KEY_TYPE_INCONSISTENT;
        }
        
        // Set key metadata
        auto* metadata = request.mutable_key_metadata();
        metadata->set_key_name(attrs.label);
        metadata->set_key_usage(mapUsageFlags(attrs.usage));
        
        // Execute RPC
        supacrypt::GenerateKeyResponse response;
        auto& pool = StateManager::getInstance().getConnectionPool();
        
        rv = pool.executeRpc<supacrypt::GenerateKeyRequest, 
                            supacrypt::GenerateKeyResponse>(
            "GenerateKey",
            request,
            response,
            [](auto* stub, auto* ctx, const auto& req, auto* resp) {
                return stub->GenerateKey(ctx, req, resp);
            }
        );
        
        if (rv != CKR_OK) return rv;
        
        // Create object cache entries
        auto& cache = StateManager::getInstance().getObjectCache();
        
        // Add public key object
        *phPublicKey = cache.addObject(response.key_id(), CKO_PUBLIC_KEY, attrs);
        
        // Add private key object with same ID
        *phPrivateKey = cache.addObject(response.key_id(), CKO_PRIVATE_KEY, attrs);
        
        return CKR_OK;
    } catch (const std::exception& e) {
        logError("C_GenerateKeyPair exception: " + std::string(e.what()));
        return CKR_GENERAL_ERROR;
    }
}
```

#### Signing Operations
```cpp
// src/core/pkcs11_crypto.cpp
CK_RV C_SignInit(
    CK_SESSION_HANDLE hSession,
    CK_MECHANISM_PTR pMechanism,
    CK_OBJECT_HANDLE hKey
) {
    try {
        if (!StateManager::getInstance().isInitialized()) {
            return CKR_CRYPTOKI_NOT_INITIALIZED;
        }
        
        if (pMechanism == nullptr) {
            return CKR_ARGUMENTS_BAD;
        }
        
        SessionState* session = nullptr;
        CK_RV rv = StateManager::getInstance().getSession(hSession, &session);
        if (rv != CKR_OK) return rv;
        
        // Get key information from cache
        auto& cache = StateManager::getInstance().getObjectCache();
        ObjectEntry entry;
        if (!cache.getObject(hKey, entry)) {
            return CKR_KEY_HANDLE_INVALID;
        }
        
        // Validate key type for signing
        if (entry.objectClass != CKO_PRIVATE_KEY) {
            return CKR_KEY_TYPE_INCONSISTENT;
        }
        
        // Map mechanism to signature algorithm
        supacrypt::SignatureAlgorithm algorithm;
        rv = mapMechanismToSignatureAlgorithm(pMechanism, algorithm);
        if (rv != CKR_OK) return rv;
        
        // Initialize signing operation in session
        rv = session->beginOperation(SessionState::OperationType::Sign, 
                                   pMechanism, entry.backendKeyId, algorithm);
        return rv;
    } catch (const std::exception& e) {
        return CKR_GENERAL_ERROR;
    }
}

CK_RV C_Sign(
    CK_SESSION_HANDLE hSession,
    CK_BYTE_PTR pData,
    CK_ULONG ulDataLen,
    CK_BYTE_PTR pSignature,
    CK_ULONG_PTR pulSignatureLen
) {
    try {
        if (!StateManager::getInstance().isInitialized()) {
            return CKR_CRYPTOKI_NOT_INITIALIZED;
        }
        
        if (pulSignatureLen == nullptr) {
            return CKR_ARGUMENTS_BAD;
        }
        
        SessionState* session = nullptr;
        CK_RV rv = StateManager::getInstance().getSession(hSession, &session);
        if (rv != CKR_OK) return rv;
        
        // Get operation context
        auto context = session->getOperationContext();
        if (context.type != SessionState::OperationType::Sign) {
            return CKR_OPERATION_NOT_INITIALIZED;
        }
        
        // Handle size query
        size_t expectedSize = getSignatureSize(context.algorithm);
        if (pSignature == nullptr) {
            *pulSignatureLen = expectedSize;
            return CKR_OK;
        }
        
        if (*pulSignatureLen < expectedSize) {
            *pulSignatureLen = expectedSize;
            return CKR_BUFFER_TOO_SMALL;
        }
        
        // Create SignDataRequest
        supacrypt::SignDataRequest request;
        request.set_key_id(context.keyId);
        request.set_algorithm(context.algorithm);
        request.set_data(pData, ulDataLen);
        
        // Add hash algorithm if needed
        if (context.hashAlgorithm != supacrypt::HASH_ALGORITHM_NONE) {
            request.set_hash_algorithm(context.hashAlgorithm);
        }
        
        // Execute RPC
        supacrypt::SignDataResponse response;
        auto& pool = StateManager::getInstance().getConnectionPool();
        
        rv = pool.executeRpc<supacrypt::SignDataRequest, 
                            supacrypt::SignDataResponse>(
            "SignData",
            request,
            response,
            [](auto* stub, auto* ctx, const auto& req, auto* resp) {
                return stub->SignData(ctx, req, resp);
            }
        );
        
        if (rv != CKR_OK) {
            session->cancelOperation();
            return rv;
        }
        
        // Copy signature to output
        if (response.signature().size() > *pulSignatureLen) {
            *pulSignatureLen = response.signature().size();
            session->cancelOperation();
            return CKR_BUFFER_TOO_SMALL;
        }
        
        std::memcpy(pSignature, response.signature().data(), response.signature().size());
        *pulSignatureLen = response.signature().size();
        
        // Clear operation state
        session->cancelOperation();
        
        return CKR_OK;
    } catch (const std::exception& e) {
        return CKR_GENERAL_ERROR;
    }
}

// Multi-part signing support
CK_RV C_SignUpdate(
    CK_SESSION_HANDLE hSession,
    CK_BYTE_PTR pPart,
    CK_ULONG ulPartLen
) {
    try {
        SessionState* session = nullptr;
        CK_RV rv = StateManager::getInstance().getSession(hSession, &session);
        if (rv != CKR_OK) return rv;
        
        rv = session->updateOperation(pPart, ulPartLen);
        return rv;
    } catch (const std::exception& e) {
        return CKR_GENERAL_ERROR;
    }
}

CK_RV C_SignFinal(
    CK_SESSION_HANDLE hSession,
    CK_BYTE_PTR pSignature,
    CK_ULONG_PTR pulSignatureLen
) {
    try {
        SessionState* session = nullptr;
        CK_RV rv = StateManager::getInstance().getSession(hSession, &session);
        if (rv != CKR_OK) return rv;
        
        // Get accumulated data
        auto context = session->getOperationContext();
        if (context.type != SessionState::OperationType::Sign) {
            return CKR_OPERATION_NOT_INITIALIZED;
        }
        
        // Sign accumulated data
        return signData(session, context.accumulatedData.data(), 
                       context.accumulatedData.size(), 
                       pSignature, pulSignatureLen);
    } catch (const std::exception& e) {
        return CKR_GENERAL_ERROR;
    }
}
```

#### Verification Operations
```cpp
// src/core/pkcs11_crypto.cpp
CK_RV C_VerifyInit(
    CK_SESSION_HANDLE hSession,
    CK_MECHANISM_PTR pMechanism,
    CK_OBJECT_HANDLE hKey
) {
    // Similar to C_SignInit but for verification
    // Validates public key instead of private key
}

CK_RV C_Verify(
    CK_SESSION_HANDLE hSession,
    CK_BYTE_PTR pData,
    CK_ULONG ulDataLen,
    CK_BYTE_PTR pSignature,
    CK_ULONG ulSignatureLen
) {
    try {
        // Create VerifySignatureRequest
        supacrypt::VerifySignatureRequest request;
        request.set_key_id(context.keyId);
        request.set_algorithm(context.algorithm);
        request.set_data(pData, ulDataLen);
        request.set_signature(pSignature, ulSignatureLen);
        
        // Execute RPC
        supacrypt::VerifySignatureResponse response;
        auto& pool = StateManager::getInstance().getConnectionPool();
        
        rv = pool.executeRpc<supacrypt::VerifySignatureRequest, 
                            supacrypt::VerifySignatureResponse>(
            "VerifySignature",
            request,
            response,
            [](auto* stub, auto* ctx, const auto& req, auto* resp) {
                return stub->VerifySignature(ctx, req, resp);
            }
        );
        
        if (rv != CKR_OK) {
            session->cancelOperation();
            return rv;
        }
        
        // Check verification result
        if (!response.valid()) {
            session->cancelOperation();
            return CKR_SIGNATURE_INVALID;
        }
        
        session->cancelOperation();
        return CKR_OK;
    } catch (const std::exception& e) {
        return CKR_GENERAL_ERROR;
    }
}
```

### 3. Enhanced Error Mapping

#### Complete Error Translation
```cpp
// src/utils/error_mapping.cpp
CK_RV mapGrpcDetailedError(const grpc::Status& status) {
    if (status.ok()) return CKR_OK;
    
    // Extract ErrorResponse from status details
    supacrypt::ErrorResponse errorResponse;
    bool hasErrorResponse = false;
    
    // Parse error details
    auto metadata = status.error_details();
    if (!metadata.empty()) {
        // Attempt to parse as ErrorResponse
        if (errorResponse.ParseFromString(metadata)) {
            hasErrorResponse = true;
        }
    }
    
    if (hasErrorResponse) {
        // Map specific error codes
        switch (errorResponse.code()) {
            case supacrypt::ERROR_CODE_KEY_NOT_FOUND:
                return CKR_KEY_HANDLE_INVALID;
            case supacrypt::ERROR_CODE_PERMISSION_DENIED:
                return CKR_KEY_FUNCTION_NOT_PERMITTED;
            case supacrypt::ERROR_CODE_INVALID_KEY_SIZE:
                return CKR_KEY_SIZE_RANGE;
            case supacrypt::ERROR_CODE_UNSUPPORTED_ALGORITHM:
                return CKR_MECHANISM_INVALID;
            case supacrypt::ERROR_CODE_INVALID_SIGNATURE:
                return CKR_SIGNATURE_INVALID;
            case supacrypt::ERROR_CODE_RATE_LIMITED:
                logWarning("Rate limited by backend: " + errorResponse.message());
                return CKR_DEVICE_ERROR;
            case supacrypt::ERROR_CODE_AZURE_KV_ERROR:
                logError("Azure Key Vault error: " + errorResponse.message());
                return CKR_DEVICE_ERROR;
            default:
                return CKR_GENERAL_ERROR;
        }
    }
    
    // Fall back to status code mapping
    return mapGrpcStatusCode(status.error_code());
}
```

### 4. Asynchronous Operation Support

#### Async RPC Execution
```cpp
// src/grpc/grpc_async_executor.h
template<typename Request, typename Response>
class AsyncRpcExecutor {
private:
    grpc::CompletionQueue cq;
    std::thread completionThread;
    std::atomic<bool> shutdown{false};
    
public:
    struct AsyncCall {
        Response response;
        grpc::ClientContext context;
        grpc::Status status;
        std::promise<CK_RV> promise;
    };
    
    std::future<CK_RV> executeAsync(
        SupacryptService::Stub* stub,
        const Request& request,
        std::function<std::unique_ptr<grpc::ClientAsyncResponseReader<Response>>(
            SupacryptService::Stub*, grpc::ClientContext*, const Request&, 
            grpc::CompletionQueue*)> rpcMethod
    ) {
        auto call = std::make_unique<AsyncCall>();
        auto future = call->promise.get_future();
        
        // Set deadline
        call->context.set_deadline(
            std::chrono::system_clock::now() + std::chrono::seconds(30));
        
        // Start async call
        auto rpc = rpcMethod(stub, &call->context, request, &cq);
        rpc->Finish(&call->response, &call->status, call.get());
        
        return future;
    }
    
    void processCompletionQueue() {
        void* tag;
        bool ok;
        
        while (!shutdown && cq.Next(&tag, &ok)) {
            auto* call = static_cast<AsyncCall*>(tag);
            
            if (ok && call->status.ok()) {
                call->promise.set_value(CKR_OK);
            } else {
                call->promise.set_value(mapGrpcDetailedError(call->status));
            }
            
            delete call;
        }
    }
};
```

### 5. Circuit Breaker Implementation

#### Circuit Breaker Pattern
```cpp
// src/grpc/circuit_breaker.h
class CircuitBreaker {
private:
    enum class State { CLOSED, OPEN, HALF_OPEN };
    
    std::atomic<State> state{State::CLOSED};
    std::atomic<int> failureCount{0};
    std::atomic<int> successCount{0};
    std::chrono::steady_clock::time_point lastFailureTime;
    std::mutex stateMutex;
    
    const int failureThreshold = 5;
    const std::chrono::seconds timeout{60};
    const int successThreshold = 3;
    
public:
    bool allowRequest() {
        std::lock_guard<std::mutex> lock(stateMutex);
        
        switch (state.load()) {
            case State::CLOSED:
                return true;
                
            case State::OPEN:
                if (std::chrono::steady_clock::now() - lastFailureTime > timeout) {
                    state = State::HALF_OPEN;
                    successCount = 0;
                    return true;
                }
                return false;
                
            case State::HALF_OPEN:
                return true;
        }
        
        return false;
    }
    
    void recordSuccess() {
        std::lock_guard<std::mutex> lock(stateMutex);
        
        if (state == State::HALF_OPEN) {
            successCount++;
            if (successCount >= successThreshold) {
                state = State::CLOSED;
                failureCount = 0;
            }
        } else if (state == State::CLOSED) {
            failureCount = 0;
        }
    }
    
    void recordFailure() {
        std::lock_guard<std::mutex> lock(stateMutex);
        
        failureCount++;
        lastFailureTime = std::chrono::steady_clock::now();
        
        if (state == State::CLOSED && failureCount >= failureThreshold) {
            state = State::OPEN;
        } else if (state == State::HALF_OPEN) {
            state = State::OPEN;
        }
    }
};
```

### 6. Integration with OpenTelemetry

#### Add Tracing to RPC Calls
```cpp
// src/grpc/grpc_connection_pool.cpp
template<typename Request, typename Response>
CK_RV GrpcConnectionPool::executeRpc(...) {
    // Create span for tracing
    auto tracer = opentelemetry::trace::Provider::GetTracerProvider()->GetTracer(
        "supacrypt-pkcs11", SUPACRYPT_VERSION);
    
    auto span = tracer->StartSpan(operationName);
    auto scope = tracer->WithActiveSpan(span);
    
    // Add span attributes
    span->SetAttribute("rpc.system", "grpc");
    span->SetAttribute("rpc.service", "SupacryptService");
    span->SetAttribute("rpc.method", operationName);
    
    // Inject trace context into gRPC metadata
    context.AddMetadata("traceparent", getTraceParent(span));
    
    // Execute RPC with circuit breaker
    if (!circuitBreaker.allowRequest()) {
        span->SetStatus(opentelemetry::trace::StatusCode::kError, "Circuit breaker open");
        return CKR_DEVICE_ERROR;
    }
    
    auto status = rpcCall(stub.get(), &context, request, &response);
    
    if (status.ok()) {
        circuitBreaker.recordSuccess();
        span->SetStatus(opentelemetry::trace::StatusCode::kOk);
        return CKR_OK;
    } else {
        circuitBreaker.recordFailure();
        span->SetStatus(opentelemetry::trace::StatusCode::kError, status.error_message());
        return mapGrpcDetailedError(status);
    }
}
```

### 7. Object Attribute Mapping

#### Complete Attribute Translation
```cpp
// src/utils/attribute_mapper.cpp
void mapKeyMetadataToAttributes(
    const supacrypt::KeyMetadata& metadata,
    std::map<CK_ATTRIBUTE_TYPE, std::vector<uint8_t>>& attributes
) {
    // Map key ID
    setAttributeString(attributes, CKA_ID, metadata.key_id());
    
    // Map key label
    setAttributeString(attributes, CKA_LABEL, metadata.key_name());
    
    // Map key type and size
    if (metadata.algorithm() >= supacrypt::KEY_ALGORITHM_RSA_2048 &&
        metadata.algorithm() <= supacrypt::KEY_ALGORITHM_RSA_4096) {
        setAttributeULong(attributes, CKA_KEY_TYPE, CKK_RSA);
        setAttributeULong(attributes, CKA_MODULUS_BITS, 
                         metadata.algorithm() == supacrypt::KEY_ALGORITHM_RSA_2048 ? 2048 : 4096);
    } else if (metadata.algorithm() >= supacrypt::KEY_ALGORITHM_ECC_P256) {
        setAttributeULong(attributes, CKA_KEY_TYPE, CKK_EC);
        // Set EC parameters based on curve
    }
    
    // Map usage flags
    CK_BBOOL canSign = (metadata.key_usage() & supacrypt::KEY_USAGE_SIGN) ? CK_TRUE : CK_FALSE;
    CK_BBOOL canVerify = (metadata.key_usage() & supacrypt::KEY_USAGE_VERIFY) ? CK_TRUE : CK_FALSE;
    CK_BBOOL canEncrypt = (metadata.key_usage() & supacrypt::KEY_USAGE_ENCRYPT) ? CK_TRUE : CK_FALSE;
    CK_BBOOL canDecrypt = (metadata.key_usage() & supacrypt::KEY_USAGE_DECRYPT) ? CK_TRUE : CK_FALSE;
    
    setAttributeBool(attributes, CKA_SIGN, canSign);
    setAttributeBool(attributes, CKA_VERIFY, canVerify);
    setAttributeBool(attributes, CKA_ENCRYPT, canEncrypt);
    setAttributeBool(attributes, CKA_DECRYPT, canDecrypt);
    
    // Set common attributes
    setAttributeBool(attributes, CKA_TOKEN, CK_TRUE);
    setAttributeBool(attributes, CKA_PRIVATE, CK_TRUE);
    setAttributeBool(attributes, CKA_SENSITIVE, CK_TRUE);
    setAttributeBool(attributes, CKA_EXTRACTABLE, CK_FALSE);
}
```

## Implementation Steps

1. **Generate Protobuf Stubs**
   - Update CMake to run protoc
   - Generate C++ code from supacrypt.proto
   - Integrate generated files into build

2. **Implement Key Operations**
   - C_GenerateKeyPair with full attribute parsing
   - Map PKCS#11 mechanisms to backend algorithms
   - Handle RSA and ECC key generation

3. **Implement Signing/Verification**
   - Complete C_Sign with backend integration
   - Support multi-part operations
   - Implement C_Verify operations

4. **Add Encryption/Decryption**
   - C_Encrypt/C_Decrypt for RSA
   - Handle padding mechanisms
   - Support size queries

5. **Enhance Error Handling**
   - Parse detailed error responses
   - Implement circuit breaker
   - Add retry with backoff

6. **Add Observability**
   - Integrate OpenTelemetry tracing
   - Add metrics for operations
   - Include in all RPC calls

## Validation Criteria
Your implementation will be considered complete when:
1. ✅ Protobuf stubs generated and integrated into build
2. ✅ All cryptographic operations call backend successfully
3. ✅ Key generation creates objects in cache with proper attributes
4. ✅ Sign/Verify operations work with test data
5. ✅ Multi-part operations accumulate data correctly
6. ✅ Error responses properly mapped from backend
7. ✅ Circuit breaker prevents cascade failures
8. ✅ OpenTelemetry tracing integrated (if enabled)
9. ✅ Integration tests pass with real backend
10. ✅ Performance acceptable (<50ms for sign operations)

## Important Notes
- Use existing connection pool and state manager from Task 3.2
- Ensure thread safety for all operations
- Follow established error mapping patterns
- Test with both RSA and ECC keys
- Handle all PKCS#11 size query patterns

## Memory Bank Logging
Document your work in `supacrypt-common/Memory/Phase_3_PKCS11_Provider/Task_3_3_Platform_Compatibility_Log.md` following the established format. Include:
- Protobuf generation configuration
- RPC implementation decisions
- Performance measurements
- Error handling strategies
- Any backend integration challenges

Begin by setting up protobuf generation in CMake and generating the stubs.