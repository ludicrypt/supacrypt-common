# Task Assignment: Cross-Platform Testing Framework

## Agent Profile
**Type:** Implementation Agent - QA Specialist  
**Expertise Required:** C++ Testing, PKCS#11 Specification, Cross-Platform Development, Test Automation, Performance Testing

## Task Overview
Develop a comprehensive cross-platform test suite for the supacrypt-pkcs11 provider that validates functionality, conformance, performance, and security across Windows, Linux, and macOS platforms. Achieve minimum 80% code coverage with 95% coverage for critical cryptographic paths.

## Context
- **Repository:** `supacrypt-pkcs11`
- **Current State:** Fully implemented PKCS#11 provider with gRPC backend integration
- **Target:** Production-ready test suite with automated CI/CD validation
- **Platforms:** Windows, Linux, macOS (x64 and ARM64)

## Detailed Requirements

### 1. Unit Test Implementation

#### Core Component Tests
```cpp
// tests/unit/test_state_manager.cpp
#include <gtest/gtest.h>
#include <gmock/gmock.h>
#include "state_manager.h"
#include <thread>
#include <vector>

class StateManagerTest : public ::testing::Test {
protected:
    void SetUp() override {
        // Ensure clean state
        StateManager::getInstance().finalize();
    }
    
    void TearDown() override {
        StateManager::getInstance().finalize();
    }
};

TEST_F(StateManagerTest, SingletonBehavior) {
    auto& instance1 = StateManager::getInstance();
    auto& instance2 = StateManager::getInstance();
    EXPECT_EQ(&instance1, &instance2);
}

TEST_F(StateManagerTest, InitializeOnce) {
    EXPECT_EQ(CKR_OK, StateManager::getInstance().initialize(nullptr));
    EXPECT_EQ(CKR_CRYPTOKI_ALREADY_INITIALIZED, 
              StateManager::getInstance().initialize(nullptr));
}

TEST_F(StateManagerTest, ThreadSafeInitialization) {
    const int numThreads = 10;
    std::vector<std::thread> threads;
    std::atomic<int> successCount{0};
    std::atomic<int> alreadyInitCount{0};
    
    for (int i = 0; i < numThreads; ++i) {
        threads.emplace_back([&]() {
            CK_RV rv = StateManager::getInstance().initialize(nullptr);
            if (rv == CKR_OK) {
                successCount++;
            } else if (rv == CKR_CRYPTOKI_ALREADY_INITIALIZED) {
                alreadyInitCount++;
            }
        });
    }
    
    for (auto& t : threads) {
        t.join();
    }
    
    EXPECT_EQ(1, successCount);
    EXPECT_EQ(numThreads - 1, alreadyInitCount);
}

TEST_F(StateManagerTest, SessionManagement) {
    ASSERT_EQ(CKR_OK, StateManager::getInstance().initialize(nullptr));
    
    CK_SESSION_HANDLE session1, session2;
    EXPECT_EQ(CKR_OK, StateManager::getInstance().createSession(
        CKF_SERIAL_SESSION | CKF_RW_SESSION, &session1));
    EXPECT_EQ(CKR_OK, StateManager::getInstance().createSession(
        CKF_SERIAL_SESSION, &session2));
    
    EXPECT_NE(session1, session2);
    
    SessionState* state1 = nullptr;
    EXPECT_EQ(CKR_OK, StateManager::getInstance().getSession(session1, &state1));
    EXPECT_NE(nullptr, state1);
    
    EXPECT_EQ(CKR_OK, StateManager::getInstance().removeSession(session1));
    EXPECT_EQ(CKR_SESSION_HANDLE_INVALID, 
              StateManager::getInstance().getSession(session1, &state1));
}
```

#### Session State Tests
```cpp
// tests/unit/test_session_state.cpp
TEST(SessionStateTest, OperationLifecycle) {
    SessionState session(1, CKF_SERIAL_SESSION);
    
    CK_MECHANISM mech = {CKM_RSA_PKCS, nullptr, 0};
    EXPECT_EQ(CKR_OK, session.beginOperation(
        OperationType::Sign, &mech, "test-key-id"));
    
    // Cannot start another operation
    EXPECT_EQ(CKR_OPERATION_ACTIVE, session.beginOperation(
        OperationType::Verify, &mech, "another-key"));
    
    // Update operation
    std::vector<uint8_t> data = {1, 2, 3, 4, 5};
    EXPECT_EQ(CKR_OK, session.updateOperation(data.data(), data.size()));
    
    const auto& context = session.getOperationContext();
    EXPECT_EQ(OperationType::Sign, context.type);
    EXPECT_EQ("test-key-id", context.keyId);
    EXPECT_EQ(data, context.accumulatedData);
    
    session.cancelOperation();
    EXPECT_EQ(OperationType::None, session.getOperationContext().type);
}

TEST(SessionStateTest, ThreadSafety) {
    SessionState session(1, CKF_SERIAL_SESSION);
    const int numThreads = 100;
    std::vector<std::thread> threads;
    
    // Concurrent reads should be safe
    for (int i = 0; i < numThreads; ++i) {
        threads.emplace_back([&session]() {
            for (int j = 0; j < 1000; ++j) {
                auto state = session.getState();
                auto flags = session.getFlags();
                auto context = session.getOperationContext();
                EXPECT_NE(0, flags);
            }
        });
    }
    
    for (auto& t : threads) {
        t.join();
    }
}
```

#### Mock gRPC Backend
```cpp
// tests/unit/mock_grpc_backend.h
class MockSupacryptStub : public supacrypt::v1::SupacryptService::StubInterface {
public:
    MOCK_METHOD(grpc::Status, GenerateKey,
        (grpc::ClientContext*, const supacrypt::v1::GenerateKeyRequest&,
         supacrypt::v1::GenerateKeyResponse*), (override));
         
    MOCK_METHOD(grpc::Status, SignData,
        (grpc::ClientContext*, const supacrypt::v1::SignDataRequest&,
         supacrypt::v1::SignDataResponse*), (override));
         
    MOCK_METHOD(grpc::Status, VerifySignature,
        (grpc::ClientContext*, const supacrypt::v1::VerifySignatureRequest&,
         supacrypt::v1::VerifySignatureResponse*), (override));
    
    // ... other RPC methods
};

// tests/unit/test_crypto_operations.cpp
TEST(CryptoOperationsTest, GenerateKeyPairSuccess) {
    // Setup mock
    auto mockStub = std::make_unique<MockSupacryptStub>();
    
    EXPECT_CALL(*mockStub, GenerateKey(_, _, _))
        .WillOnce([](auto*, const auto& request, auto* response) {
            // Validate request
            EXPECT_EQ(supacrypt::v1::KeyAlgorithm::KEY_ALGORITHM_RSA, 
                     request.algorithm());
            EXPECT_EQ(supacrypt::v1::RSAKeySize::RSA_KEY_SIZE_2048,
                     request.parameters().rsa_params().key_size());
            
            // Build response
            auto* success = response->mutable_success();
            auto* metadata = success->mutable_metadata();
            metadata->set_key_id("test-key-12345");
            metadata->set_key_name(request.name());
            metadata->set_algorithm(request.algorithm());
            
            return grpc::Status::OK;
        });
    
    // Test key generation
    CK_MECHANISM mech = {CKM_RSA_PKCS_KEY_PAIR_GEN, nullptr, 0};
    CK_ULONG modulusBits = 2048;
    CK_ATTRIBUTE pubTemplate[] = {
        {CKA_MODULUS_BITS, &modulusBits, sizeof(modulusBits)}
    };
    CK_ATTRIBUTE privTemplate[] = {
        {CKA_SIGN, &ckTrue, sizeof(ckTrue)}
    };
    
    CK_OBJECT_HANDLE hPub, hPriv;
    CK_RV rv = C_GenerateKeyPair(hSession, &mech,
        pubTemplate, 1, privTemplate, 1, &hPub, &hPriv);
    
    EXPECT_EQ(CKR_OK, rv);
    EXPECT_NE(0, hPub);
    EXPECT_NE(0, hPriv);
    EXPECT_NE(hPub, hPriv);
}
```

### 2. Integration Test Suite

#### Test Backend Setup
```cpp
// tests/integration/test_backend_fixture.h
class TestBackendFixture : public ::testing::Test {
protected:
    static void SetUpTestSuite() {
        // Start test backend container
        system("docker run -d --name supacrypt-test-backend "
               "-p 5001:5000 "
               "-e ASPNETCORE_ENVIRONMENT=Development "
               "-e Security__Mtls__Enabled=false "
               "supacrypt/backend:test");
        
        // Wait for backend to be ready
        std::this_thread::sleep_for(std::chrono::seconds(5));
    }
    
    static void TearDownTestSuite() {
        system("docker stop supacrypt-test-backend");
        system("docker rm supacrypt-test-backend");
    }
    
    void SetUp() override {
        // Configure PKCS#11 to use test backend
        supacrypt_config_t config = {0};
        strncpy(config.backend_endpoint, "localhost:5001", 
                sizeof(config.backend_endpoint));
        config.use_tls = false;
        
        ASSERT_EQ(CKR_OK, SC_Configure(&config));
        ASSERT_EQ(CKR_OK, C_Initialize(nullptr));
    }
    
    void TearDown() override {
        C_Finalize(nullptr);
    }
};
```

#### End-to-End Operation Tests
```cpp
// tests/integration/test_e2e_operations.cpp
TEST_F(TestBackendFixture, GenerateSignVerifyFlow) {
    // Open session
    CK_SESSION_HANDLE hSession;
    ASSERT_EQ(CKR_OK, C_OpenSession(1, CKF_SERIAL_SESSION, 
                                   nullptr, nullptr, &hSession));
    
    // Generate RSA key pair
    CK_MECHANISM keyGenMech = {CKM_RSA_PKCS_KEY_PAIR_GEN, nullptr, 0};
    CK_OBJECT_HANDLE hPublicKey, hPrivateKey;
    
    CK_ULONG modulusBits = 2048;
    CK_UTF8CHAR label[] = "Test RSA Key";
    CK_BBOOL ckTrue = CK_TRUE;
    
    CK_ATTRIBUTE publicKeyTemplate[] = {
        {CKA_MODULUS_BITS, &modulusBits, sizeof(modulusBits)},
        {CKA_LABEL, label, sizeof(label) - 1},
        {CKA_VERIFY, &ckTrue, sizeof(ckTrue)}
    };
    
    CK_ATTRIBUTE privateKeyTemplate[] = {
        {CKA_LABEL, label, sizeof(label) - 1},
        {CKA_SIGN, &ckTrue, sizeof(ckTrue)}
    };
    
    ASSERT_EQ(CKR_OK, C_GenerateKeyPair(hSession, &keyGenMech,
        publicKeyTemplate, 3, privateKeyTemplate, 2,
        &hPublicKey, &hPrivateKey));
    
    // Sign data
    CK_MECHANISM signMech = {CKM_RSA_PKCS, nullptr, 0};
    ASSERT_EQ(CKR_OK, C_SignInit(hSession, &signMech, hPrivateKey));
    
    CK_BYTE data[] = "Hello, PKCS#11!";
    CK_BYTE signature[256];
    CK_ULONG signatureLen = sizeof(signature);
    
    ASSERT_EQ(CKR_OK, C_Sign(hSession, data, sizeof(data) - 1, 
                            signature, &signatureLen));
    
    // Verify signature
    ASSERT_EQ(CKR_OK, C_VerifyInit(hSession, &signMech, hPublicKey));
    ASSERT_EQ(CKR_OK, C_Verify(hSession, data, sizeof(data) - 1,
                              signature, signatureLen));
    
    // Verify with wrong data should fail
    CK_BYTE wrongData[] = "Wrong data";
    ASSERT_EQ(CKR_OK, C_VerifyInit(hSession, &signMech, hPublicKey));
    ASSERT_EQ(CKR_SIGNATURE_INVALID, C_Verify(hSession, wrongData, 
                                              sizeof(wrongData) - 1,
                                              signature, signatureLen));
    
    C_CloseSession(hSession);
}

TEST_F(TestBackendFixture, MultiPartSignature) {
    // ... setup session and keys ...
    
    CK_MECHANISM signMech = {CKM_RSA_PKCS, nullptr, 0};
    ASSERT_EQ(CKR_OK, C_SignInit(hSession, &signMech, hPrivateKey));
    
    // Sign in multiple parts
    CK_BYTE part1[] = "First part ";
    CK_BYTE part2[] = "Second part ";
    CK_BYTE part3[] = "Third part";
    
    ASSERT_EQ(CKR_OK, C_SignUpdate(hSession, part1, sizeof(part1) - 1));
    ASSERT_EQ(CKR_OK, C_SignUpdate(hSession, part2, sizeof(part2) - 1));
    ASSERT_EQ(CKR_OK, C_SignUpdate(hSession, part3, sizeof(part3) - 1));
    
    CK_BYTE signature[256];
    CK_ULONG signatureLen = sizeof(signature);
    ASSERT_EQ(CKR_OK, C_SignFinal(hSession, signature, &signatureLen));
    
    // Verify the multi-part signature
    CK_BYTE fullData[] = "First part Second part Third part";
    ASSERT_EQ(CKR_OK, C_VerifyInit(hSession, &signMech, hPublicKey));
    ASSERT_EQ(CKR_OK, C_Verify(hSession, fullData, sizeof(fullData) - 1,
                              signature, signatureLen));
}
```

### 3. PKCS#11 Conformance Tests

#### Google pkcs11test Integration
```cmake
# tests/conformance/CMakeLists.txt
if(BUILD_CONFORMANCE_TESTS)
    FetchContent_Declare(
        pkcs11test
        GIT_REPOSITORY https://github.com/google/pkcs11test.git
        GIT_TAG main
    )
    FetchContent_MakeAvailable(pkcs11test)
    
    add_executable(supacrypt-conformance
        conformance_runner.cpp
    )
    
    target_link_libraries(supacrypt-conformance
        PRIVATE
            supacrypt::pkcs11
            pkcs11test
            GTest::gtest_main
    )
endif()
```

#### Custom Conformance Tests
```cpp
// tests/conformance/test_oasis_profiles.cpp
class OasisConformanceTest : public ::testing::Test {
protected:
    void SetUp() override {
        // Load PKCS#11 library dynamically
        module_ = dlopen("libsupacrypt-pkcs11.so", RTLD_NOW);
        ASSERT_NE(nullptr, module_);
        
        CK_C_GetFunctionList getFunctionList = 
            (CK_C_GetFunctionList)dlsym(module_, "C_GetFunctionList");
        ASSERT_NE(nullptr, getFunctionList);
        
        ASSERT_EQ(CKR_OK, getFunctionList(&p11_));
        ASSERT_NE(nullptr, p11_);
        
        ASSERT_EQ(CKR_OK, p11_->C_Initialize(nullptr));
    }
    
    void TearDown() override {
        if (p11_) {
            p11_->C_Finalize(nullptr);
        }
        if (module_) {
            dlclose(module_);
        }
    }
    
    void* module_ = nullptr;
    CK_FUNCTION_LIST_PTR p11_ = nullptr;
};

TEST_F(OasisConformanceTest, BaselineProviderProfile) {
    // Test OASIS PKCS#11 Profiles - Baseline Provider
    
    // 1. Version compatibility
    CK_INFO info;
    ASSERT_EQ(CKR_OK, p11_->C_GetInfo(&info));
    EXPECT_GE(info.cryptokiVersion.major, 2);
    EXPECT_GE(info.cryptokiVersion.minor, 40);
    
    // 2. Slot and token presence
    CK_ULONG slotCount;
    ASSERT_EQ(CKR_OK, p11_->C_GetSlotList(CK_TRUE, nullptr, &slotCount));
    EXPECT_GE(slotCount, 1);
    
    // 3. Required mechanisms
    CK_MECHANISM_TYPE requiredMechs[] = {
        CKM_RSA_PKCS,
        CKM_RSA_PKCS_KEY_PAIR_GEN,
        CKM_SHA256,
        CKM_SHA256_RSA_PKCS
    };
    
    CK_MECHANISM_INFO mechInfo;
    for (auto mech : requiredMechs) {
        EXPECT_EQ(CKR_OK, p11_->C_GetMechanismInfo(1, mech, &mechInfo))
            << "Missing required mechanism: " << mech;
    }
}
```

### 4. Platform-Specific Tests

#### Windows Tests
```cpp
// tests/platform/test_windows.cpp
#ifdef _WIN32
TEST(WindowsPlatformTest, DllExports) {
    HMODULE hModule = LoadLibraryA("supacrypt-pkcs11.dll");
    ASSERT_NE(nullptr, hModule);
    
    // Check standard exports
    EXPECT_NE(nullptr, GetProcAddress(hModule, "C_GetFunctionList"));
    EXPECT_NE(nullptr, GetProcAddress(hModule, "C_Initialize"));
    
    // Check Supacrypt extensions
    EXPECT_NE(nullptr, GetProcAddress(hModule, "SC_Configure"));
    EXPECT_NE(nullptr, GetProcAddress(hModule, "SC_GetErrorString"));
    
    FreeLibrary(hModule);
}

TEST(WindowsPlatformTest, CertificateStoreIntegration) {
    // Test loading certificates from Windows certificate store
    HCERTSTORE hStore = CertOpenSystemStore(0, "MY");
    ASSERT_NE(nullptr, hStore);
    
    // ... test certificate loading ...
    
    CertCloseStore(hStore, 0);
}
#endif
```

#### Linux Tests
```cpp
// tests/platform/test_linux.cpp
#ifdef __linux__
TEST(LinuxPlatformTest, SymbolVisibility) {
    void* handle = dlopen("./libsupacrypt-pkcs11.so", RTLD_NOW);
    ASSERT_NE(nullptr, handle);
    
    // Check that internal symbols are not exposed
    EXPECT_EQ(nullptr, dlsym(handle, "_ZN8supacrypt6pkcs1112StateManagerC1Ev"))
        << "Internal symbols should not be visible";
    
    dlclose(handle);
}

TEST(LinuxPlatformTest, P11KitIntegration) {
    // Test p11-kit module configuration
    std::ofstream config("/etc/pkcs11/modules/supacrypt.module");
    config << "module: " << CMAKE_INSTALL_PREFIX << "/lib/libsupacrypt-pkcs11.so\n";
    config.close();
    
    // Verify p11-kit can load the module
    system("p11-kit list-modules | grep supacrypt");
}
#endif
```

#### macOS Tests
```cpp
// tests/platform/test_macos.cpp
#ifdef __APPLE__
TEST(MacOSPlatformTest, UniversalBinary) {
    // Verify universal binary support
    FILE* pipe = popen("lipo -info libsupacrypt-pkcs11.dylib", "r");
    ASSERT_NE(nullptr, pipe);
    
    char buffer[256];
    fgets(buffer, sizeof(buffer), pipe);
    
    EXPECT_NE(nullptr, strstr(buffer, "x86_64"));
    EXPECT_NE(nullptr, strstr(buffer, "arm64"));
    
    pclose(pipe);
}

TEST(MacOSPlatformTest, KeychainIntegration) {
    // Test macOS Keychain certificate loading
    SecKeychainRef keychain;
    OSStatus status = SecKeychainCopyDefault(&keychain);
    ASSERT_EQ(errSecSuccess, status);
    
    // ... test certificate operations ...
    
    CFRelease(keychain);
}
#endif
```

### 5. Performance Benchmarks

#### Benchmark Suite
```cpp
// tests/benchmarks/pkcs11_benchmarks.cpp
#include <benchmark/benchmark.h>

class PKCS11Benchmark : public benchmark::Fixture {
public:
    void SetUp(const ::benchmark::State& state) override {
        C_Initialize(nullptr);
        C_OpenSession(1, CKF_SERIAL_SESSION, nullptr, nullptr, &hSession_);
        
        // Pre-generate test keys
        generateTestKeys();
    }
    
    void TearDown(const ::benchmark::State& state) override {
        C_CloseSession(hSession_);
        C_Finalize(nullptr);
    }
    
protected:
    CK_SESSION_HANDLE hSession_;
    CK_OBJECT_HANDLE hRSA2048Pub_, hRSA2048Priv_;
    CK_OBJECT_HANDLE hECCP256Pub_, hECCP256Priv_;
};

BENCHMARK_F(PKCS11Benchmark, BM_RSA2048_Sign)(benchmark::State& state) {
    CK_MECHANISM mech = {CKM_RSA_PKCS, nullptr, 0};
    CK_BYTE data[32];
    CK_BYTE signature[256];
    CK_ULONG sigLen;
    
    // Fill with random data
    RAND_bytes(data, sizeof(data));
    
    for (auto _ : state) {
        C_SignInit(hSession_, &mech, hRSA2048Priv_);
        sigLen = sizeof(signature);
        C_Sign(hSession_, data, sizeof(data), signature, &sigLen);
    }
    
    state.SetItemsProcessed(state.iterations());
}

BENCHMARK_F(PKCS11Benchmark, BM_RSA2048_Verify)(benchmark::State& state) {
    // Pre-sign data
    CK_MECHANISM mech = {CKM_RSA_PKCS, nullptr, 0};
    CK_BYTE data[32];
    CK_BYTE signature[256];
    CK_ULONG sigLen = sizeof(signature);
    
    RAND_bytes(data, sizeof(data));
    C_SignInit(hSession_, &mech, hRSA2048Priv_);
    C_Sign(hSession_, data, sizeof(data), signature, &sigLen);
    
    for (auto _ : state) {
        C_VerifyInit(hSession_, &mech, hRSA2048Pub_);
        C_Verify(hSession_, data, sizeof(data), signature, sigLen);
    }
    
    state.SetItemsProcessed(state.iterations());
}

BENCHMARK_F(PKCS11Benchmark, BM_GenerateKeyPair_RSA2048)(benchmark::State& state) {
    CK_MECHANISM mech = {CKM_RSA_PKCS_KEY_PAIR_GEN, nullptr, 0};
    CK_ULONG modulusBits = 2048;
    CK_ATTRIBUTE pubTemplate[] = {
        {CKA_MODULUS_BITS, &modulusBits, sizeof(modulusBits)}
    };
    
    for (auto _ : state) {
        CK_OBJECT_HANDLE hPub, hPriv;
        C_GenerateKeyPair(hSession_, &mech, pubTemplate, 1, 
                         nullptr, 0, &hPub, &hPriv);
        
        // Clean up keys
        C_DestroyObject(hSession_, hPub);
        C_DestroyObject(hSession_, hPriv);
    }
}

// Register benchmarks with custom settings
BENCHMARK_REGISTER_F(PKCS11Benchmark, BM_RSA2048_Sign)
    ->Unit(benchmark::kMicrosecond)
    ->Iterations(1000);
    
BENCHMARK_REGISTER_F(PKCS11Benchmark, BM_RSA2048_Verify)
    ->Unit(benchmark::kMicrosecond)
    ->Iterations(1000);
    
BENCHMARK_REGISTER_F(PKCS11Benchmark, BM_GenerateKeyPair_RSA2048)
    ->Unit(benchmark::kMillisecond)
    ->Iterations(10);
```

### 6. Security Testing

#### Fuzzing Tests
```cpp
// tests/fuzzing/fuzz_pkcs11.cpp
extern "C" int LLVMFuzzerTestOneInput(const uint8_t* data, size_t size) {
    static bool initialized = false;
    static CK_SESSION_HANDLE hSession;
    
    if (!initialized) {
        C_Initialize(nullptr);
        C_OpenSession(1, CKF_SERIAL_SESSION, nullptr, nullptr, &hSession);
        initialized = true;
    }
    
    if (size < 4) return 0;
    
    // Use first 4 bytes to determine operation
    uint32_t op = *(uint32_t*)data;
    data += 4;
    size -= 4;
    
    switch (op % 5) {
        case 0: // Fuzz C_Sign
            if (size > 0) {
                CK_BYTE sig[512];
                CK_ULONG sigLen = sizeof(sig);
                C_Sign(hSession, (CK_BYTE_PTR)data, size, sig, &sigLen);
            }
            break;
            
        case 1: // Fuzz C_Verify
            if (size > 32) {
                C_Verify(hSession, (CK_BYTE_PTR)data, 32, 
                        (CK_BYTE_PTR)(data + 32), size - 32);
            }
            break;
            
        case 2: // Fuzz attribute parsing
            C_GetAttributeValue(hSession, 1, (CK_ATTRIBUTE_PTR)data, 
                               size / sizeof(CK_ATTRIBUTE));
            break;
            
        // ... more fuzzing targets
    }
    
    return 0;
}
```

### 7. Test Coverage Configuration

#### CMake Coverage Setup
```cmake
# cmake/CodeCoverage.cmake
if(ENABLE_COVERAGE)
    find_program(GCOV gcov)
    find_program(LCOV lcov)
    find_program(GENHTML genhtml)
    
    if(NOT GCOV OR NOT LCOV OR NOT GENHTML)
        message(FATAL_ERROR "Coverage tools not found")
    endif()
    
    # Add coverage flags
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} --coverage")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} --coverage")
    
    # Create coverage target
    add_custom_target(coverage
        COMMAND ${LCOV} --directory . --zerocounters
        COMMAND ${CMAKE_CTEST_COMMAND} --output-on-failure
        COMMAND ${LCOV} --directory . --capture --output-file coverage.info
        COMMAND ${LCOV} --remove coverage.info '/usr/*' '*/tests/*' --output-file coverage.filtered.info
        COMMAND ${GENHTML} coverage.filtered.info --output-directory coverage-report
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    )
endif()
```

### 8. CI/CD Test Integration

#### Updated GitHub Actions
```yaml
# .github/workflows/test.yml
name: Test Suite

on: [push, pull_request]

jobs:
  unit-tests:
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        
    runs-on: ${{ matrix.os }}
    
    steps:
    - uses: actions/checkout@v4
      with:
        submodules: recursive
    
    - name: Install dependencies
      run: |
        if [ "$RUNNER_OS" == "Linux" ]; then
          sudo apt-get update
          sudo apt-get install -y libssl-dev lcov
        elif [ "$RUNNER_OS" == "macOS" ]; then
          brew install openssl lcov
        fi
      shell: bash
    
    - name: Configure
      run: |
        cmake -B build \
          -DCMAKE_BUILD_TYPE=Debug \
          -DBUILD_TESTING=ON \
          -DENABLE_COVERAGE=ON \
          -DENABLE_SANITIZERS=ON
    
    - name: Build
      run: cmake --build build --parallel
    
    - name: Run Unit Tests
      run: |
        cd build
        ctest --output-on-failure -R "unit"
    
    - name: Run Coverage
      if: runner.os == 'Linux'
      run: |
        cd build
        make coverage
    
    - name: Upload Coverage
      if: runner.os == 'Linux'
      uses: codecov/codecov-action@v3
      with:
        file: ./build/coverage.filtered.info
  
  integration-tests:
    runs-on: ubuntu-latest
    services:
      backend:
        image: supacrypt/backend:latest
        ports:
          - 5001:5000
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Configure
      run: cmake -B build -DBUILD_TESTING=ON
    
    - name: Build
      run: cmake --build build
    
    - name: Run Integration Tests
      run: |
        cd build
        ctest --output-on-failure -R "integration"
  
  conformance-tests:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Build
      run: |
        cmake -B build -DBUILD_CONFORMANCE_TESTS=ON
        cmake --build build
    
    - name: Run Conformance Tests
      run: |
        cd build/tests/conformance
        ./supacrypt-conformance
```

## Implementation Steps

1. **Setup Test Infrastructure**
   - Configure Google Test and Google Benchmark
   - Create test fixtures and utilities
   - Set up mock gRPC backend

2. **Implement Unit Tests**
   - Test each component in isolation
   - Achieve 95% coverage for crypto paths
   - Validate thread safety

3. **Create Integration Tests**
   - Docker-based test backend
   - End-to-end operation flows
   - Error scenario testing

4. **Add Conformance Tests**
   - Integrate pkcs11test
   - Implement OASIS profile tests
   - Validate all mechanisms

5. **Platform-Specific Testing**
   - Symbol export verification
   - Dynamic loading tests
   - Platform integration

6. **Performance Benchmarks**
   - Operation latency tests
   - Throughput measurements
   - Memory usage profiling

7. **Security Testing**
   - Fuzzing setup
   - Vulnerability scanning
   - Memory safety validation

## Validation Criteria
Your implementation will be considered complete when:
1. ✅ Unit tests achieve >80% code coverage (95% for crypto)
2. ✅ All integration tests pass with real backend
3. ✅ PKCS#11 conformance tests pass
4. ✅ Platform-specific tests pass on all OS
5. ✅ Performance benchmarks meet targets (<50ms sign)
6. ✅ No memory leaks detected by sanitizers
7. ✅ Fuzzing finds no crashes in 24 hours
8. ✅ CI/CD pipeline runs all tests automatically
9. ✅ Test documentation is complete
10. ✅ Coverage reports are generated and tracked

## Important Notes
- Use existing test patterns from backend test suite
- Ensure tests are deterministic and repeatable
- Mock external dependencies for unit tests
- Use real backend for integration tests only
- Document any platform-specific test requirements

## Memory Bank Logging
Document your work in `supacrypt-common/Memory/Phase_3_PKCS11_Provider/Task_3_4_Testing_Framework_Log.md` following the established format. Include:
- Test coverage metrics achieved
- Performance benchmark results
- Platform-specific test outcomes
- Any discovered issues and resolutions
- CI/CD pipeline configuration

Begin by setting up the unit test infrastructure with Google Test.