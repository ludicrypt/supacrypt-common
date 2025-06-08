# Task Assignment: Integrate Azure Key Vault

## Agent Profile
**Type:** Implementation Agent - Azure Specialist  
**Expertise Required:** Azure Key Vault SDK, .NET 9, Azure Identity, Cryptographic Operations, Resilience Patterns

## Task Overview
Replace the mock implementations from Task 2.2 with real Azure Key Vault integration. Implement all cryptographic operations using Azure Key Vault's managed HSM capabilities while maintaining the existing service interfaces and error handling patterns.

## Context
- **Repository:** `supacrypt-backend-akv`
- **Current State:** Mock implementations working with full gRPC service infrastructure
- **Target:** Production-ready Azure Key Vault integration with proper authentication and resilience
- **Key Technologies:** Azure.Security.KeyVault.Keys, Azure.Identity, Polly for resilience

## Detailed Requirements

### 1. Azure Key Vault Client Configuration

#### Update AzureKeyVaultOptions Configuration
Enhance the existing `Configuration/AzureKeyVaultOptions.cs` with:
```csharp
public class AzureKeyVaultOptions
{
    public string VaultUri { get; set; } = string.Empty;
    public string? ClientId { get; set; }
    public string? TenantId { get; set; }
    public string? ClientSecret { get; set; }
    public bool UseManagedIdentity { get; set; } = true;
    public RetryOptions RetryOptions { get; set; } = new();
    public CircuitBreakerOptions CircuitBreaker { get; set; } = new();
}

public class CircuitBreakerOptions
{
    public int HandledEventsAllowedBeforeBreaking { get; set; } = 3;
    public TimeSpan DurationOfBreak { get; set; } = TimeSpan.FromSeconds(30);
}
```

#### Authentication Strategy
Implement flexible authentication supporting:
1. **Managed Identity** (preferred for production)
2. **Service Principal** (for development/testing)
3. **Azure CLI** (for local development)

### 2. Service Implementations

#### AzureKeyVaultCryptographicOperations
Replace `MockCryptographicOperations` with real implementation:
- Implement RSA operations (sign, verify, encrypt, decrypt)
- Implement ECDSA operations (sign, verify)
- Handle key size and algorithm mappings
- Implement proper error translation from Azure errors to protobuf errors

#### AzureKeyVaultKeyManagementService
Replace `MockKeyManagementService` with:
- Key generation with Azure Key Vault
- Key metadata management
- Key versioning support
- Soft delete and purge protection handling

#### AzureKeyVaultKeyRepository
Replace `MockKeyRepository` with:
- Key listing with pagination
- Key retrieval by identifier
- Key deletion (soft delete)
- Tag-based filtering support

### 3. Resilience Implementation

#### Using Polly Policies
Implement comprehensive resilience patterns:
```csharp
// Retry Policy
var retryPolicy = Policy
    .HandleResult<Response<KeyVaultKey>>(r => IsTransientError(r))
    .WaitAndRetryAsync(
        options.RetryOptions.MaxRetries,
        retryAttempt => TimeSpan.FromSeconds(Math.Pow(2, retryAttempt)),
        onRetry: LogRetryAttempt);

// Circuit Breaker
var circuitBreakerPolicy = Policy
    .HandleResult<Response<KeyVaultKey>>(r => IsCircuitBreakerError(r))
    .CircuitBreakerAsync(
        handledEventsAllowedBeforeBreaking: options.CircuitBreaker.HandledEventsAllowedBeforeBreaking,
        durationOfBreak: options.CircuitBreaker.DurationOfBreak,
        onBreak: LogCircuitOpen,
        onReset: LogCircuitReset);

// Combine policies
var resilientPolicy = Policy.WrapAsync(retryPolicy, circuitBreakerPolicy);
```

### 4. Error Handling

#### Azure to Protobuf Error Mapping
Map Azure Key Vault exceptions to appropriate protobuf error codes:
- `RequestFailedException` with 429 → `ERROR_CODE_RATE_LIMITED` (1001)
- `RequestFailedException` with 401/403 → `ERROR_CODE_UNAUTHORIZED` (1002)
- `RequestFailedException` with 404 → `ERROR_CODE_KEY_NOT_FOUND` (1003)
- `ArgumentException` → `ERROR_CODE_INVALID_REQUEST` (1004)
- Timeout exceptions → `ERROR_CODE_TIMEOUT` (1005)
- Circuit breaker open → `ERROR_CODE_SERVICE_UNAVAILABLE` (1006)

### 5. Performance Optimizations

#### Connection Pooling
- Implement singleton `KeyClient` instances per vault
- Configure HTTP client for optimal performance
- Consider caching key metadata for frequently accessed keys

#### Batch Operations
- Implement efficient listing with proper pagination
- Use parallel operations where appropriate (with throttling)

### 6. Observability

#### Metrics to Track
Add custom OpenTelemetry metrics:
- `supacrypt.backend.keyvault.operations.total` (counter)
- `supacrypt.backend.keyvault.operations.duration` (histogram)
- `supacrypt.backend.keyvault.errors.total` (counter by error type)
- `supacrypt.backend.keyvault.circuit_breaker.state` (gauge)

#### Structured Logging
Enhance logging with Azure Key Vault context:
```csharp
logger.LogInformation("Azure Key Vault operation completed",
    new
    {
        Operation = "CreateKey",
        KeyId = keyId,
        VaultName = vaultName,
        Duration = stopwatch.ElapsedMilliseconds,
        CorrelationId = correlationId
    });
```

### 7. Health Checks

#### Implement AzureKeyVaultHealthCheck
Update the existing health check to:
- Verify connectivity to Azure Key Vault
- Check authentication is working
- Optionally verify a test key exists
- Report circuit breaker state

### 8. Configuration Updates

#### Update appsettings.json
```json
{
  "AzureKeyVault": {
    "VaultUri": "https://your-vault.vault.azure.net/",
    "UseManagedIdentity": true,
    "RetryOptions": {
      "MaxRetries": 3,
      "Delay": "00:00:02",
      "MaxDelay": "00:00:16",
      "Mode": "Exponential"
    },
    "CircuitBreaker": {
      "HandledEventsAllowedBeforeBreaking": 3,
      "DurationOfBreak": "00:00:30"
    }
  }
}
```

### 9. Testing Considerations

#### Unit Tests
- Mock `KeyClient` for unit testing
- Test error handling scenarios
- Verify retry and circuit breaker behavior

#### Integration Tests
Create integration tests that:
- Use Azure Key Vault emulator or test vault
- Verify all operations end-to-end
- Test authentication methods
- Simulate transient failures

## Implementation Steps

1. **Set up Azure Key Vault Client**
   - Configure authentication
   - Implement client factory
   - Add to dependency injection

2. **Implement Service Classes**
   - Start with `AzureKeyVaultKeyRepository`
   - Then `AzureKeyVaultKeyManagementService`
   - Finally `AzureKeyVaultCryptographicOperations`

3. **Add Resilience Patterns**
   - Implement Polly policies
   - Integrate with service methods
   - Add appropriate logging

4. **Update Service Registration**
   - Replace mock registrations in `ServiceCollectionExtensions`
   - Configure options binding
   - Add health checks

5. **Test and Validate**
   - Run integration tests
   - Verify error scenarios
   - Check performance metrics

## Validation Criteria
Your implementation will be considered complete when:
1. ✅ All mock services replaced with Azure Key Vault implementations
2. ✅ Authentication working with at least Azure CLI for development
3. ✅ All 8 gRPC operations functional with real Azure Key Vault
4. ✅ Resilience patterns (retry, circuit breaker) implemented
5. ✅ Comprehensive error handling with proper mapping
6. ✅ Health checks reporting Azure Key Vault connectivity
7. ✅ Unit and integration tests passing
8. ✅ Metrics and logging properly implemented

## Important Notes
- Maintain backward compatibility with existing interfaces
- Do NOT store any secrets in code or configuration files
- Use Azure Key Vault's built-in features (soft delete, purge protection)
- Consider rate limiting implications for your implementation
- Document any Azure Key Vault limitations that affect functionality

## Memory Bank Logging
Document your work in `supacrypt-common/Memory/Phase_2_Backend_Service/Task_2_3_Azure_Integration_Log.md` following the established format. Include:
- Azure SDK versions used
- Authentication methods implemented
- Performance considerations
- Any limitations or workarounds needed
- Configuration requirements for production deployment

Begin by setting up your local Azure development environment and ensuring you have access to an Azure Key Vault instance for testing.