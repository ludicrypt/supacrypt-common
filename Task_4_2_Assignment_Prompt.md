# Task Assignment: Phase 4 / Task 4.2 / Windows KSP Implementation

## Agent Role Assignment
**Assigned to:** Implementation Agent - Windows CNG Key Storage Provider Specialist

## Task Overview
Implement a Windows CNG (Cryptography Next Generation) Key Storage Provider (KSP) that delegates all cryptographic operations to the Supacrypt gRPC backend service. This KSP will enable modern Windows applications using CNG APIs to transparently use the centralized cryptographic services provided by the backend.

## Background Context
- **Phase Status:** Task 4.1 (Windows CSP) has been successfully completed with excellent performance metrics
- **Backend Service:** Fully implemented gRPC backend (supacrypt-backend-akv) is operational with mTLS authentication
- **Integration Pattern:** Follow the delegation pattern established in both PKCS#11 and CSP providers
- **Repository:** Work will be performed in the `supacrypt-ksp` directory

## Technical Requirements

### Core KSP Implementation
1. **NCrypt Provider Interface**
   - Implement all required NCrypt provider functions (GetInterface, OpenProvider, etc.)
   - Support NCRYPT_KEY_STORAGE_INTERFACE at minimum
   - Handle provider registration and discovery
   - Implement proper reference counting and cleanup

2. **Key Storage Management**
   - Support persistent and ephemeral keys
   - Implement key naming and enumeration
   - Map KSP keys to backend key identifiers
   - Support key properties and metadata
   - Handle key export/import with appropriate formats

3. **Cryptographic Operations**
   - **Key Generation:** RSA (2048, 3072, 4096), ECC (P-256, P-384, P-521)
   - **Hashing:** SHA-256, SHA-384, SHA-512
   - **Signing/Verification:** RSA (PKCS#1, PSS), ECDSA
   - **Encryption/Decryption:** RSA (PKCS#1, OAEP)
   - **Key Agreement:** ECDH
   - **Secret Agreement:** Derived key material

4. **gRPC Backend Integration**
   - Reuse protobuf definitions from `supacrypt-common/proto/supacrypt.proto`
   - Implement gRPC client with mTLS certificate authentication
   - Leverage connection pooling patterns from CSP implementation
   - Map CNG error codes to/from backend error codes
   - Implement proper timeout and retry logic

### Windows CNG Integration
1. **Provider Registration**
   - Implement NCrypt provider registration functions
   - Create MSI installer for provider deployment
   - Support both user and machine registration
   - Handle provider capability advertisement

2. **Security Context**
   - Support CNG isolation levels
   - Implement proper security descriptor handling
   - Handle key usage restrictions and ACLs
   - Support hardware security module emulation

3. **Algorithm Support**
   - Advertise supported algorithms via CNG discovery
   - Implement algorithm-specific property handlers
   - Support algorithm chaining for composite operations
   - Handle padding and parameter specifications

## Development Guidelines

### Code Structure
```
supacrypt-ksp/
├── CMakeLists.txt              # CMake build configuration
├── include/
│   ├── ksp_provider.h          # Main KSP interface
│   ├── key_storage.h           # Key storage management
│   ├── algorithm_provider.h    # Algorithm implementations
│   └── grpc_backend.h          # Backend communication
├── src/
│   ├── ksp_main.cpp           # DLL entry point
│   ├── ncrypt_provider.cpp    # NCrypt interface implementation
│   ├── key_operations.cpp     # Key management operations
│   ├── crypto_algorithms.cpp  # Algorithm implementations
│   ├── grpc_backend.cpp       # Backend client (reuse CSP patterns)
│   ├── property_handlers.cpp  # Property get/set implementations
│   └── error_handling.cpp     # CNG error mapping
├── installer/
│   ├── register_ksp.cpp       # KSP registration utility
│   ├── ksp_installer.wxs      # WiX installer definition
│   └── install.ps1            # PowerShell installation script
└── tests/
    ├── unit/                  # Unit tests
    ├── integration/           # Integration tests with backend
    ├── cng_compliance/        # CNG compliance tests
    └── performance/           # Performance benchmarks
```

### Technology Stack
- **Language:** C++ (C++17 minimum, matching CSP/PKCS#11)
- **Build System:** CMake (3.20+)
- **gRPC:** Match version used in CSP/PKCS#11 providers
- **Testing:** Google Test + Windows CNG test utilities
- **Windows SDK:** Target Windows 8+ (CNG enhanced in Windows 8)
- **Installer:** WiX Toolset for MSI generation

### Coding Standards
- Follow the established C++ coding standards from `supacrypt-common/docs/standards/cpp-coding-standards.md`
- Maintain consistency with CSP implementation patterns
- Use RAII for all NCrypt handles and resources
- Implement comprehensive logging using the project's logging standards
- Ensure thread safety for all KSP operations

## Sub-tasks Breakdown

1. **Project Setup and Structure** (Day 1)
   - Initialize CMake project with Windows CNG configurations
   - Set up NCrypt headers and import libraries
   - Create basic DLL structure with NCrypt exports
   - Implement provider registration utility

2. **NCrypt Provider Framework** (Days 2-3)
   - Implement GetInterface for key storage interface
   - Create provider open/close functionality
   - Implement reference counting and cleanup
   - Set up provider property handlers

3. **Key Storage Implementation** (Days 3-4)
   - Implement key creation and deletion
   - Add key enumeration support
   - Create key property management
   - Implement key finalization and cleanup

4. **gRPC Backend Integration** (Days 4-5)
   - Adapt CSP gRPC patterns for KSP
   - Implement CNG-specific error mapping
   - Create algorithm-specific operation handlers
   - Add connection management from shared pool

5. **Cryptographic Algorithms** (Days 6-8)
   - Implement RSA operations (sign, verify, encrypt, decrypt)
   - Add ECC operations (ECDSA, ECDH)
   - Implement hash algorithm providers
   - Add key derivation functions
   - Support algorithm chaining

6. **Windows Integration & Testing** (Days 8-10)
   - Complete provider registration
   - Test with Windows CNG applications
   - Verify with PowerShell CNG cmdlets
   - Implement MSI installer
   - Performance optimization and benchmarking

## Acceptance Criteria

1. **Functional Requirements**
   - All core NCrypt functions implemented
   - Successfully registers as Windows KSP
   - Passes Windows CNG validation tests
   - All crypto operations delegated to backend
   - Proper error handling and reporting
   - Algorithm discovery working correctly

2. **Performance Targets**
   - Provider initialization: < 100ms
   - RSA-2048 signing: < 100ms (including backend round-trip)
   - ECC P-256 signing: < 50ms
   - Key enumeration: < 200ms for 100 keys
   - Connection reuse improves performance by 35%+

3. **Quality Standards**
   - 90%+ unit test coverage
   - All CNG compliance tests passing
   - No memory leaks (verified with Application Verifier)
   - Thread-safe implementation verified
   - Clear documentation and code comments
   - Integration tests with real CNG applications

## Integration Notes

- Review both PKCS#11 (`supacrypt-pkcs11/`) and CSP (`supacrypt-csp/`) implementations for patterns
- Ensure error handling consistency across all providers
- Coordinate with CSP implementation for shared Windows infrastructure
- Consider future integration testing between CSP and KSP providers
- Leverage CSP's gRPC client patterns for connection management

## Deliverables

1. Complete KSP implementation in `supacrypt-ksp/`
2. Comprehensive test suite with 90%+ coverage
3. KSP registration utility and MSI installer
4. PowerShell installation and management scripts
5. Integration documentation for CNG applications
6. Performance benchmark results comparing to CSP
7. Memory Bank log entry upon completion

## Resources

- [Microsoft CNG Development Documentation](https://docs.microsoft.com/en-us/windows/win32/seccng/cng-portal)
- [NCrypt API Reference](https://docs.microsoft.com/en-us/windows/win32/api/ncrypt/)
- Existing CSP implementation in `supacrypt-csp/` for patterns
- Protobuf definitions in `supacrypt-common/proto/`
- Backend service API documentation

## Critical Guidance

- **DO NOT** implement any actual cryptographic algorithms - all operations must be delegated to the backend
- **ENSURE** compatibility with modern Windows applications using CNG
- **FOLLOW** the established patterns from CSP and PKCS#11 providers for consistency
- **TEST** thoroughly with CNG-based applications (e.g., IIS with ECC certificates, PowerShell)
- **MAINTAIN** clear separation between NCrypt interface and backend communication
- **CONSIDER** performance implications of CNG's more complex API compared to CSP

Upon completion of this task, log your work to the Memory Bank following the format specified in `supacrypt-common/prompts/02_Utility_Prompts_And_Format_Definitions/Memory_Bank_Log_Format.md` and report completion status to the User.

---

*Note: This task is part of Phase 4 (Windows Native Providers) of the Supacrypt project. Successful completion will enable modern Windows applications using CNG to leverage the Supacrypt cryptographic backend, complementing the legacy support provided by the CSP implementation.*