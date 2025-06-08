# Task Assignment: PKCS#11 CMake Project Setup

## Agent Profile
**Type:** Implementation Agent - C++ Build Specialist  
**Expertise Required:** Modern CMake, Cross-Platform C++ Development, Build Systems, Dependency Management

## Task Overview
Create a modern CMake-based build system for the supacrypt-pkcs11 provider that supports cross-platform compilation (Windows, Linux, macOS), manages external dependencies, and establishes the foundation for a production-grade PKCS#11 implementation.

## Context
- **Repository:** `supacrypt-pkcs11`
- **Current State:** Empty repository with only LICENSE file
- **Target:** Production-ready CMake build system supporting C++20/C17
- **Integration:** Must connect to supacrypt-backend-akv via gRPC with mTLS

## Detailed Requirements

### 1. Root CMakeLists.txt

Create the main CMake configuration file with modern practices:

```cmake
# CMakeLists.txt
cmake_minimum_required(VERSION 3.20)
project(supacrypt-pkcs11 
    VERSION 0.1.0
    DESCRIPTION "Supacrypt PKCS#11 Cryptographic Provider"
    LANGUAGES C CXX)

# CMake modules path
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

# Project options
option(BUILD_SHARED_LIBS "Build shared libraries" ON)
option(BUILD_TESTING "Build test suite" ON)
option(BUILD_EXAMPLES "Build example applications" ON)
option(BUILD_BENCHMARKS "Build performance benchmarks" OFF)
option(ENABLE_COVERAGE "Enable code coverage" OFF)
option(ENABLE_SANITIZERS "Enable sanitizers" OFF)

# C++ and C standards
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_C_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Export compile commands for IDEs
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Include modules
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)
include(Dependencies)
include(CompilerOptions)
include(Platform)

# Create main library target
add_library(supacrypt-pkcs11)
add_library(supacrypt::pkcs11 ALIAS supacrypt-pkcs11)

# Set target properties
set_target_properties(supacrypt-pkcs11 PROPERTIES
    VERSION ${PROJECT_VERSION}
    SOVERSION ${PROJECT_VERSION_MAJOR}
    POSITION_INDEPENDENT_CODE ON
    C_VISIBILITY_PRESET hidden
    CXX_VISIBILITY_PRESET hidden
    VISIBILITY_INLINES_HIDDEN ON
)

# Add subdirectories
add_subdirectory(src)
add_subdirectory(include)

if(BUILD_TESTING)
    enable_testing()
    add_subdirectory(tests)
endif()

if(BUILD_EXAMPLES)
    add_subdirectory(examples)
endif()

if(BUILD_BENCHMARKS)
    add_subdirectory(benchmarks)
endif()

# Installation
include(Installation)

# CPack configuration
include(Packaging)
```

### 2. Dependency Management (cmake/Dependencies.cmake)

```cmake
# cmake/Dependencies.cmake
include(FetchContent)

# Thread support
find_package(Threads REQUIRED)

# OpenSSL (for local crypto operations)
find_package(OpenSSL REQUIRED)

# Protobuf and gRPC
FetchContent_Declare(
    gRPC
    GIT_REPOSITORY https://github.com/grpc/grpc
    GIT_TAG        v1.65.0
)
set(gRPC_BUILD_TESTS OFF)
set(gRPC_BUILD_EXAMPLES OFF)
FetchContent_MakeAvailable(gRPC)

# Find generated protobuf files
find_package(Protobuf REQUIRED)

# Google Test (for testing)
if(BUILD_TESTING)
    FetchContent_Declare(
        googletest
        GIT_REPOSITORY https://github.com/google/googletest.git
        GIT_TAG        v1.15.0
    )
    set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
    FetchContent_MakeAvailable(googletest)
endif()

# OpenTelemetry C++ SDK
FetchContent_Declare(
    opentelemetry-cpp
    GIT_REPOSITORY https://github.com/open-telemetry/opentelemetry-cpp.git
    GIT_TAG        v1.16.0
)
set(BUILD_TESTING OFF)
set(WITH_EXAMPLES OFF)
set(WITH_OTLP_GRPC ON)
set(WITH_OTLP_HTTP OFF)
FetchContent_MakeAvailable(opentelemetry-cpp)

# Platform-specific dependencies
if(WIN32)
    # Windows-specific dependencies
elseif(APPLE)
    # macOS-specific dependencies
    find_library(SECURITY_FRAMEWORK Security)
    find_library(COREFOUNDATION_FRAMEWORK CoreFoundation)
else()
    # Linux-specific dependencies
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(LIBDL REQUIRED libdl)
endif()
```

### 3. Compiler Options (cmake/CompilerOptions.cmake)

```cmake
# cmake/CompilerOptions.cmake

# Compiler-specific options
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    # Common flags for GCC and Clang
    add_compile_options(
        -Wall
        -Wextra
        -Wpedantic
        -Wcast-align
        -Wcast-qual
        -Wconversion
        -Wformat=2
        -Wnull-dereference
        -Wold-style-cast
        -Woverloaded-virtual
        -Wshadow
        -Wsign-conversion
        -Wunused
        -Wno-unknown-pragmas
    )
    
    # C++-specific warnings
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wnon-virtual-dtor")
    
    # Debug-specific flags
    set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -Og -ggdb3")
    set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -Og -ggdb3")
    
    # Release optimization
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3 -DNDEBUG")
    set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -O3 -DNDEBUG")
    
    # Sanitizers
    if(ENABLE_SANITIZERS)
        add_compile_options(-fsanitize=address,undefined -fno-omit-frame-pointer)
        add_link_options(-fsanitize=address,undefined)
    endif()
    
elseif(MSVC)
    # MSVC flags
    add_compile_options(
        /W4
        /permissive-
        /Zc:__cplusplus
        /Zc:inline
        /Zc:throwingNew
        /EHsc
        /MP
    )
    
    # Disable specific warnings
    add_compile_definitions(_CRT_SECURE_NO_WARNINGS)
    
    # Debug configuration
    set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} /Zi /Od /RTC1")
    
    # Release optimization
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /O2 /Ob2 /DNDEBUG")
endif()

# Coverage flags
if(ENABLE_COVERAGE AND CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    add_compile_options(--coverage -fprofile-arcs -ftest-coverage)
    add_link_options(--coverage)
endif()
```

### 4. Platform Configuration (cmake/Platform.cmake)

```cmake
# cmake/Platform.cmake

# Platform detection and configuration
if(WIN32)
    add_compile_definitions(
        WIN32_LEAN_AND_MEAN
        NOMINMAX
        _WIN32_WINNT=0x0601  # Windows 7 minimum
    )
    
    # Export all symbols for PKCS#11 DLL
    set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)
    
elseif(APPLE)
    # macOS specific settings
    set(CMAKE_MACOSX_RPATH ON)
    set(CMAKE_INSTALL_RPATH "@loader_path/../lib")
    
    # Universal binary support
    if(CMAKE_OSX_ARCHITECTURES)
        message(STATUS "Building universal binary for: ${CMAKE_OSX_ARCHITECTURES}")
    endif()
    
elseif(UNIX)
    # Linux/Unix specific settings
    set(CMAKE_INSTALL_RPATH "$ORIGIN/../lib")
    
    # Position independent code for shared libraries
    set(CMAKE_POSITION_INDEPENDENT_CODE ON)
endif()

# Architecture detection
if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(ARCH_64BIT TRUE)
else()
    set(ARCH_32BIT TRUE)
endif()

# Endianness detection
include(TestBigEndian)
test_big_endian(IS_BIG_ENDIAN)
if(IS_BIG_ENDIAN)
    add_compile_definitions(SUPACRYPT_BIG_ENDIAN)
endif()
```

### 5. Project Structure Creation

Create the following directory structure:

```bash
#!/bin/bash
# setup_structure.sh

mkdir -p cmake
mkdir -p include/supacrypt/pkcs11
mkdir -p src/{core,grpc,security,observability,utils}
mkdir -p tests/{unit,integration,compliance,fixtures}
mkdir -p examples
mkdir -p benchmarks
mkdir -p docs
mkdir -p tools
mkdir -p .github/workflows

# Create placeholder files
touch include/supacrypt/pkcs11/pkcs11.h
touch include/supacrypt/pkcs11/supacrypt_pkcs11.h
touch src/CMakeLists.txt
touch tests/CMakeLists.txt
touch examples/CMakeLists.txt
touch benchmarks/CMakeLists.txt
```

### 6. Source Directory CMake (src/CMakeLists.txt)

```cmake
# src/CMakeLists.txt

# Source files
set(PKCS11_SOURCES
    core/pkcs11_init.cpp
    core/pkcs11_session.cpp
    core/pkcs11_object.cpp
    core/pkcs11_crypto.cpp
    core/pkcs11_key.cpp
    core/pkcs11_mechanism.cpp
    grpc/grpc_client.cpp
    grpc/grpc_connection_pool.cpp
    security/certificate_manager.cpp
    security/secure_memory.cpp
    observability/metrics.cpp
    observability/tracing.cpp
    utils/error_mapping.cpp
    utils/logging.cpp
)

# Add sources to target
target_sources(supacrypt-pkcs11 PRIVATE ${PKCS11_SOURCES})

# Include directories
target_include_directories(supacrypt-pkcs11
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}
)

# Link dependencies
target_link_libraries(supacrypt-pkcs11
    PUBLIC
        Threads::Threads
    PRIVATE
        OpenSSL::SSL
        OpenSSL::Crypto
        gRPC::grpc++
        protobuf::libprotobuf
        opentelemetry-cpp::api
        opentelemetry-cpp::sdk
        opentelemetry-cpp::otlp_grpc_exporter
)

# Platform-specific linking
if(WIN32)
    target_link_libraries(supacrypt-pkcs11 PRIVATE ws2_32 crypt32)
elseif(APPLE)
    target_link_libraries(supacrypt-pkcs11 PRIVATE 
        ${SECURITY_FRAMEWORK} 
        ${COREFOUNDATION_FRAMEWORK}
    )
else()
    target_link_libraries(supacrypt-pkcs11 PRIVATE ${LIBDL_LIBRARIES})
endif()

# Generate export header
include(GenerateExportHeader)
generate_export_header(supacrypt-pkcs11
    BASE_NAME SUPACRYPT_PKCS11
    EXPORT_MACRO_NAME SUPACRYPT_PKCS11_EXPORT
    EXPORT_FILE_NAME ${CMAKE_BINARY_DIR}/include/supacrypt/pkcs11/export.h
)
```

### 7. Testing Configuration (tests/CMakeLists.txt)

```cmake
# tests/CMakeLists.txt

# Test executable
add_executable(supacrypt-pkcs11-tests)

# Test sources
set(TEST_SOURCES
    unit/test_main.cpp
    unit/test_pkcs11_init.cpp
    unit/test_session_management.cpp
    unit/test_crypto_operations.cpp
    unit/test_key_management.cpp
    unit/test_error_handling.cpp
    integration/test_grpc_connection.cpp
    integration/test_backend_operations.cpp
    compliance/test_pkcs11_compliance.cpp
)

target_sources(supacrypt-pkcs11-tests PRIVATE ${TEST_SOURCES})

# Link test dependencies
target_link_libraries(supacrypt-pkcs11-tests
    PRIVATE
        supacrypt::pkcs11
        GTest::gtest
        GTest::gtest_main
        GTest::gmock
)

# Add test fixtures directory
target_compile_definitions(supacrypt-pkcs11-tests
    PRIVATE TEST_FIXTURES_DIR="${CMAKE_CURRENT_SOURCE_DIR}/fixtures"
)

# Register tests with CTest
include(GoogleTest)
gtest_discover_tests(supacrypt-pkcs11-tests)

# Coverage target
if(ENABLE_COVERAGE)
    include(CodeCoverage)
    setup_target_for_coverage_gcovr_html(
        NAME coverage
        EXECUTABLE supacrypt-pkcs11-tests
        EXCLUDE "*/tests/*" "*/examples/*" "*/benchmarks/*"
    )
endif()
```

### 8. Installation Configuration (cmake/Installation.cmake)

```cmake
# cmake/Installation.cmake

# Install library
install(TARGETS supacrypt-pkcs11
    EXPORT supacrypt-pkcs11-targets
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

# Install headers
install(DIRECTORY include/supacrypt
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    FILES_MATCHING PATTERN "*.h"
)

# Install generated export header
install(FILES ${CMAKE_BINARY_DIR}/include/supacrypt/pkcs11/export.h
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/supacrypt/pkcs11
)

# Install CMake config files
install(EXPORT supacrypt-pkcs11-targets
    FILE supacrypt-pkcs11-targets.cmake
    NAMESPACE supacrypt::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/supacrypt-pkcs11
)

# Generate config file
configure_package_config_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake/supacrypt-pkcs11-config.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/supacrypt-pkcs11-config.cmake
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/supacrypt-pkcs11
)

# Generate version file
write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/supacrypt-pkcs11-config-version.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)

# Install config files
install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/supacrypt-pkcs11-config.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/supacrypt-pkcs11-config-version.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/supacrypt-pkcs11
)
```

### 9. Build Scripts

#### build.sh (Linux/macOS)
```bash
#!/bin/bash
# build.sh

set -e

BUILD_TYPE=${1:-Release}
BUILD_DIR="build-${BUILD_TYPE,,}"

echo "Building supacrypt-pkcs11 in ${BUILD_TYPE} mode..."

# Create build directory
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

# Configure
cmake .. \
    -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" \
    -DBUILD_TESTING=ON \
    -DBUILD_EXAMPLES=ON \
    -DENABLE_COVERAGE=$([ "${BUILD_TYPE}" = "Debug" ] && echo "ON" || echo "OFF")

# Build
cmake --build . --parallel $(nproc)

# Run tests
ctest --output-on-failure

echo "Build complete!"
```

#### build.ps1 (Windows)
```powershell
# build.ps1

param(
    [string]$BuildType = "Release"
)

$BuildDir = "build-$($BuildType.ToLower())"

Write-Host "Building supacrypt-pkcs11 in $BuildType mode..." -ForegroundColor Green

# Create build directory
New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null
Set-Location $BuildDir

# Configure
cmake .. `
    -G "Visual Studio 17 2022" `
    -A x64 `
    -DCMAKE_BUILD_TYPE=$BuildType `
    -DBUILD_TESTING=ON `
    -DBUILD_EXAMPLES=ON

# Build
cmake --build . --config $BuildType --parallel

# Run tests
ctest -C $BuildType --output-on-failure

Write-Host "Build complete!" -ForegroundColor Green
```

### 10. CI/CD Configuration (.github/workflows/ci.yml)

```yaml
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        build_type: [Debug, Release]
        
    runs-on: ${{ matrix.os }}
    
    steps:
    - uses: actions/checkout@v4
      with:
        submodules: recursive
    
    - name: Install dependencies (Ubuntu)
      if: runner.os == 'Linux'
      run: |
        sudo apt-get update
        sudo apt-get install -y libssl-dev
    
    - name: Install dependencies (macOS)
      if: runner.os == 'macOS'
      run: |
        brew install openssl
    
    - name: Configure CMake
      run: |
        cmake -B build -DCMAKE_BUILD_TYPE=${{ matrix.build_type }} -DBUILD_TESTING=ON
    
    - name: Build
      run: cmake --build build --config ${{ matrix.build_type }} --parallel
    
    - name: Test
      run: ctest --test-dir build -C ${{ matrix.build_type }} --output-on-failure
    
    - name: Upload test results
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: test-results-${{ matrix.os }}-${{ matrix.build_type }}
        path: build/test-results/
```

## Implementation Steps

1. **Initialize Repository**
   - Create directory structure using setup script
   - Copy CMake files to appropriate locations
   - Initialize git repository

2. **Configure Dependencies**
   - Test FetchContent for all dependencies
   - Verify version compatibility
   - Ensure reproducible builds

3. **Create Stub Implementation**
   - Minimal PKCS#11 function stubs
   - Basic gRPC client connection
   - Placeholder for OpenTelemetry

4. **Verify Build System**
   - Test on all target platforms
   - Verify all configurations build
   - Check installation process

5. **Set Up CI/CD**
   - Configure GitHub Actions workflow
   - Enable build matrix for all platforms
   - Set up artifact collection

## Validation Criteria
Your implementation will be considered complete when:
1. ✅ CMake configures successfully on Windows, Linux, and macOS
2. ✅ All dependencies are fetched and built automatically
3. ✅ Project builds in Debug and Release modes
4. ✅ Basic PKCS#11 library exports required symbols
5. ✅ Test framework runs (even with placeholder tests)
6. ✅ Installation process works correctly
7. ✅ CI/CD pipeline passes on all platforms
8. ✅ Documentation is clear and complete
9. ✅ Build reproduces consistently
10. ✅ Cross-compilation is supported where applicable

## Important Notes
- Ensure PKCS#11 C API compatibility (extern "C" exports)
- Use modern CMake practices (target-based, no global variables)
- Keep platform-specific code isolated in separate modules
- Document all build options and their effects
- Consider future needs for signing/notarization on macOS/Windows

## Memory Bank Logging
Document your work in `supacrypt-common/Memory/Phase_3_PKCS11_Provider/Task_3_1_Project_Setup_Log.md` following the established format. Include:
- CMake configuration decisions
- Dependency version selections
- Platform-specific considerations
- Build performance metrics
- Any issues encountered and solutions

Begin by creating the directory structure and root CMakeLists.txt file.