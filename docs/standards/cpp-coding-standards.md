# C++ Coding Standards for Supacrypt Native Providers

## Overview

This document establishes coding standards for C++20/C17 native cryptographic providers in the Supacrypt suite, including PKCS#11, Windows CSP/KSP, and macOS CTK implementations.

## Code Formatting

### Indentation and Spacing
- Use 4 spaces for indentation (no tabs)
- Maximum line length: 120 characters
- Single space around binary operators
- No trailing whitespace

### Brace Style
Use Allman brace style for consistency and readability:

```cpp
class CryptographicProvider
{
public:
    void GenerateKey()
    {
        if (keySize >= MinimumKeySize)
        {
            // Implementation
        }
    }
};
```

### Include Organization
Order includes as follows:
1. Standard library headers
2. Third-party library headers
3. Platform-specific headers
4. Project headers

```cpp
#include <memory>
#include <string>
#include <vector>

#include <openssl/evp.h>

#ifdef _WIN32
#include <windows.h>
#include <wincrypt.h>
#endif

#include "supacrypt/common/types.h"
#include "supacrypt/provider/base.h"
```

## Naming Conventions

### Classes and Structures
- PascalCase for class names
- Descriptive names reflecting cryptographic purpose

```cpp
class RsaKeyGenerator
{
};

struct CryptographicOperation
{
};
```

### Functions and Methods
- PascalCase for public methods
- camelCase for private methods
- Verb-noun structure for clarity

```cpp
class KeyManager
{
public:
    bool GenerateRsaKey(uint32_t keySize);
    CryptographicResult SignData(const std::vector<uint8_t>& data);

private:
    void initializeProvider();
    bool validateKeySize(uint32_t size);
};
```

### Variables and Constants
- camelCase for variables
- SCREAMING_SNAKE_CASE for constants
- Descriptive names avoiding abbreviations

```cpp
const uint32_t MINIMUM_RSA_KEY_SIZE = 2048;
const char* DEFAULT_ALGORITHM_NAME = "RSA-PSS";

std::unique_ptr<KeyHandle> rsaKeyHandle;
std::vector<uint8_t> encryptedData;
CryptographicOperation currentOperation;
```

### Platform-Specific Naming
- Prefix platform-specific classes with platform identifier
- Use conditional compilation for platform-specific code

```cpp
#ifdef _WIN32
class WindowsCspProvider : public CryptographicProvider
{
};
#endif

#ifdef __APPLE__
class MacOsCtkProvider : public CryptographicProvider
{
};
#endif
```

## Memory Management

### RAII Principles
- Use RAII for all resource management
- Prefer smart pointers over raw pointers
- Ensure exception safety

```cpp
class SecureKeyHandle
{
private:
    std::unique_ptr<KeyData, KeyDeleter> keyData_;

public:
    SecureKeyHandle(std::unique_ptr<KeyData, KeyDeleter> data)
        : keyData_(std::move(data))
    {
    }

    ~SecureKeyHandle()
    {
        // Automatic cleanup via smart pointer
    }
};
```

### Smart Pointer Usage
- `std::unique_ptr` for exclusive ownership
- `std::shared_ptr` only when shared ownership is required
- Custom deleters for cryptographic cleanup

```cpp
using SecureBuffer = std::unique_ptr<uint8_t[], SecureDeleter>;

class SecureDeleter
{
public:
    void operator()(uint8_t* ptr) const
    {
        if (ptr)
        {
            sodium_memzero(ptr, bufferSize_);
            delete[] ptr;
        }
    }
};
```

## Error Handling

### Exception vs Error Codes
- Use exceptions for unexpected errors
- Return error codes for expected failure cases
- Never throw exceptions across API boundaries

```cpp
enum class CryptographicError : uint32_t
{
    Success = 0,
    InvalidKeySize = 2001,
    InsufficientEntropy = 2002,
    OperationNotSupported = 2003
};

class CryptographicResult
{
private:
    CryptographicError error_;
    std::string errorMessage_;

public:
    bool IsSuccess() const { return error_ == CryptographicError::Success; }
    CryptographicError GetError() const { return error_; }
    const std::string& GetErrorMessage() const { return errorMessage_; }
};
```

### Error Code Ranges
- PKCS#11 provider errors: 2000-2999
- Windows CSP errors: 3000-3999
- Windows KSP errors: 4000-4999
- macOS CTK errors: 5000-5999

## Thread Safety

### Synchronization Patterns
- Use `std::mutex` for basic synchronization
- Prefer `std::shared_mutex` for read-write scenarios
- Use atomic operations for simple state changes

```cpp
class ThreadSafeKeyStore
{
private:
    mutable std::shared_mutex keyStoreMutex_;
    std::unordered_map<std::string, KeyHandle> keys_;

public:
    KeyHandle GetKey(const std::string& keyId) const
    {
        std::shared_lock lock(keyStoreMutex_);
        return keys_.at(keyId);
    }

    void StoreKey(const std::string& keyId, KeyHandle key)
    {
        std::unique_lock lock(keyStoreMutex_);
        keys_[keyId] = std::move(key);
    }
};
```

## Platform-Specific Guidelines

### Cross-Platform Compatibility
- Use conditional compilation for platform-specific code
- Abstract platform differences behind common interfaces
- Minimize platform-specific header inclusion

```cpp
#ifdef _WIN32
    #define SUPACRYPT_PLATFORM_WINDOWS
    #include <windows.h>
#elif defined(__APPLE__)
    #define SUPACRYPT_PLATFORM_MACOS
    #include <Security/Security.h>
#elif defined(__linux__)
    #define SUPACRYPT_PLATFORM_LINUX
#endif

class PlatformCryptographicProvider
{
public:
    static std::unique_ptr<CryptographicProvider> Create();

private:
#ifdef SUPACRYPT_PLATFORM_WINDOWS
    static std::unique_ptr<WindowsCspProvider> CreateWindowsProvider();
#elif defined(SUPACRYPT_PLATFORM_MACOS)
    static std::unique_ptr<MacOsCtkProvider> CreateMacOsProvider();
#endif
};
```

### Conditional Compilation Patterns
- Use feature macros rather than platform macros when possible
- Group platform-specific code into separate compilation units

```cpp
// Feature detection
#ifdef SUPACRYPT_HAS_HARDWARE_SECURITY_MODULE
    #include "supacrypt/hsm/provider.h"
#endif

// Platform-specific implementations
#ifdef SUPACRYPT_PLATFORM_WINDOWS
    #include "supacrypt/windows/csp_provider.h"
    #include "supacrypt/windows/ksp_provider.h"
#endif
```

## Provider-Specific Patterns

### PKCS#11 Implementation Patterns
- Follow PKCS#11 v3.0 specification strictly
- Use function pointer tables for API implementation
- Implement proper session management

```cpp
class Pkcs11Provider
{
private:
    CK_FUNCTION_LIST functionList_;
    std::unordered_map<CK_SESSION_HANDLE, Session> sessions_;

public:
    CK_RV C_Initialize(CK_VOID_PTR pInitArgs);
    CK_RV C_GetTokenInfo(CK_SLOT_ID slotID, CK_TOKEN_INFO_PTR pInfo);
    CK_RV C_GenerateKeyPair(CK_SESSION_HANDLE hSession, /* ... */);
};
```

### Windows CSP/KSP Conventions
- Follow Microsoft Cryptographic API conventions
- Use appropriate Windows data types
- Implement proper COM-style error handling

```cpp
class WindowsCspProvider
{
public:
    BOOL WINAPI CPAcquireContext(
        HCRYPTPROV* phProv,
        LPCSTR pszContainer,
        DWORD dwFlags,
        PVTableProvStruc pVTable
    );

    BOOL WINAPI CPGenKey(
        HCRYPTPROV hProv,
        ALG_ID Algid,
        DWORD dwFlags,
        HCRYPTKEY* phKey
    );
};
```

### macOS CTK Framework Integration
- Follow Apple's CryptoTokenKit patterns
- Use Objective-C++ where necessary
- Implement proper token lifecycle management

```cpp
// Use Objective-C++ for CTK integration
#ifdef __OBJC__
@interface SupacryptToken : TKSmartCardToken
- (nullable TKTokenKeychainItem*)createOrUpdateKeychainItemForKey:(TKTokenObjectID)keyID;
@end
#endif

// C++ wrapper for cross-platform compatibility
class MacOsCtkProvider : public CryptographicProvider
{
private:
    void* tokenRef_; // Opaque pointer to Objective-C token

public:
    CryptographicResult GenerateKey(const KeyGenerationParameters& params) override;
};
```

## Best Practices

### Do's
- Always clear sensitive data from memory
- Use constant-time operations for cryptographic comparisons
- Validate all input parameters
- Log security-relevant events
- Use secure random number generation
- Follow principle of least privilege

### Don'ts
- Never log cryptographic key material
- Don't use deprecated cryptographic algorithms
- Avoid hardcoded cryptographic parameters
- Don't ignore error return values
- Never use raw malloc/free for sensitive data
- Don't expose internal implementation details in public headers

### Security Considerations
- Zero sensitive memory before deallocation
- Use timing-safe comparison functions
- Implement proper key lifecycle management
- Follow secure coding practices for cryptographic operations

```cpp
class SecureComparison
{
public:
    static bool ConstantTimeEqual(const std::vector<uint8_t>& a, const std::vector<uint8_t>& b)
    {
        if (a.size() != b.size())
        {
            return false;
        }

        return sodium_memcmp(a.data(), b.data(), a.size()) == 0;
    }
};
```

## References

- [ISO/IEC 14882:2020 (C++20)](https://www.iso.org/standard/79358.html)
- [PKCS #11 Cryptographic Token Interface Standard](http://docs.oasis-open.org/pkcs11/pkcs11-spec/v3.0/pkcs11-spec-v3.0.html)
- [Microsoft Cryptographic Service Providers](https://docs.microsoft.com/en-us/windows/win32/seccrypto/cryptographic-service-providers)
- [Apple CryptoTokenKit Framework](https://developer.apple.com/documentation/cryptotokenkit)
- [OWASP Secure Coding Practices](https://owasp.org/www-project-secure-coding-practices-quick-reference-guide/)