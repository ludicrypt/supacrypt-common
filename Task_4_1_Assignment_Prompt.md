# Task Assignment: Phase 4 / Task 4.1 / Windows CSP Implementation

## Agent Role Assignment
**Assigned to:** Implementation Agent - Windows Cryptographic Service Provider Specialist

## Task Overview
Implement a Windows CAPI Cryptographic Service Provider (CSP) that delegates all cryptographic operations to the Supacrypt gRPC backend service. This CSP will enable legacy Windows applications and APIs to transparently use the centralized cryptographic services provided by the backend.

## Background Context
- **Phase Status:** Phase 3 (PKCS#11 Provider) has been successfully completed with full compliance and excellent performance metrics
- **Backend Service:** Fully implemented gRPC backend (supacrypt-backend-akv) is operational with mTLS authentication
- **Integration Pattern:** Follow the delegation pattern established in the PKCS#11 provider - all crypto operations forwarded to backend
- **Repository:** Work will be performed in the `supacrypt-csp` directory

## Technical Requirements

### Core CSP Implementation
1. **CSP Entry Points**
   - Implement all required CSP DLL exports (CPAcquireContext, CPReleaseContext, etc.)
   - Support CSP type PROV_RSA_FULL at minimum
   - Handle CSP versioning (support v2.0 minimum)
   - Implement proper DLL main entry point with process/thread attach handling

2. **Key Container Management**
   - Implement named key container support (machine and user stores)
   - Map CSP key containers to backend key identifiers
   - Support both volatile (session) and persistent keys
   - Handle key container enumeration

3. **Cryptographic Operations**
   - **Key Generation:** RSA key pair generation (1024, 2048, 4096 bits)
   - **Hashing:** SHA-1, SHA-256, SHA-384, SHA-512
   - **Signing/Verification:** RSA PKCS#1 v1.5 and PSS
   - **Encryption/Decryption:** RSA PKCS#1 v1.5 and OAEP
   - **Key Import/Export:** PUBLICKEYBLOB, PRIVATEKEYBLOB formats

4. **gRPC Backend Integration**
   - Reuse protobuf definitions from `supacrypt-common/proto/supacrypt.proto`
   - Implement gRPC client with mTLS certificate authentication
   - Handle connection pooling and resilience (circuit breaker pattern)
   - Map Windows crypto errors to/from backend error codes
   - Implement proper timeout and retry logic

### Windows Integration Requirements
1. **Error Handling**
   - Use SetLastError() with appropriate Windows crypto error codes
   - Map backend errors to meaningful Windows error codes
   - Support GetLastError() patterns expected by Windows APIs

2. **Registry Integration**
   - Create proper CSP registry entries for installation
   - Support both 32-bit and 64-bit registry views
   - Implement CSP type and algorithm capability entries

3. **Security Considerations**
   - Handle sensitive data in secure memory where appropriate
   - Clear key material from memory after use
   - Support Windows CryptoAPI key usage flags and permissions
   - Implement proper access control for machine vs user keys

## Development Guidelines

### Code Structure
```
supacrypt-csp/
├── CMakeLists.txt              # CMake build configuration
├── include/
│   ├── csp_provider.h          # Main CSP interface
│   ├── key_container.h         # Key container management
│   └── grpc_client.h           # Backend communication
├── src/
│   ├── csp_main.cpp           # DLL entry point and exports
│   ├── csp_provider.cpp       # Core CSP implementation
│   ├── key_container.cpp      # Key storage/retrieval
│   ├── crypto_operations.cpp  # Crypto function implementations
│   ├── grpc_client.cpp        # Backend client with pooling
│   └── error_handling.cpp     # Error mapping utilities
├── installer/
│   ├── register_csp.cpp       # CSP registration utility
│   └── install.bat            # Installation script
└── tests/
    ├── unit/                  # Unit tests
    ├── integration/           # Integration tests with backend
    └── compatibility/         # Windows API compatibility tests
```

### Technology Stack
- **Language:** C++ (C++17 minimum for consistency with PKCS#11)
- **Build System:** CMake (3.20+)
- **gRPC:** Match version used in PKCS#11 provider
- **Testing:** Google Test + Windows-specific test utilities
- **Windows SDK:** Target Windows 7+ (Windows SDK 10.0.19041.0 or later)

### Coding Standards
- Follow the established C++ coding standards from `supacrypt-common/docs/standards/cpp-coding-standards.md`
- Use consistent error handling patterns from the PKCS#11 implementation
- Implement comprehensive logging using the project's logging standards
- Ensure thread safety for all CSP operations

## Sub-tasks Breakdown

1. **Project Setup and Structure** (Day 1)
   - Initialize CMake project with Windows-specific configurations
   - Set up gRPC and protobuf integration
   - Create basic DLL structure with exports
   - Implement CSP registration utility

2. **Core CSP Framework** (Days 2-3)
   - Implement CPAcquireContext/CPReleaseContext
   - Create key container management infrastructure
   - Implement basic CSP property functions
   - Set up provider handle and context management

3. **gRPC Client Integration** (Days 3-4)
   - Port gRPC client patterns from PKCS#11 provider
   - Implement connection pooling and circuit breaker
   - Create error mapping between gRPC and Windows errors
   - Add mTLS certificate loading for Windows

4. **Cryptographic Operations** (Days 5-7)
   - Implement key generation with backend delegation
   - Add hashing operations (create hash, hash data, get value)
   - Implement signing and verification
   - Add encryption and decryption support
   - Implement key import/export functions

5. **Windows Integration** (Days 8-9)
   - Complete registry integration for CSP registration
   - Test with Windows Certificate Manager (certmgr.msc)
   - Verify with common Windows crypto APIs
   - Implement any missing CSP capabilities

6. **Testing and Validation** (Days 9-10)
   - Unit tests for all CSP functions
   - Integration tests with mock backend
   - Real backend integration tests
   - Windows API compatibility testing
   - Performance benchmarking

## Acceptance Criteria

1. **Functional Requirements**
   - All core CSP functions implemented and working
   - Successfully registers with Windows CryptoAPI
   - Passes Windows CSP validation tests
   - All crypto operations delegated to backend
   - Proper error handling and reporting

2. **Performance Targets**
   - CSP initialization: < 100ms
   - RSA-2048 signing: < 100ms (including backend round-trip)
   - Key generation: < 3s
   - Connection pooling reduces latency for repeated operations

3. **Quality Standards**
   - 90%+ unit test coverage
   - All integration tests passing
   - No memory leaks (verified with Windows debugging tools)
   - Thread-safe implementation
   - Clear documentation and code comments

## Integration Notes

- Review the PKCS#11 implementation in `supacrypt-pkcs11/` for patterns to follow
- Ensure consistency with error handling approaches across providers
- Coordinate with the backend service for any CSP-specific requirements
- Consider future integration with the KSP provider (Task 4.2)

## Deliverables

1. Complete CSP implementation in `supacrypt-csp/`
2. Comprehensive test suite with 90%+ coverage
3. CSP registration utility and installation scripts
4. Integration documentation for Windows applications
5. Performance benchmark results
6. Memory Bank log entry upon completion

## Resources

- [Microsoft CSP Development Documentation](https://docs.microsoft.com/en-us/windows/win32/seccrypto/cryptographic-service-providers)
- Existing protobuf definitions in `supacrypt-common/proto/`
- PKCS#11 provider implementation for reference patterns
- Backend service API documentation

## Critical Guidance

- **DO NOT** implement any actual cryptographic algorithms - all operations must be delegated to the backend
- **ENSURE** backward compatibility with legacy Windows applications
- **FOLLOW** the established patterns from the PKCS#11 provider for consistency
- **TEST** thoroughly with real Windows applications (e.g., IIS, Certificate Manager)
- **MAINTAIN** clear separation between CSP interface and backend communication layers

Upon completion of this task, log your work to the Memory Bank following the format specified in `supacrypt-common/prompts/02_Utility_Prompts_And_Format_Definitions/Memory_Bank_Log_Format.md` and report completion status to the User.

---

*Note: This task is part of Phase 4 (Windows Native Providers) of the Supacrypt project. Successful completion will enable legacy Windows applications to use the Supacrypt cryptographic backend transparently.*