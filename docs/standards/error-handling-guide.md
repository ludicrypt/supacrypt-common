# Error Handling Guide for Supacrypt Components

## Overview

This document establishes comprehensive error handling patterns and error code ranges across all Supacrypt components to ensure consistent error propagation and debugging capabilities.

## Error Code Ranges

### Component Error Code Allocation
Each component is allocated a specific range of error codes to prevent conflicts and enable quick identification of error sources:

- **1000-1999**: Backend service errors
- **2000-2999**: PKCS#11 provider errors  
- **3000-3999**: Windows CSP errors
- **4000-4999**: Windows KSP errors
- **5000-5999**: macOS CTK errors
- **6000-6999**: Common/shared errors
- **7000-7999**: Azure Key Vault integration errors
- **8000-8999**: Network and communication errors
- **9000-9999**: System and platform errors

### Detailed Error Code Definitions

#### Backend Service Errors (1000-1999)
```csharp
public enum BackendServiceError : uint
{
    // General service errors (1000-1099)
    ServiceUnavailable = 1000,
    ServiceInitializationFailed = 1001,
    ServiceShutdownError = 1002,
    ConfigurationError = 1003,
    
    // Request validation errors (1100-1199)
    InvalidRequest = 1100,
    MissingRequiredParameter = 1101,
    InvalidParameterValue = 1102,
    UnsupportedOperation = 1103,
    RequestTooLarge = 1104,
    
    // Authentication and authorization errors (1200-1299)
    AuthenticationFailed = 1200,
    AuthorizationDenied = 1201,
    InvalidCredentials = 1202,
    TokenExpired = 1203,
    InsufficientPermissions = 1204,
    
    // Key management errors (1300-1399)
    KeyNotFound = 1300,
    KeyAlreadyExists = 1301,
    KeyGenerationFailed = 1302,
    KeyDeletionFailed = 1303,
    KeyImportFailed = 1304,
    KeyExportFailed = 1305,
    
    // Cryptographic operation errors (1400-1499)
    SigningFailed = 1400,
    VerificationFailed = 1401,
    EncryptionFailed = 1402,
    DecryptionFailed = 1403,
    HashingFailed = 1404,
    
    // Rate limiting and quotas (1500-1599)
    RateLimitExceeded = 1500,
    QuotaExceeded = 1501,
    ConcurrencyLimitExceeded = 1502,
    
    // Internal service errors (1900-1999)
    InternalError = 1900,
    DatabaseError = 1901,
    CacheError = 1902,
    MetricsError = 1903
}
```

#### PKCS#11 Provider Errors (2000-2999)
```c
// PKCS#11 provider specific errors
#define CKR_SUPACRYPT_BASE                     0x80002000UL

// Initialization and finalization errors (2000-2099)
#define CKR_SUPACRYPT_ALREADY_INITIALIZED      (CKR_SUPACRYPT_BASE + 0)
#define CKR_SUPACRYPT_NOT_INITIALIZED          (CKR_SUPACRYPT_BASE + 1)
#define CKR_SUPACRYPT_INITIALIZATION_FAILED    (CKR_SUPACRYPT_BASE + 2)
#define CKR_SUPACRYPT_FINALIZATION_FAILED      (CKR_SUPACRYPT_BASE + 3)

// Token and slot errors (2100-2199)
#define CKR_SUPACRYPT_TOKEN_NOT_PRESENT        (CKR_SUPACRYPT_BASE + 100)
#define CKR_SUPACRYPT_TOKEN_WRITE_PROTECTED    (CKR_SUPACRYPT_BASE + 101)
#define CKR_SUPACRYPT_SLOT_ID_INVALID          (CKR_SUPACRYPT_BASE + 102)
#define CKR_SUPACRYPT_TOKEN_NOT_RECOGNIZED     (CKR_SUPACRYPT_BASE + 103)

// Session management errors (2200-2299)
#define CKR_SUPACRYPT_SESSION_HANDLE_INVALID   (CKR_SUPACRYPT_BASE + 200)
#define CKR_SUPACRYPT_SESSION_COUNT_EXCEEDED   (CKR_SUPACRYPT_BASE + 201)
#define CKR_SUPACRYPT_SESSION_READ_ONLY        (CKR_SUPACRYPT_BASE + 202)
#define CKR_SUPACRYPT_SESSION_EXISTS           (CKR_SUPACRYPT_BASE + 203)

// Object management errors (2300-2399)
#define CKR_SUPACRYPT_OBJECT_HANDLE_INVALID    (CKR_SUPACRYPT_BASE + 300)
#define CKR_SUPACRYPT_OBJECT_NOT_FOUND         (CKR_SUPACRYPT_BASE + 301)
#define CKR_SUPACRYPT_OBJECT_TYPE_INVALID      (CKR_SUPACRYPT_BASE + 302)
#define CKR_SUPACRYPT_ATTRIBUTE_READ_ONLY      (CKR_SUPACRYPT_BASE + 303)

// Key management errors (2400-2499)
#define CKR_SUPACRYPT_KEY_HANDLE_INVALID       (CKR_SUPACRYPT_BASE + 400)
#define CKR_SUPACRYPT_KEY_SIZE_RANGE           (CKR_SUPACRYPT_BASE + 401)
#define CKR_SUPACRYPT_KEY_TYPE_INCONSISTENT    (CKR_SUPACRYPT_BASE + 402)
#define CKR_SUPACRYPT_KEY_GENERATION_FAILED    (CKR_SUPACRYPT_BASE + 403)

// Cryptographic operation errors (2500-2599)
#define CKR_SUPACRYPT_OPERATION_NOT_INITIALIZED (CKR_SUPACRYPT_BASE + 500)
#define CKR_SUPACRYPT_OPERATION_ACTIVE         (CKR_SUPACRYPT_BASE + 501)
#define CKR_SUPACRYPT_SIGNATURE_INVALID        (CKR_SUPACRYPT_BASE + 502)
#define CKR_SUPACRYPT_SIGNATURE_LEN_RANGE      (CKR_SUPACRYPT_BASE + 503)

// Provider-specific errors (2900-2999)
#define CKR_SUPACRYPT_PROVIDER_ERROR           (CKR_SUPACRYPT_BASE + 900)
#define CKR_SUPACRYPT_BACKEND_UNAVAILABLE      (CKR_SUPACRYPT_BASE + 901)
#define CKR_SUPACRYPT_CONFIGURATION_ERROR      (CKR_SUPACRYPT_BASE + 902)
```

#### Windows CSP Errors (3000-3999)
```c
// Windows CSP specific errors
#define SUPACRYPT_CSP_ERROR_BASE               3000

// Provider initialization errors (3000-3099)
#define NTE_SUPACRYPT_ALREADY_INITIALIZED      (SUPACRYPT_CSP_ERROR_BASE + 0)
#define NTE_SUPACRYPT_NOT_INITIALIZED          (SUPACRYPT_CSP_ERROR_BASE + 1)
#define NTE_SUPACRYPT_INIT_FAILED              (SUPACRYPT_CSP_ERROR_BASE + 2)
#define NTE_SUPACRYPT_CLEANUP_FAILED           (SUPACRYPT_CSP_ERROR_BASE + 3)

// Context management errors (3100-3199)
#define NTE_SUPACRYPT_INVALID_CONTEXT          (SUPACRYPT_CSP_ERROR_BASE + 100)
#define NTE_SUPACRYPT_CONTEXT_EXISTS           (SUPACRYPT_CSP_ERROR_BASE + 101)
#define NTE_SUPACRYPT_CONTAINER_NOT_FOUND      (SUPACRYPT_CSP_ERROR_BASE + 102)
#define NTE_SUPACRYPT_CONTAINER_EXISTS         (SUPACRYPT_CSP_ERROR_BASE + 103)

// Key management errors (3200-3299)
#define NTE_SUPACRYPT_KEY_NOT_FOUND            (SUPACRYPT_CSP_ERROR_BASE + 200)
#define NTE_SUPACRYPT_KEY_EXISTS               (SUPACRYPT_CSP_ERROR_BASE + 201)
#define NTE_SUPACRYPT_INVALID_KEY_SIZE         (SUPACRYPT_CSP_ERROR_BASE + 202)
#define NTE_SUPACRYPT_KEY_GENERATION_FAILED    (SUPACRYPT_CSP_ERROR_BASE + 203)

// Algorithm errors (3300-3399)
#define NTE_SUPACRYPT_UNSUPPORTED_ALGORITHM    (SUPACRYPT_CSP_ERROR_BASE + 300)
#define NTE_SUPACRYPT_INVALID_ALGORITHM        (SUPACRYPT_CSP_ERROR_BASE + 301)
#define NTE_SUPACRYPT_ALGORITHM_NOT_FOUND      (SUPACRYPT_CSP_ERROR_BASE + 302)

// Operation errors (3400-3499)
#define NTE_SUPACRYPT_OPERATION_FAILED         (SUPACRYPT_CSP_ERROR_BASE + 400)
#define NTE_SUPACRYPT_INVALID_PARAMETER        (SUPACRYPT_CSP_ERROR_BASE + 401)
#define NTE_SUPACRYPT_BUFFER_TOO_SMALL         (SUPACRYPT_CSP_ERROR_BASE + 402)
#define NTE_SUPACRYPT_INVALID_DATA             (SUPACRYPT_CSP_ERROR_BASE + 403)

// Provider-specific errors (3900-3999)
#define NTE_SUPACRYPT_PROVIDER_ERROR           (SUPACRYPT_CSP_ERROR_BASE + 900)
#define NTE_SUPACRYPT_REGISTRY_ERROR           (SUPACRYPT_CSP_ERROR_BASE + 901)
#define NTE_SUPACRYPT_BACKEND_ERROR            (SUPACRYPT_CSP_ERROR_BASE + 902)
```

#### Windows KSP Errors (4000-4999)
```c
// Windows KSP specific errors
#define SUPACRYPT_KSP_ERROR_BASE               4000

// Provider errors (4000-4099)
#define SUPACRYPT_KSP_NOT_SUPPORTED            (SUPACRYPT_KSP_ERROR_BASE + 0)
#define SUPACRYPT_KSP_INVALID_PARAMETER        (SUPACRYPT_KSP_ERROR_BASE + 1)
#define SUPACRYPT_KSP_NO_MEMORY                (SUPACRYPT_KSP_ERROR_BASE + 2)
#define SUPACRYPT_KSP_INTERNAL_ERROR           (SUPACRYPT_KSP_ERROR_BASE + 3)

// Key storage errors (4100-4199)
#define SUPACRYPT_KSP_OBJECT_NOT_FOUND         (SUPACRYPT_KSP_ERROR_BASE + 100)
#define SUPACRYPT_KSP_OBJECT_EXISTS            (SUPACRYPT_KSP_ERROR_BASE + 101)
#define SUPACRYPT_KSP_INVALID_KEY_SIZE         (SUPACRYPT_KSP_ERROR_BASE + 102)
#define SUPACRYPT_KSP_KEY_CREATION_FAILED      (SUPACRYPT_KSP_ERROR_BASE + 103)

// Algorithm errors (4200-4299)
#define SUPACRYPT_KSP_INVALID_ALGORITHM        (SUPACRYPT_KSP_ERROR_BASE + 200)
#define SUPACRYPT_KSP_ALGORITHM_NOT_SUPPORTED  (SUPACRYPT_KSP_ERROR_BASE + 201)
#define SUPACRYPT_KSP_INVALID_KEY_BLOB         (SUPACRYPT_KSP_ERROR_BASE + 202)

// Operation errors (4300-4399)
#define SUPACRYPT_KSP_INVALID_SIGNATURE        (SUPACRYPT_KSP_ERROR_BASE + 300)
#define SUPACRYPT_KSP_BUFFER_TOO_SMALL         (SUPACRYPT_KSP_ERROR_BASE + 301)
#define SUPACRYPT_KSP_OPERATION_NOT_SUPPORTED  (SUPACRYPT_KSP_ERROR_BASE + 302)

// Provider-specific errors (4900-4999)
#define SUPACRYPT_KSP_PROVIDER_ERROR           (SUPACRYPT_KSP_ERROR_BASE + 900)
#define SUPACRYPT_KSP_CONFIGURATION_ERROR      (SUPACRYPT_KSP_ERROR_BASE + 901)
#define SUPACRYPT_KSP_BACKEND_ERROR            (SUPACRYPT_KSP_ERROR_BASE + 902)
```

#### macOS CTK Errors (5000-5999)
```objc
// macOS CTK specific errors
typedef NS_ENUM(NSInteger, SupacryptCTKError) {
    // Token errors (5000-5099)
    SupacryptCTKErrorTokenNotFound = 5000,
    SupacryptCTKErrorTokenNotPresent = 5001,
    SupacryptCTKErrorTokenNotSupported = 5002,
    SupacryptCTKErrorTokenInitializationFailed = 5003,
    
    // Session errors (5100-5199)
    SupacryptCTKErrorSessionInvalid = 5100,
    SupacryptCTKErrorSessionNotFound = 5101,
    SupacryptCTKErrorSessionCreationFailed = 5102,
    SupacryptCTKErrorSessionAuthenticationFailed = 5103,
    
    // Key management errors (5200-5299)
    SupacryptCTKErrorKeyNotFound = 5200,
    SupacryptCTKErrorKeyCreationFailed = 5201,
    SupacryptCTKErrorKeyDeletionFailed = 5202,
    SupacryptCTKErrorInvalidKeyType = 5203,
    SupacryptCTKErrorInvalidKeySize = 5204,
    
    // Cryptographic operation errors (5300-5399)
    SupacryptCTKErrorSigningFailed = 5300,
    SupacryptCTKErrorVerificationFailed = 5301,
    SupacryptCTKErrorEncryptionFailed = 5302,
    SupacryptCTKErrorDecryptionFailed = 5303,
    
    // Keychain errors (5400-5499)
    SupacryptCTKErrorKeychainAccessDenied = 5400,
    SupacryptCTKErrorKeychainItemNotFound = 5401,
    SupacryptCTKErrorKeychainItemExists = 5402,
    SupacryptCTKErrorKeychainError = 5403,
    
    // Provider-specific errors (5900-5999)
    SupacryptCTKErrorProviderError = 5900,
    SupacryptCTKErrorConfigurationError = 5901,
    SupacryptCTKErrorBackendError = 5902
};
```

## Error Propagation Patterns

### gRPC Status Code Mapping
Map internal error codes to appropriate gRPC status codes for consistent API responses:

```csharp
public static class ErrorMapper
{
    public static Status MapToGrpcStatus(uint errorCode, string message)
    {
        return errorCode switch
        {
            // Authentication/Authorization errors
            >= 1200 and <= 1299 => new Status(StatusCode.Unauthenticated, message),
            
            // Validation errors
            >= 1100 and <= 1199 => new Status(StatusCode.InvalidArgument, message),
            
            // Resource not found errors
            1300 or 2301 or 3102 or 4100 or 5200 => new Status(StatusCode.NotFound, message),
            
            // Resource already exists errors
            1301 or 3103 or 4101 => new Status(StatusCode.AlreadyExists, message),
            
            // Permission denied errors
            1204 or 5400 => new Status(StatusCode.PermissionDenied, message),
            
            // Rate limiting errors
            >= 1500 and <= 1599 => new Status(StatusCode.ResourceExhausted, message),
            
            // Service unavailable errors
            1000 or 2901 or 3902 or 4902 or 5902 => new Status(StatusCode.Unavailable, message),
            
            // Unsupported operation errors
            1103 or 3300 or 4200 => new Status(StatusCode.Unimplemented, message),
            
            // Internal errors
            >= 1900 and <= 1999 => new Status(StatusCode.Internal, message),
            
            // Default to internal error
            _ => new Status(StatusCode.Internal, $"Unknown error: {errorCode} - {message}")
        };
    }
}
```

### Error Detail Message Formats
Standardize error message formats for consistency and debugging:

```csharp
public class ErrorDetails
{
    public uint Code { get; set; }
    public string Message { get; set; }
    public string Component { get; set; }
    public string Operation { get; set; }
    public string CorrelationId { get; set; }
    public DateTime Timestamp { get; set; }
    public Dictionary<string, string> AdditionalInfo { get; set; } = new();
}

public static class ErrorMessageFormatter
{
    public static string FormatErrorMessage(ErrorDetails details)
    {
        var sb = new StringBuilder();
        sb.AppendLine($"Error {details.Code}: {details.Message}");
        sb.AppendLine($"Component: {details.Component}");
        sb.AppendLine($"Operation: {details.Operation}");
        sb.AppendLine($"Correlation ID: {details.CorrelationId}");
        sb.AppendLine($"Timestamp: {details.Timestamp:yyyy-MM-dd HH:mm:ss.fff UTC}");
        
        if (details.AdditionalInfo.Any())
        {
            sb.AppendLine("Additional Information:");
            foreach (var kvp in details.AdditionalInfo)
            {
                sb.AppendLine($"  {kvp.Key}: {kvp.Value}");
            }
        }
        
        return sb.ToString();
    }
}
```

### Error Logging Requirements
Define consistent logging patterns for error scenarios:

```csharp
public static class ErrorLogger
{
    public static void LogError(
        ILogger logger,
        uint errorCode,
        string message,
        Exception? exception = null,
        string? operation = null,
        string? correlationId = null,
        Dictionary<string, object>? additionalContext = null)
    {
        using var scope = logger.BeginScope(new Dictionary<string, object>
        {
            ["ErrorCode"] = errorCode,
            ["Operation"] = operation ?? "Unknown",
            ["CorrelationId"] = correlationId ?? Guid.NewGuid().ToString()
        });

        var logLevel = GetLogLevelForErrorCode(errorCode);
        var contextData = additionalContext ?? new Dictionary<string, object>();
        
        logger.Log(logLevel, exception,
            "Error {ErrorCode}: {Message} - Context: {@Context}",
            errorCode, message, contextData);
    }

    private static LogLevel GetLogLevelForErrorCode(uint errorCode)
    {
        return errorCode switch
        {
            // Critical system errors
            >= 1900 and <= 1999 => LogLevel.Critical,
            >= 2900 and <= 2999 => LogLevel.Critical,
            
            // Authentication/security errors
            >= 1200 and <= 1299 => LogLevel.Warning,
            
            // Validation errors (expected)
            >= 1100 and <= 1199 => LogLevel.Information,
            
            // Default to error level
            _ => LogLevel.Error
        };
    }
}
```

## Component-Specific Error Handling

### Backend Service Error Handling
```csharp
public class CryptographicService : SupacryptService.SupacryptServiceBase
{
    public override async Task<GenerateKeyResponse> GenerateKey(
        GenerateKeyRequest request,
        ServerCallContext context)
    {
        var correlationId = context.RequestHeaders
            .GetValue("correlation-id") ?? Guid.NewGuid().ToString();
        
        try
        {
            // Validate request
            ValidateGenerateKeyRequest(request);
            
            // Perform operation
            var result = await _keyManagementService.GenerateKeyAsync(request, context.CancellationToken);
            
            return new GenerateKeyResponse
            {
                Success = true,
                KeyId = result.KeyId,
                PublicKey = ByteString.CopyFrom(result.PublicKey)
            };
        }
        catch (ValidationException ex)
        {
            var errorCode = GetValidationErrorCode(ex);
            ErrorLogger.LogError(_logger, errorCode, ex.Message, ex, "GenerateKey", correlationId);
            
            throw new RpcException(ErrorMapper.MapToGrpcStatus(errorCode, ex.Message));
        }
        catch (KeyManagementException ex)
        {
            ErrorLogger.LogError(_logger, ex.ErrorCode, ex.Message, ex, "GenerateKey", correlationId);
            
            return new GenerateKeyResponse
            {
                Success = false,
                Error = new ErrorInfo
                {
                    Code = ex.ErrorCode,
                    Message = ex.Message
                }
            };
        }
        catch (Exception ex)
        {
            const uint internalErrorCode = 1900;
            ErrorLogger.LogError(_logger, internalErrorCode, "Unexpected error during key generation", 
                ex, "GenerateKey", correlationId);
            
            throw new RpcException(new Status(StatusCode.Internal, "Internal server error"));
        }
    }
}
```

### PKCS#11 Provider Error Handling
```c
CK_RV supacrypt_generate_key_pair(
    CK_SESSION_HANDLE hSession,
    CK_MECHANISM_PTR pMechanism,
    CK_ATTRIBUTE_PTR pPublicKeyTemplate,
    CK_ULONG ulPublicKeyAttributeCount,
    CK_ATTRIBUTE_PTR pPrivateKeyTemplate,
    CK_ULONG ulPrivateKeyAttributeCount,
    CK_OBJECT_HANDLE_PTR phPublicKey,
    CK_OBJECT_HANDLE_PTR phPrivateKey)
{
    CK_RV rv = CKR_OK;
    SupacryptContext* ctx = NULL;
    char correlation_id[37] = {0};
    
    // Generate correlation ID for tracking
    generate_correlation_id(correlation_id);
    
    // Validate session
    rv = validate_session_handle(hSession, &ctx);
    if (rv != CKR_OK) {
        log_pkcs11_error(CKR_SUPACRYPT_SESSION_HANDLE_INVALID, 
            "Invalid session handle", "GenerateKeyPair", correlation_id);
        return CKR_SUPACRYPT_SESSION_HANDLE_INVALID;
    }
    
    // Validate mechanism
    if (pMechanism == NULL) {
        log_pkcs11_error(CKR_ARGUMENTS_BAD, 
            "Mechanism parameter is NULL", "GenerateKeyPair", correlation_id);
        return CKR_ARGUMENTS_BAD;
    }
    
    // Validate key size for RSA
    if (pMechanism->mechanism == CKM_RSA_PKCS_KEY_PAIR_GEN) {
        CK_ULONG key_size = 0;
        rv = get_key_size_from_template(pPublicKeyTemplate, ulPublicKeyAttributeCount, &key_size);
        if (rv != CKR_OK || key_size < 2048) {
            log_pkcs11_error(CKR_SUPACRYPT_KEY_SIZE_RANGE, 
                "Invalid RSA key size", "GenerateKeyPair", correlation_id);
            return CKR_SUPACRYPT_KEY_SIZE_RANGE;
        }
    }
    
    // Perform key generation via backend
    rv = backend_generate_key_pair(ctx, pMechanism, 
        pPublicKeyTemplate, ulPublicKeyAttributeCount,
        pPrivateKeyTemplate, ulPrivateKeyAttributeCount,
        phPublicKey, phPrivateKey, correlation_id);
    
    if (rv != CKR_OK) {
        log_pkcs11_error(rv, "Backend key generation failed", "GenerateKeyPair", correlation_id);
        return rv;
    }
    
    log_pkcs11_success("Key pair generated successfully", "GenerateKeyPair", correlation_id);
    return CKR_OK;
}
```

### Windows Provider Error Handling
```c
BOOL WINAPI CPGenKey(
    HCRYPTPROV hProv,
    ALG_ID Algid,
    DWORD dwFlags,
    HCRYPTKEY* phKey)
{
    DWORD error_code = ERROR_SUCCESS;
    char correlation_id[37] = {0};
    ProviderContext* ctx = NULL;
    
    generate_correlation_id(correlation_id);
    
    // Validate provider context
    if (!validate_provider_context(hProv, &ctx)) {
        error_code = NTE_SUPACRYPT_INVALID_CONTEXT;
        log_csp_error(error_code, "Invalid provider context", "CPGenKey", correlation_id);
        SetLastError(error_code);
        return FALSE;
    }
    
    // Validate algorithm
    if (!is_supported_algorithm(Algid)) {
        error_code = NTE_SUPACRYPT_UNSUPPORTED_ALGORITHM;
        log_csp_error(error_code, "Unsupported algorithm", "CPGenKey", correlation_id);
        SetLastError(error_code);
        return FALSE;
    }
    
    // Validate key size for RSA
    if (Algid == CALG_RSA_SIGN || Algid == CALG_RSA_KEYX) {
        DWORD key_size = (dwFlags & 0xFFFF0000) >> 16;
        if (key_size != 0 && key_size < 2048) {
            error_code = NTE_SUPACRYPT_INVALID_KEY_SIZE;
            log_csp_error(error_code, "Invalid RSA key size", "CPGenKey", correlation_id);
            SetLastError(error_code);
            return FALSE;
        }
    }
    
    // Perform key generation
    if (!backend_generate_key(ctx, Algid, dwFlags, phKey, correlation_id)) {
        error_code = NTE_SUPACRYPT_KEY_GENERATION_FAILED;
        log_csp_error(error_code, "Backend key generation failed", "CPGenKey", correlation_id);
        SetLastError(error_code);
        return FALSE;
    }
    
    log_csp_success("Key generated successfully", "CPGenKey", correlation_id);
    return TRUE;
}
```

## Error Documentation Template

### Error Code Documentation Format
Each error code should be documented with the following template:

```markdown
### Error Code: [CODE] - [NAME]

**Component**: [Component Name]
**Severity**: [Critical|Error|Warning|Information]
**Category**: [Validation|Authentication|Cryptographic|System|Network]

**Description**: 
Brief description of when this error occurs.

**Causes**:
- Cause 1: Detailed explanation
- Cause 2: Detailed explanation

**Resolution**:
- Step 1: How to resolve
- Step 2: Additional steps

**Example**:
```language
// Code example showing the error condition
```

**Related Errors**: [List of related error codes]
**See Also**: [Links to related documentation]
```

## Testing Error Conditions

### Error Injection for Testing
```csharp
public class ErrorInjectionService : IErrorInjectionService
{
    private readonly Dictionary<string, uint> _injectedErrors = new();
    private readonly ILogger<ErrorInjectionService> _logger;

    public void InjectError(string operation, uint errorCode)
    {
        _injectedErrors[operation] = errorCode;
        _logger.LogInformation("Injected error {ErrorCode} for operation {Operation}", 
            errorCode, operation);
    }

    public void ClearInjectedError(string operation)
    {
        _injectedErrors.Remove(operation);
        _logger.LogInformation("Cleared injected error for operation {Operation}", operation);
    }

    public uint? GetInjectedError(string operation)
    {
        return _injectedErrors.TryGetValue(operation, out var errorCode) ? errorCode : null;
    }
}

// Usage in service methods
public async Task<KeyGenerationResult> GenerateKeyAsync(KeyGenerationRequest request)
{
    // Check for injected errors during testing
    if (_errorInjectionService?.GetInjectedError("GenerateKey") is uint injectedError)
    {
        throw new KeyManagementException(injectedError, "Injected error for testing");
    }
    
    // Normal operation logic
    // ...
}
```

### Error Recovery Testing
```csharp
[Test]
public async Task GenerateKey_ShouldRetryOnTransientErrors()
{
    // Arrange
    var mockBackend = new Mock<IKeyVaultClient>();
    mockBackend.SetupSequence(x => x.GenerateKeyAsync(It.IsAny<string>(), It.IsAny<KeyType>()))
        .ThrowsAsync(new HttpRequestException("Temporary network error"))
        .ThrowsAsync(new HttpRequestException("Temporary network error"))
        .ReturnsAsync(new KeyVaultKey("test-key", KeyType.Rsa));

    var service = new KeyManagementService(mockBackend.Object, _logger, _options);

    // Act & Assert
    var result = await service.GenerateKeyAsync(new KeyGenerationRequest 
    { 
        KeyId = "test-key", 
        KeyType = KeyType.Rsa 
    });

    Assert.That(result.KeyId, Is.EqualTo("test-key"));
    mockBackend.Verify(x => x.GenerateKeyAsync(It.IsAny<string>(), It.IsAny<KeyType>()), 
        Times.Exactly(3));
}
```

## Best Practices

### Error Handling Do's
1. Always include correlation IDs for request tracking
2. Use appropriate log levels based on error severity
3. Map internal errors to appropriate public error codes
4. Include sufficient context for debugging
5. Implement retry logic for transient errors
6. Validate input parameters early
7. Use structured logging for error details
8. Follow security practices (don't log sensitive data)

### Error Handling Don'ts
1. Don't expose internal implementation details in error messages
2. Don't log cryptographic keys or sensitive data
3. Don't ignore or swallow exceptions without logging
4. Don't use generic error messages without context
5. Don't retry non-transient errors
6. Don't break error propagation chains
7. Don't use exceptions for normal control flow
8. Don't return different error types for the same condition

### Security Considerations
- Never include sensitive cryptographic material in error messages
- Use constant-time operations to prevent timing attacks
- Implement rate limiting for authentication errors
- Log security-relevant events for monitoring
- Use secure error reporting channels for sensitive errors

## References

- [gRPC Error Handling](https://grpc.io/docs/guides/error/)
- [Microsoft Error Handling Guidelines](https://docs.microsoft.com/en-us/dotnet/standard/exceptions/)
- [PKCS #11 Return Values](http://docs.oasis-open.org/pkcs11/pkcs11-spec/v3.0/pkcs11-spec-v3.0.html)
- [Windows Error Codes](https://docs.microsoft.com/en-us/windows/win32/debug/system-error-codes)
- [Apple Error Handling](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ErrorHandlingCocoa/ErrorHandling/ErrorHandling.html)
- [OpenTelemetry Error Tracking](https://opentelemetry.io/docs/specs/otel/trace/exceptions/)