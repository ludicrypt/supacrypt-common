# C# Coding Standards for Supacrypt Backend Service

## Overview

This document establishes coding standards for the C# 13/.NET 9 backend service using .NET Aspire 9.3 and gRPC in the Supacrypt suite.

## Code Formatting

### Indentation and Spacing
- Use 4 spaces for indentation (no tabs)
- Maximum line length: 120 characters
- Single space around binary operators
- No trailing whitespace
- Use EditorConfig for consistent formatting

### Brace Style
Use K&R brace style (opening brace on same line):

```csharp
public class CryptographicService
{
    public async Task<GenerateKeyResponse> GenerateKeyAsync(GenerateKeyRequest request)
    {
        if (request.KeySize >= MinimumKeySize) {
            // Implementation
        }
    }
}
```

### Using Directives Organization
Order using directives as follows:
1. System namespaces
2. Microsoft namespaces
3. Third-party namespaces
4. Project namespaces

```csharp
using System;
using System.Threading.Tasks;

using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

using Grpc.Core;
using Azure.Security.KeyVault.Keys;

using Supacrypt.Common;
using Supacrypt.Backend.Services;
```

## Naming Conventions

### Classes and Interfaces
- PascalCase for class names
- Interface names prefixed with 'I'
- Service classes suffixed with 'Service'
- Controllers suffixed with 'Controller'

```csharp
public interface ICryptographicService
{
}

public class CryptographicService : ICryptographicService
{
}

public class KeyManagementController : ControllerBase
{
}
```

### Methods and Properties
- PascalCase for public methods and properties
- camelCase for private fields
- Async methods suffixed with 'Async'

```csharp
public class KeyManager
{
    private readonly ILogger<KeyManager> _logger;
    private readonly IKeyVaultClient _keyVaultClient;

    public async Task<KeyGenerationResult> GenerateRsaKeyAsync(int keySize)
    {
        return await ProcessKeyGenerationAsync(keySize);
    }

    public string KeyIdentifier { get; set; }

    private async Task<KeyGenerationResult> ProcessKeyGenerationAsync(int keySize)
    {
        // Implementation
    }
}
```

### Constants and Fields
- PascalCase for public constants
- camelCase for private fields prefixed with underscore
- ALL_CAPS for compile-time constants

```csharp
public class CryptographicConstants
{
    public const int MinimumRsaKeySize = 2048;
    public const string DefaultAlgorithm = "RSA-PSS";
    private const int MAX_RETRY_ATTEMPTS = 3;

    private readonly ILogger _logger;
    private readonly CryptographicOptions _options;
}
```

## .NET Naming Conventions Alignment

### Microsoft Guidelines Compliance
- Follow official .NET naming conventions
- Use appropriate suffixes for different types
- Implement consistent parameter naming

```csharp
// Repository pattern
public interface IKeyRepository
{
    Task<Key> GetByIdAsync(Guid keyId, CancellationToken cancellationToken = default);
    Task<IEnumerable<Key>> GetAllAsync(CancellationToken cancellationToken = default);
}

// Service pattern
public interface INotificationService
{
    Task SendAsync(NotificationRequest request, CancellationToken cancellationToken = default);
}

// Options pattern
public class KeyVaultOptions
{
    public string VaultUrl { get; set; } = string.Empty;
    public string ClientId { get; set; } = string.Empty;
    public TimeSpan RequestTimeout { get; set; } = TimeSpan.FromSeconds(30);
}
```

## Async/Await Patterns

### Best Practices
- Always use ConfigureAwait(false) in library code
- Prefer async/await over Task.Run for I/O operations
- Use cancellation tokens consistently
- Handle exceptions appropriately

```csharp
public class AsyncCryptographicService
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<AsyncCryptographicService> _logger;

    public async Task<OperationResult> ProcessRequestAsync(
        CryptographicRequest request,
        CancellationToken cancellationToken = default)
    {
        try {
            _logger.LogInformation("Processing cryptographic request {RequestId}", request.Id);

            var result = await PerformCryptographicOperationAsync(request, cancellationToken)
                .ConfigureAwait(false);

            return new OperationResult { Success = true, Data = result };
        }
        catch (OperationCanceledException) {
            _logger.LogInformation("Operation cancelled for request {RequestId}", request.Id);
            throw;
        }
        catch (Exception ex) {
            _logger.LogError(ex, "Failed to process request {RequestId}", request.Id);
            return new OperationResult { Success = false, Error = ex.Message };
        }
    }

    private async Task<string> PerformCryptographicOperationAsync(
        CryptographicRequest request,
        CancellationToken cancellationToken)
    {
        using var response = await _httpClient.PostAsJsonAsync(
            "api/crypto/operation",
            request,
            cancellationToken)
            .ConfigureAwait(false);

        response.EnsureSuccessStatusCode();
        return await response.Content.ReadAsStringAsync(cancellationToken)
            .ConfigureAwait(false);
    }
}
```

### Task Return Types
- Use `Task<T>` for methods returning values
- Use `Task` for methods not returning values
- Use `ValueTask<T>` for frequently synchronous operations

```csharp
public interface ICacheService
{
    // Frequently synchronous - use ValueTask
    ValueTask<string> GetAsync(string key);
    
    // Always asynchronous - use Task
    Task SetAsync(string key, string value, TimeSpan expiry);
    
    // Fire and forget - use Task
    Task InvalidateAsync(string pattern);
}
```

## Dependency Injection Patterns

### Service Registration
- Use extension methods for service registration
- Group related services together
- Use appropriate service lifetimes

```csharp
public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddCryptographicServices(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        // Options pattern
        services.Configure<KeyVaultOptions>(
            configuration.GetSection(KeyVaultOptions.SectionName));
        
        // Singleton services
        services.AddSingleton<ICryptographicFactory, CryptographicFactory>();
        
        // Scoped services
        services.AddScoped<ICryptographicService, CryptographicService>();
        services.AddScoped<IKeyManagementService, KeyManagementService>();
        
        // Transient services
        services.AddTransient<IKeyValidator, KeyValidator>();
        
        // HTTP clients
        services.AddHttpClient<IExternalCryptoService, ExternalCryptoService>(client => {
            client.BaseAddress = new Uri(configuration["ExternalCrypto:BaseUrl"]);
            client.Timeout = TimeSpan.FromSeconds(30);
        });

        return services;
    }
}
```

### Constructor Injection
- Use constructor injection for required dependencies
- Keep constructors simple
- Use guard clauses for validation

```csharp
public class CryptographicService : ICryptographicService
{
    private readonly IKeyVaultClient _keyVaultClient;
    private readonly ILogger<CryptographicService> _logger;
    private readonly IOptions<CryptographicOptions> _options;

    public CryptographicService(
        IKeyVaultClient keyVaultClient,
        ILogger<CryptographicService> logger,
        IOptions<CryptographicOptions> options)
    {
        _keyVaultClient = keyVaultClient ?? throw new ArgumentNullException(nameof(keyVaultClient));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        _options = options ?? throw new ArgumentNullException(nameof(options));
    }
}
```

## Exception Handling and Logging

### Exception Handling Patterns
- Use specific exception types
- Include meaningful error messages
- Log exceptions appropriately
- Don't catch and rethrow without adding value

```csharp
public class CryptographicOperationException : Exception
{
    public string OperationType { get; }
    public string KeyId { get; }

    public CryptographicOperationException(
        string operationType,
        string keyId,
        string message,
        Exception? innerException = null)
        : base($"Cryptographic operation '{operationType}' failed for key '{keyId}': {message}", innerException)
    {
        OperationType = operationType;
        KeyId = keyId;
    }
}

public class KeyManagementService
{
    public async Task<Key> GenerateKeyAsync(KeyGenerationRequest request)
    {
        try {
            ValidateKeyGenerationRequest(request);
            
            var key = await _keyVaultClient.GenerateKeyAsync(request).ConfigureAwait(false);
            
            _logger.LogInformation(
                "Successfully generated key {KeyId} of type {KeyType}",
                key.Id,
                request.KeyType);
                
            return key;
        }
        catch (KeyVaultException ex) when (ex.Status == 403) {
            _logger.LogError(ex, "Access denied when generating key for request {RequestId}", request.Id);
            throw new CryptographicOperationException("GenerateKey", request.KeyId, "Access denied", ex);
        }
        catch (Exception ex) {
            _logger.LogError(ex, "Unexpected error generating key for request {RequestId}", request.Id);
            throw;
        }
    }
}
```

### Logging Patterns
- Use structured logging with semantic meaning
- Include correlation IDs for request tracking
- Log at appropriate levels
- Never log sensitive cryptographic material

```csharp
public class CryptographicService
{
    private readonly ILogger<CryptographicService> _logger;

    public async Task<SignatureResult> SignDataAsync(SignRequest request)
    {
        using var scope = _logger.BeginScope(new Dictionary<string, object>
        {
            ["CorrelationId"] = request.CorrelationId,
            ["Operation"] = "SignData",
            ["KeyId"] = request.KeyId
        });

        _logger.LogInformation(
            "Starting signature operation for key {KeyId} with algorithm {Algorithm}",
            request.KeyId,
            request.Algorithm);

        var stopwatch = Stopwatch.StartNew();
        
        try {
            var result = await PerformSignOperationAsync(request).ConfigureAwait(false);
            
            _logger.LogInformation(
                "Signature operation completed successfully in {ElapsedMs}ms",
                stopwatch.ElapsedMilliseconds);
                
            return result;
        }
        catch (Exception ex) {
            _logger.LogError(ex,
                "Signature operation failed after {ElapsedMs}ms",
                stopwatch.ElapsedMilliseconds);
            throw;
        }
    }
}
```

## .NET Aspire 9.3 Patterns

### Service Registration
- Use Aspire's service discovery and configuration
- Implement health checks
- Configure observability properly

```csharp
public class Program
{
    public static void Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);

        // Add Aspire
        builder.AddServiceDefaults();

        // Add services
        builder.Services.AddGrpc();
        builder.Services.AddCryptographicServices(builder.Configuration);

        // Add health checks
        builder.Services.AddHealthChecks()
            .AddCheck<CryptographicServiceHealthCheck>("cryptographic")
            .AddCheck<KeyVaultHealthCheck>("keyvault");

        var app = builder.Build();

        // Configure middleware
        app.MapServiceDefaults();
        app.MapGrpcService<CryptographicService>();
        app.MapHealthChecks("/health");

        app.Run();
    }
}
```

### Configuration Management
- Use the options pattern consistently
- Implement configuration validation
- Support environment-specific settings

```csharp
public class CryptographicOptions
{
    public const string SectionName = "Cryptographic";

    [Required]
    public string KeyVaultUrl { get; set; } = string.Empty;

    [Range(2048, 4096)]
    public int DefaultKeySize { get; set; } = 2048;

    [Required]
    public string[] SupportedAlgorithms { get; set; } = Array.Empty<string>();

    public TimeSpan OperationTimeout { get; set; } = TimeSpan.FromMinutes(5);
}

// Validation
public class CryptographicOptionsValidator : IValidateOptions<CryptographicOptions>
{
    public ValidateOptionsResult Validate(string name, CryptographicOptions options)
    {
        var failures = new List<string>();

        if (string.IsNullOrEmpty(options.KeyVaultUrl)) {
            failures.Add("KeyVaultUrl is required");
        }

        if (!Uri.TryCreate(options.KeyVaultUrl, UriKind.Absolute, out _)) {
            failures.Add("KeyVaultUrl must be a valid URI");
        }

        return failures.Count > 0
            ? ValidateOptionsResult.Fail(failures)
            : ValidateOptionsResult.Success;
    }
}
```

### Health Check Implementation
- Implement custom health checks for dependencies
- Include dependency status in health responses
- Use appropriate timeouts

```csharp
public class KeyVaultHealthCheck : IHealthCheck
{
    private readonly IKeyVaultClient _keyVaultClient;
    private readonly ILogger<KeyVaultHealthCheck> _logger;

    public KeyVaultHealthCheck(
        IKeyVaultClient keyVaultClient,
        ILogger<KeyVaultHealthCheck> logger)
    {
        _keyVaultClient = keyVaultClient;
        _logger = logger;
    }

    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        try {
            using var timeoutCts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
            timeoutCts.CancelAfter(TimeSpan.FromSeconds(10));

            await _keyVaultClient.GetKeysAsync(cancellationToken: timeoutCts.Token)
                .ConfigureAwait(false);

            return HealthCheckResult.Healthy("Key Vault is accessible");
        }
        catch (OperationCanceledException) {
            _logger.LogWarning("Key Vault health check timed out");
            return HealthCheckResult.Degraded("Key Vault health check timed out");
        }
        catch (Exception ex) {
            _logger.LogError(ex, "Key Vault health check failed");
            return HealthCheckResult.Unhealthy("Key Vault is not accessible", ex);
        }
    }
}
```

## gRPC Service Implementation

### Service Class Structure
- Inherit from generated service base class
- Use dependency injection for service dependencies
- Implement proper error handling and status codes

```csharp
public class CryptographicService : Supacrypt.V1.SupacryptService.SupacryptServiceBase
{
    private readonly IKeyManagementService _keyManagementService;
    private readonly ICryptographicOperations _cryptographicOperations;
    private readonly ILogger<CryptographicService> _logger;

    public CryptographicService(
        IKeyManagementService keyManagementService,
        ICryptographicOperations cryptographicOperations,
        ILogger<CryptographicService> logger)
    {
        _keyManagementService = keyManagementService;
        _cryptographicOperations = cryptographicOperations;
        _logger = logger;
    }

    public override async Task<GenerateKeyResponse> GenerateKey(
        GenerateKeyRequest request,
        ServerCallContext context)
    {
        try {
            ValidateGenerateKeyRequest(request);

            var key = await _keyManagementService.GenerateKeyAsync(
                request,
                context.CancellationToken)
                .ConfigureAwait(false);

            return new GenerateKeyResponse
            {
                Success = true,
                KeyId = key.Id,
                PublicKey = ByteString.CopyFrom(key.PublicKeyBytes)
            };
        }
        catch (ValidationException ex) {
            _logger.LogWarning(ex, "Invalid request for GenerateKey");
            throw new RpcException(new Status(StatusCode.InvalidArgument, ex.Message));
        }
        catch (CryptographicOperationException ex) {
            _logger.LogError(ex, "Cryptographic operation failed");
            throw new RpcException(new Status(StatusCode.Internal, "Key generation failed"));
        }
    }
}
```

### Request Validation Patterns
- Validate all input parameters
- Use FluentValidation for complex validation
- Return appropriate gRPC status codes

```csharp
public class GenerateKeyRequestValidator : AbstractValidator<GenerateKeyRequest>
{
    public GenerateKeyRequestValidator()
    {
        RuleFor(x => x.KeyType)
            .Must(IsValidKeyType)
            .WithMessage("Invalid key type specified");

        RuleFor(x => x.KeySize)
            .GreaterThanOrEqualTo(2048)
            .When(x => x.KeyType == KeyType.Rsa)
            .WithMessage("RSA key size must be at least 2048 bits");

        RuleFor(x => x.KeyId)
            .NotEmpty()
            .MaximumLength(100)
            .WithMessage("Key ID is required and must be less than 100 characters");
    }

    private static bool IsValidKeyType(KeyType keyType)
    {
        return Enum.IsDefined(typeof(KeyType), keyType) && keyType != KeyType.Unknown;
    }
}
```

### Response Building Conventions
- Use consistent response structure
- Include appropriate error information
- Ensure all required fields are populated

```csharp
public static class ResponseBuilder
{
    public static GenerateKeyResponse Success(string keyId, byte[] publicKey)
    {
        return new GenerateKeyResponse
        {
            Success = true,
            KeyId = keyId,
            PublicKey = ByteString.CopyFrom(publicKey),
            Error = null
        };
    }

    public static GenerateKeyResponse Failure(string errorMessage, uint errorCode)
    {
        return new GenerateKeyResponse
        {
            Success = false,
            KeyId = string.Empty,
            PublicKey = ByteString.Empty,
            Error = new ErrorInfo
            {
                Message = errorMessage,
                Code = errorCode
            }
        };
    }
}
```

## Best Practices

### Do's
- Use nullable reference types consistently
- Implement proper disposal patterns
- Use cancellation tokens for long-running operations
- Follow async all the way pattern
- Use record types for immutable data
- Implement proper logging and telemetry

### Don'ts
- Don't use async void (except for event handlers)
- Don't block async operations with .Result or .Wait()
- Don't catch and ignore exceptions
- Don't log sensitive cryptographic material
- Don't use Task.Run for CPU-bound work in ASP.NET Core
- Don't create unnecessary allocations in hot paths

### Security Considerations
- Never log cryptographic keys or sensitive data
- Use secure string comparison for tokens
- Implement proper input validation
- Use HTTPS for all communications
- Follow OWASP security guidelines

```csharp
public static class SecureComparison
{
    public static bool ConstantTimeEquals(string a, string b)
    {
        if (a == null || b == null) {
            return a == b;
        }

        if (a.Length != b.Length) {
            return false;
        }

        var result = 0;
        for (int i = 0; i < a.Length; i++) {
            result |= a[i] ^ b[i];
        }

        return result == 0;
    }
}
```

## References

- [.NET Coding Conventions](https://docs.microsoft.com/en-us/dotnet/csharp/programming-guide/inside-a-program/coding-conventions)
- [C# Naming Guidelines](https://docs.microsoft.com/en-us/dotnet/standard/design-guidelines/naming-guidelines)
- [.NET Aspire Documentation](https://docs.microsoft.com/en-us/dotnet/aspire/)
- [gRPC for .NET](https://docs.microsoft.com/en-us/aspnet/core/grpc/)
- [Azure SDK for .NET](https://docs.microsoft.com/en-us/dotnet/azure/)
- [OWASP .NET Security](https://owasp.org/www-project-cheat-sheets/cheatsheets/DotNet_Security_Cheat_Sheet.html)