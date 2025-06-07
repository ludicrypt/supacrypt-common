# Logging Standards for Supacrypt Components

## Overview

This document establishes comprehensive logging standards for all Supacrypt components to ensure consistent observability, debugging capabilities, and security compliance across the cryptographic software suite.

## Log Levels and Usage Guidelines

### Log Level Definitions
Use the following log levels consistently across all components:

#### Critical
- System failures that require immediate attention
- Security breaches or unauthorized access attempts
- Component initialization failures that prevent startup
- Data corruption or loss scenarios

```csharp
_logger.LogCritical("Azure Key Vault authentication failed: unable to retrieve credentials from {Source}", 
    credentialSource);
    
_logger.LogCritical("PKCS#11 provider initialization failed: library could not be loaded from {Path}", 
    libraryPath);
```

#### Error
- Operation failures that affect functionality
- Network communication failures
- Resource access denials
- Validation failures for external input

```csharp
_logger.LogError("Key generation failed for key {KeyId}: {ErrorMessage}", 
    request.KeyId, ex.Message);
    
_logger.LogError("gRPC service call failed: {ServiceMethod} returned status {StatusCode}", 
    context.Method, context.Status.StatusCode);
```

#### Warning
- Recoverable errors or degraded functionality
- Performance issues or timeouts
- Configuration issues that don't prevent operation
- Authentication failures (potential security events)

```csharp
_logger.LogWarning("Key cache miss for key {KeyId}, falling back to Key Vault lookup", keyId);

_logger.LogWarning("Request from {ClientId} exceeded rate limit, throttling applied", clientId);
```

#### Information
- Normal operational events
- Successful completion of significant operations
- Configuration changes
- Service lifecycle events

```csharp
_logger.LogInformation("Successfully generated {KeyType} key {KeyId} with size {KeySize} bits", 
    keyType, keyId, keySize);
    
_logger.LogInformation("Supacrypt backend service started on {Host}:{Port} with TLS {TlsStatus}", 
    host, port, tlsEnabled ? "enabled" : "disabled");
```

#### Debug
- Detailed execution flow information
- Variable values and state changes
- Internal component interactions
- Performance metrics and timings

```csharp
_logger.LogDebug("Processing sign request: KeyId={KeyId}, Algorithm={Algorithm}, DataLength={DataLength}", 
    request.KeyId, request.Algorithm, request.Data.Length);
    
_logger.LogDebug("Cache lookup completed in {ElapsedMs}ms for key {KeyId}", 
    stopwatch.ElapsedMilliseconds, keyId);
```

#### Trace
- Very detailed execution information
- Entry/exit points of methods
- Detailed parameter values
- Low-level component interactions

```csharp
_logger.LogTrace("Entering GenerateKeyAsync with parameters: {@Request}", request);
_logger.LogTrace("Exiting GenerateKeyAsync with result: Success={Success}", result.Success);
```

## Structured Logging Format

### Required Fields
All log entries must include these standardized fields:

```csharp
public class LogEntry
{
    [JsonPropertyName("timestamp")]
    public DateTime Timestamp { get; set; }
    
    [JsonPropertyName("level")]
    public string Level { get; set; }
    
    [JsonPropertyName("component")]
    public string Component { get; set; }
    
    [JsonPropertyName("operation")]
    public string Operation { get; set; }
    
    [JsonPropertyName("correlation_id")]
    public string CorrelationId { get; set; }
    
    [JsonPropertyName("message")]
    public string Message { get; set; }
    
    [JsonPropertyName("machine_name")]
    public string MachineName { get; set; }
    
    [JsonPropertyName("process_id")]
    public int ProcessId { get; set; }
    
    [JsonPropertyName("thread_id")]
    public int ThreadId { get; set; }
}
```

### Optional Fields
Include these fields when relevant context is available:

```csharp
public class ExtendedLogEntry : LogEntry
{
    [JsonPropertyName("user_id")]
    public string? UserId { get; set; }
    
    [JsonPropertyName("session_id")]
    public string? SessionId { get; set; }
    
    [JsonPropertyName("key_id")]
    public string? KeyId { get; set; }
    
    [JsonPropertyName("duration_ms")]
    public long? DurationMs { get; set; }
    
    [JsonPropertyName("request_id")]
    public string? RequestId { get; set; }
    
    [JsonPropertyName("client_ip")]
    public string? ClientIp { get; set; }
    
    [JsonPropertyName("error_code")]
    public uint? ErrorCode { get; set; }
    
    [JsonPropertyName("provider_type")]
    public string? ProviderType { get; set; }
    
    [JsonPropertyName("algorithm")]
    public string? Algorithm { get; set; }
    
    [JsonPropertyName("key_size")]
    public int? KeySize { get; set; }
}
```

### JSON Logging Configuration

#### .NET Backend Service Configuration
```json
{
  "Serilog": {
    "Using": ["Serilog.Sinks.Console", "Serilog.Sinks.File", "Serilog.Sinks.OpenTelemetry"],
    "MinimumLevel": {
      "Default": "Information",
      "Override": {
        "Microsoft": "Warning",
        "System": "Warning",
        "Grpc": "Information",
        "Supacrypt": "Debug"
      }
    },
    "WriteTo": [
      {
        "Name": "Console",
        "Args": {
          "outputTemplate": "[{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz}] [{Level:u3}] [{Component}] {Message:lj} {NewLine}{Exception}",
          "formatter": "Serilog.Formatting.Json.JsonFormatter"
        }
      },
      {
        "Name": "File",
        "Args": {
          "path": "/var/log/supacrypt/backend-.log",
          "rollingInterval": "Day",
          "retainedFileCountLimit": 30,
          "fileSizeLimitBytes": 104857600,
          "formatter": "Serilog.Formatting.Json.JsonFormatter"
        }
      },
      {
        "Name": "OpenTelemetry",
        "Args": {
          "endpoint": "http://localhost:4317",
          "protocol": "Grpc"
        }
      }
    ],
    "Enrich": [
      "FromLogContext",
      "WithMachineName",
      "WithProcessId",
      "WithThreadId"
    ],
    "Properties": {
      "Component": "supacrypt-backend",
      "Version": "1.0.0"
    }
  }
}
```

#### C++ Native Components Configuration
```cpp
// Using spdlog for C++ components
#include <spdlog/spdlog.h>
#include <spdlog/sinks/json_file_sink.h>
#include <spdlog/sinks/stdout_color_sinks.h>

class SupacryptLogger 
{
private:
    std::shared_ptr<spdlog::logger> logger_;
    std::string component_;
    
public:
    SupacryptLogger(const std::string& component, const std::string& logPath) 
        : component_(component)
    {
        auto console_sink = std::make_shared<spdlog::sinks::stdout_color_sink_mt>();
        auto file_sink = std::make_shared<spdlog::sinks::basic_file_sink_mt>(logPath, true);
        
        console_sink->set_level(spdlog::level::info);
        file_sink->set_level(spdlog::level::debug);
        
        console_sink->set_pattern("[%Y-%m-%d %H:%M:%S.%f] [%^%l%$] [%n] %v");
        file_sink->set_pattern("[%Y-%m-%d %H:%M:%S.%f] [%l] [%n] %v");
        
        logger_ = std::make_shared<spdlog::logger>(component, 
            spdlog::sinks_init_list{console_sink, file_sink});
        
        logger_->set_level(spdlog::level::debug);
        spdlog::register_logger(logger_);
    }
    
    template<typename... Args>
    void LogInfo(const std::string& operation, const std::string& correlationId, 
                 const std::string& format, Args&&... args)
    {
        auto message = fmt::format(format, std::forward<Args>(args)...);
        logger_->info("{{\"operation\":\"{}\",\"correlation_id\":\"{}\",\"message\":\"{}\"}}",
                     operation, correlationId, message);
    }
    
    template<typename... Args>
    void LogError(const std::string& operation, const std::string& correlationId,
                  uint32_t errorCode, const std::string& format, Args&&... args)
    {
        auto message = fmt::format(format, std::forward<Args>(args)...);
        logger_->error("{{\"operation\":\"{}\",\"correlation_id\":\"{}\",\"error_code\":{},\"message\":\"{}\"}}",
                      operation, correlationId, errorCode, message);
    }
};
```

## Logging Message Templates

### Common Operation Templates

#### Key Generation Operations
```csharp
// Success
_logger.LogInformation("Key generation completed successfully: KeyId={KeyId}, KeyType={KeyType}, KeySize={KeySize}, Duration={DurationMs}ms",
    keyId, keyType, keySize, duration);

// Failure
_logger.LogError("Key generation failed: KeyId={KeyId}, KeyType={KeyType}, ErrorCode={ErrorCode}, ErrorMessage={ErrorMessage}",
    keyId, keyType, errorCode, errorMessage);

// Start
_logger.LogDebug("Starting key generation: KeyId={KeyId}, KeyType={KeyType}, KeySize={KeySize}, Algorithm={Algorithm}",
    keyId, keyType, keySize, algorithm);
```

#### Cryptographic Operations
```csharp
// Signing operations
_logger.LogInformation("Data signing completed: KeyId={KeyId}, Algorithm={Algorithm}, DataSize={DataSize}, SignatureSize={SignatureSize}, Duration={DurationMs}ms",
    keyId, algorithm, dataSize, signatureSize, duration);

// Verification operations
_logger.LogInformation("Signature verification completed: KeyId={KeyId}, Algorithm={Algorithm}, IsValid={IsValid}, Duration={DurationMs}ms",
    keyId, algorithm, isValid, duration);

// Encryption operations
_logger.LogInformation("Data encryption completed: KeyId={KeyId}, Algorithm={Algorithm}, PlaintextSize={PlaintextSize}, CiphertextSize={CiphertextSize}",
    keyId, algorithm, plaintextSize, ciphertextSize);
```

#### Service Lifecycle
```csharp
// Service startup
_logger.LogInformation("Supacrypt service starting: Version={Version}, Environment={Environment}, Configuration={@Configuration}",
    version, environment, configuration);

// Service ready
_logger.LogInformation("Supacrypt service ready: Host={Host}, Port={Port}, TLS={TlsEnabled}, Providers={@EnabledProviders}",
    host, port, tlsEnabled, enabledProviders);

// Service shutdown
_logger.LogInformation("Supacrypt service shutting down: Reason={Reason}, GracefulShutdown={Graceful}",
    reason, graceful);
```

#### Authentication and Authorization
```csharp
// Authentication success
_logger.LogInformation("Authentication successful: UserId={UserId}, Method={AuthMethod}, Duration={DurationMs}ms",
    userId, authMethod, duration);

// Authentication failure
_logger.LogWarning("Authentication failed: UserId={UserId}, Method={AuthMethod}, Reason={Reason}, ClientIp={ClientIp}",
    userId, authMethod, reason, clientIp);

// Authorization denied
_logger.LogWarning("Authorization denied: UserId={UserId}, Operation={Operation}, Resource={Resource}, Reason={Reason}",
    userId, operation, resource, reason);
```

### Provider-Specific Templates

#### PKCS#11 Provider
```cpp
// Session management
logger.LogInfo("OpenSession", correlationId, 
    "PKCS#11 session opened: SlotId={}, SessionHandle={}, Flags={}", 
    slotId, sessionHandle, flags);

// Key operations
logger.LogInfo("GenerateKeyPair", correlationId,
    "PKCS#11 key pair generated: Mechanism={}, PublicKeyHandle={}, PrivateKeyHandle={}", 
    mechanism, publicKeyHandle, privateKeyHandle);

// Cryptographic operations
logger.LogInfo("Sign", correlationId,
    "PKCS#11 signing completed: SessionHandle={}, KeyHandle={}, DataLength={}, SignatureLength={}", 
    sessionHandle, keyHandle, dataLength, signatureLength);
```

#### Windows CSP Provider
```c
// Provider context
log_info("AcquireContext", correlation_id,
    "CSP context acquired: ContainerName=%s, ProviderType=%d, Flags=%d",
    container_name, provider_type, flags);

// Key generation
log_info("GenKey", correlation_id,
    "CSP key generated: Algorithm=%d, KeySize=%d, Flags=%d, KeyHandle=%p",
    algorithm, key_size, flags, key_handle);

// Cryptographic operations
log_info("SignHash", correlation_id,
    "CSP hash signed: KeyHandle=%p, HashAlgorithm=%d, SignatureLength=%d",
    key_handle, hash_algorithm, signature_length);
```

#### Windows KSP Provider
```c
// Provider operations
log_info("OpenProvider", correlation_id,
    "KSP provider opened: ProviderName=%ws, Flags=%d",
    provider_name, flags);

// Key storage
log_info("CreatePersistedKey", correlation_id,
    "KSP persisted key created: KeyName=%ws, Algorithm=%ws, KeySize=%d",
    key_name, algorithm, key_size);

// Key operations
log_info("SecretAgreement", correlation_id,
    "KSP secret agreement completed: PrivateKeyHandle=%p, PublicKeyHandle=%p, SecretLength=%d",
    private_key_handle, public_key_handle, secret_length);
```

#### macOS CTK Provider
```objc
// Token operations
[logger logInfo:@"TokenOperation" correlationId:correlationId 
    message:@"CTK token operation: TokenID=%@, Operation=%@, Duration=%ldms",
    tokenId, operation, duration];

// Key management
[logger logInfo:@"KeyGeneration" correlationId:correlationId
    message:@"CTK key generated: KeyType=%@, KeySize=%ld, KeyTag=%@",
    keyType, keySize, keyTag];

// Keychain operations
[logger logInfo:@"KeychainAccess" correlationId:correlationId
    message:@"CTK keychain access: Operation=%@, ItemClass=%@, AccessGroup=%@",
    operation, itemClass, accessGroup];
```

## Sensitive Data Handling

### Data Classification
Never log the following sensitive information:

#### Prohibited Data
- Cryptographic private keys
- Symmetric encryption keys
- Digital signatures (raw bytes)
- Plaintext user data
- Passwords or PINs
- Authentication tokens
- Personal identifiable information (PII)

#### Allowed Data
- Key identifiers (non-sensitive)
- Algorithm names
- Key sizes and types
- Operation success/failure status
- Performance metrics
- Error codes and messages
- Correlation and request IDs

### Safe Logging Examples

#### Good Examples
```csharp
// Safe: Log key metadata without sensitive content
_logger.LogInformation("Key created: KeyId={KeyId}, Type={KeyType}, Size={KeySize}", 
    keyId, keyType, keySize);

// Safe: Log operation results without data
_logger.LogInformation("Encryption completed: InputSize={InputSize}, OutputSize={OutputSize}", 
    inputBytes.Length, outputBytes.Length);

// Safe: Log truncated identifiers
_logger.LogInformation("Processing key: KeyId={KeyId}", keyId.Substring(0, 8) + "...");
```

#### Bad Examples (Never Do This)
```csharp
// NEVER: Don't log private key material
_logger.LogDebug("Generated private key: {PrivateKey}", Convert.ToBase64String(privateKeyBytes));

// NEVER: Don't log user credentials
_logger.LogInformation("User authenticated: Username={Username}, Password={Password}", username, password);

// NEVER: Don't log raw signature data
_logger.LogDebug("Signature created: {Signature}", Convert.ToBase64String(signatureBytes));
```

### Data Sanitization
```csharp
public static class LogSanitizer
{
    public static string SanitizeKeyId(string keyId)
    {
        if (string.IsNullOrEmpty(keyId) || keyId.Length <= 8)
            return keyId;
            
        return $"{keyId.Substring(0, 4)}...{keyId.Substring(keyId.Length - 4)}";
    }
    
    public static string SanitizeUserData(string userData)
    {
        if (string.IsNullOrEmpty(userData))
            return userData;
            
        return $"[{userData.Length} bytes]";
    }
    
    public static object SanitizeRequest(object request)
    {
        // Use reflection or serialization to remove sensitive fields
        var sanitized = JsonSerializer.Deserialize<dynamic>(
            JsonSerializer.Serialize(request, _sanitizationOptions));
        return sanitized;
    }
}
```

## Performance and Operational Logging

### Performance Metrics
```csharp
public class PerformanceLogger
{
    private readonly ILogger _logger;
    private readonly IMetrics _metrics;
    
    public async Task<T> LogOperationAsync<T>(
        string operation, 
        string correlationId,
        Func<Task<T>> operationFunc,
        params (string key, object value)[] additionalContext)
    {
        using var activity = Activity.StartActivity(operation);
        var stopwatch = Stopwatch.StartNew();
        
        try
        {
            _logger.LogDebug("Starting operation: {Operation}, CorrelationId={CorrelationId}, Context={@Context}",
                operation, correlationId, additionalContext);
                
            var result = await operationFunc();
            
            stopwatch.Stop();
            
            _logger.LogInformation("Operation completed: {Operation}, Duration={DurationMs}ms, Success=true",
                operation, stopwatch.ElapsedMilliseconds);
                
            _metrics.Measure.Counter.Increment("supacrypt.operations.count", 
                new MetricTags("operation", operation, "result", "success"));
            _metrics.Measure.Histogram.Update("supacrypt.operations.duration", 
                stopwatch.ElapsedMilliseconds, new MetricTags("operation", operation));
                
            return result;
        }
        catch (Exception ex)
        {
            stopwatch.Stop();
            
            _logger.LogError(ex, "Operation failed: {Operation}, Duration={DurationMs}ms, ErrorType={ErrorType}",
                operation, stopwatch.ElapsedMilliseconds, ex.GetType().Name);
                
            _metrics.Measure.Counter.Increment("supacrypt.operations.count",
                new MetricTags("operation", operation, "result", "error"));
                
            throw;
        }
    }
}
```

### Health Check Logging
```csharp
public class HealthCheckLogger : IHealthCheck
{
    private readonly ILogger<HealthCheckLogger> _logger;
    
    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context, 
        CancellationToken cancellationToken = default)
    {
        var checks = new List<(string name, bool healthy, string details)>();
        
        // Check Key Vault connectivity
        var kvHealthy = await CheckKeyVaultAsync();
        checks.Add(("KeyVault", kvHealthy, kvHealthy ? "Connected" : "Connection failed"));
        
        // Check provider availability
        var providerHealthy = CheckProviderAvailability();
        checks.Add(("Providers", providerHealthy, providerHealthy ? "Available" : "Unavailable"));
        
        var allHealthy = checks.All(c => c.healthy);
        var status = allHealthy ? HealthStatus.Healthy : HealthStatus.Unhealthy;
        
        _logger.LogInformation("Health check completed: Status={Status}, Checks={@Checks}",
            status, checks);
            
        return new HealthCheckResult(status, "System health check", data: checks.ToDictionary(
            c => c.name, c => (object)new { healthy = c.healthy, details = c.details }));
    }
}
```

## Log Aggregation and Analysis

### Structured Query Examples

#### Finding Errors by Component
```json
{
  "query": {
    "bool": {
      "must": [
        { "term": { "level": "error" } },
        { "term": { "component": "supacrypt-backend" } },
        { "range": { "timestamp": { "gte": "now-1h" } } }
      ]
    }
  }
}
```

#### Tracking Operations by Correlation ID
```json
{
  "query": {
    "term": { "correlation_id": "12345678-1234-1234-1234-123456789012" }
  },
  "sort": [
    { "timestamp": { "order": "asc" } }
  ]
}
```

#### Performance Analysis
```json
{
  "query": {
    "bool": {
      "must": [
        { "term": { "operation": "GenerateKey" } },
        { "range": { "duration_ms": { "gte": 1000 } } }
      ]
    }
  },
  "aggs": {
    "avg_duration": { "avg": { "field": "duration_ms" } },
    "max_duration": { "max": { "field": "duration_ms" } }
  }
}
```

## Component-Specific Configuration

### Backend Service (.NET)
```csharp
public static class LoggingExtensions
{
    public static IServiceCollection AddSupacryptLogging(
        this IServiceCollection services, 
        IConfiguration configuration)
    {
        services.AddSerilog((serviceProvider, loggerConfiguration) =>
        {
            loggerConfiguration
                .ReadFrom.Configuration(configuration)
                .Enrich.FromLogContext()
                .Enrich.WithProperty("Component", "supacrypt-backend")
                .Enrich.WithProperty("Version", Assembly.GetExecutingAssembly().GetName().Version?.ToString())
                .Enrich.WithMachineName()
                .Enrich.WithProcessId()
                .Enrich.WithThreadId();
        });
        
        return services;
    }
    
    public static IApplicationBuilder UseSupacryptLogging(this IApplicationBuilder app)
    {
        app.UseSerilogRequestLogging(options =>
        {
            options.MessageTemplate = "HTTP {RequestMethod} {RequestPath} responded {StatusCode} in {Elapsed:0.0000} ms";
            options.EnrichDiagnosticContext = (diagnosticContext, httpContext) =>
            {
                diagnosticContext.Set("RequestHost", httpContext.Request.Host.Value);
                diagnosticContext.Set("RequestScheme", httpContext.Request.Scheme);
                diagnosticContext.Set("UserAgent", httpContext.Request.Headers["User-Agent"].ToString());
                
                if (httpContext.Request.Headers.TryGetValue("X-Correlation-ID", out var correlationId))
                {
                    diagnosticContext.Set("CorrelationId", correlationId.ToString());
                }
            };
        });
        
        return app;
    }
}
```

### PKCS#11 Provider (C++)
```cpp
class PKCS11Logger 
{
private:
    static std::unique_ptr<SupacryptLogger> instance_;
    
public:
    static void Initialize(const std::string& logPath = "/var/log/supacrypt/pkcs11.log")
    {
        instance_ = std::make_unique<SupacryptLogger>("supacrypt-pkcs11", logPath);
    }
    
    static void LogOperation(spdlog::level::level_enum level, 
                           const std::string& operation,
                           const std::string& correlationId,
                           const std::string& message,
                           const std::map<std::string, std::string>& context = {})
    {
        if (!instance_) return;
        
        nlohmann::json logEntry;
        logEntry["timestamp"] = std::chrono::system_clock::now();
        logEntry["level"] = spdlog::level::to_string_view(level);
        logEntry["component"] = "supacrypt-pkcs11";
        logEntry["operation"] = operation;
        logEntry["correlation_id"] = correlationId;
        logEntry["message"] = message;
        logEntry["process_id"] = getpid();
        logEntry["thread_id"] = std::this_thread::get_id();
        
        for (const auto& [key, value] : context)
        {
            logEntry[key] = value;
        }
        
        instance_->GetLogger()->log(level, logEntry.dump());
    }
};
```

## Monitoring and Alerting

### Log-Based Alerts
```yaml
# Example Prometheus alerting rules based on logs
groups:
- name: supacrypt.alerts
  rules:
  - alert: HighErrorRate
    expr: rate(log_entries_total{level="error"}[5m]) > 0.1
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: "High error rate detected in Supacrypt components"
      
  - alert: AuthenticationFailures
    expr: rate(log_entries_total{operation="authentication",level="warning"}[1m]) > 5
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Multiple authentication failures detected"
      
  - alert: KeyVaultConnectivity
    expr: log_entries_total{component="supacrypt-backend",message=~".*Key Vault.*failed.*"} > 0
    for: 0s
    labels:
      severity: critical
    annotations:
      summary: "Key Vault connectivity issues detected"
```

## Best Practices Summary

### Do's
1. Use structured logging with consistent field names
2. Include correlation IDs for request tracing
3. Log at appropriate levels based on event significance
4. Use parameterized log messages for better performance
5. Include sufficient context for debugging
6. Follow security guidelines for sensitive data
7. Use log aggregation and monitoring tools
8. Implement log retention policies

### Don'ts
1. Never log sensitive cryptographic material
2. Don't use string concatenation in log messages
3. Don't log at debug/trace level in production
4. Don't ignore logging configuration in deployment
5. Don't create excessive log volume
6. Don't expose internal implementation details
7. Don't rely solely on logs for monitoring
8. Don't forget to rotate and archive log files

## References

- [Structured Logging Best Practices](https://github.com/NLog/NLog/wiki/How-to-use-structured-logging)
- [Serilog Documentation](https://serilog.net/)
- [OpenTelemetry Logging](https://opentelemetry.io/docs/specs/otel/logs/)
- [Security Logging Guidelines](https://owasp.org/www-community/controls/Logging_Cheat_Sheet)
- [.NET Logging Best Practices](https://docs.microsoft.com/en-us/dotnet/core/extensions/logging-providers)
- [Elasticsearch Query DSL](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl.html)