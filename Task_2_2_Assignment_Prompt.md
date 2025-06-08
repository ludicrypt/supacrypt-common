# Task 2.2: Implement Core gRPC Service

## Task Overview
**Task ID**: 2.2  
**Task Name**: Backend Core Implementation  
**Assigned To**: Implementation Agent (Backend Developer)  
**Prerequisite**: Task 2.1 (Backend Project Structure) completed  
**Created**: 2025-01-07  

## Objective
Implement the core gRPC service for the Supacrypt backend, generating C# code from the protobuf definitions and creating a fully functional service layer with proper dependency injection, request validation, error handling, and comprehensive logging. This implementation will establish the foundation for Azure Key Vault integration in Task 2.3.

## Context
The project structure has been established in Task 2.1 with .NET 9, Aspire 9.3, and all necessary packages configured. The protobuf definition (`supacrypt.proto`) in `supacrypt-common/proto/` defines the complete gRPC service interface. Your task is to bring this service to life with production-ready code that follows established standards and patterns.

## Key Requirements

### 1. Generate C# Code from Protobuf
- Configure the project to automatically generate C# classes from `supacrypt.proto`
- Ensure the generated code is properly integrated into the build process
- Set up appropriate namespaces (Supacrypt.Backend.Grpc)
- Configure protobuf compilation in the .csproj file

### 2. Implement gRPC Service Interface
Create the main gRPC service implementation class that inherits from the generated base class:
- Implement all 8 service methods defined in the proto file:
  - GenerateKey
  - SignData
  - VerifySignature
  - GetKey
  - ListKeys
  - DeleteKey
  - EncryptData
  - DecryptData
- Use proper dependency injection for all service dependencies
- Implement proper async/await patterns with ConfigureAwait(false)
- Ensure cancellation token propagation throughout the call stack

### 3. Service Registration and Configuration
- Create service registration extensions for dependency injection
- Configure gRPC service options (max message size, interceptors, etc.)
- Set up service health checks
- Implement proper service lifetime management (Scoped/Singleton as appropriate)
- Configure gRPC reflection for development environments

### 4. Request Validation and Error Handling
Implement comprehensive request validation using FluentValidation:
- Create validators for each request type
- Validate algorithm compatibility
- Validate key sizes and parameters
- Validate data size limits
- Implement proper error mapping from protobuf error codes to gRPC status codes
- Create custom exceptions for different error scenarios
- Follow the error code ranges defined in the error-handling-guide.md:
  - Backend service errors: 1000-1999
  - Use appropriate sub-ranges for different error types

### 5. Comprehensive Logging
Implement structured logging following the logging standards:
- Use Serilog with JSON formatting
- Include correlation IDs for all operations
- Log operation start, success, and failure
- Include appropriate context (KeyId, Algorithm, Operation, Duration)
- Never log sensitive cryptographic material
- Use appropriate log levels (Debug, Information, Warning, Error, Critical)
- Implement performance logging with operation duration tracking

### 6. Service Abstractions for Azure Key Vault
Create interfaces and mock implementations for cryptographic operations:
- `IKeyManagementService` for key lifecycle operations
- `ICryptographicOperations` for signing/encryption operations
- `IKeyRepository` for key metadata storage
- Mock implementations that simulate operations without actual cryptography
- Prepare for circuit breaker patterns (using Polly)
- Design interfaces to support async operations with cancellation

### 7. Implementation Details

#### Service Structure
```csharp
namespace Supacrypt.Backend.Services
{
    public class SupacryptGrpcService : SupacryptService.SupacryptServiceBase
    {
        private readonly IKeyManagementService _keyManagementService;
        private readonly ICryptographicOperations _cryptographicOperations;
        private readonly IKeyRepository _keyRepository;
        private readonly ILogger<SupacryptGrpcService> _logger;
        private readonly IValidator<GenerateKeyRequest> _generateKeyValidator;
        // ... other validators and dependencies
    }
}
```

#### Mock Implementation Guidelines
- Mock services should return realistic responses
- Simulate operation delays (50-200ms for key operations)
- Store key metadata in memory for the mock repository
- Generate fake public keys using deterministic algorithms
- Implement error scenarios for testing (configurable failure rates)

#### Circuit Breaker Preparation
- Design service interfaces to support Polly policies
- Include retry logic placeholders
- Prepare for timeout handling
- Structure code to easily add circuit breakers in Task 2.3

## Specific Implementation Tasks

### 1. Protobuf Integration
- Copy `supacrypt.proto` to `src/Supacrypt.Backend/Protos/`
- Configure .csproj with proper Protobuf includes
- Set GrpcServices="Server" for server-side generation
- Verify successful code generation during build

### 2. Service Implementation Files to Create
- `Services/SupacryptGrpcService.cs` - Main gRPC service implementation
- `Services/Interfaces/IKeyManagementService.cs` - Key management abstraction
- `Services/Interfaces/ICryptographicOperations.cs` - Crypto operations abstraction
- `Services/Interfaces/IKeyRepository.cs` - Key storage abstraction
- `Services/Mock/MockKeyManagementService.cs` - Mock implementation
- `Services/Mock/MockCryptographicOperations.cs` - Mock implementation
- `Services/Mock/MockKeyRepository.cs` - Mock implementation

### 3. Validation Files to Create
- `Validation/GenerateKeyRequestValidator.cs`
- `Validation/SignDataRequestValidator.cs`
- `Validation/VerifySignatureRequestValidator.cs`
- `Validation/GetKeyRequestValidator.cs`
- `Validation/ListKeysRequestValidator.cs`
- `Validation/DeleteKeyRequestValidator.cs`
- `Validation/EncryptDataRequestValidator.cs`
- `Validation/DecryptDataRequestValidator.cs`
- `Validation/ValidationExtensions.cs` - Common validation logic

### 4. Error Handling Files to Create
- `Exceptions/KeyManagementException.cs`
- `Exceptions/CryptographicOperationException.cs`
- `Exceptions/ValidationException.cs`
- `ErrorHandling/ErrorMapper.cs` - Maps errors to gRPC status codes
- `ErrorHandling/ErrorResponseBuilder.cs` - Builds error responses

### 5. Models and DTOs
- `Models/KeyMetadata.cs` - Internal key metadata model
- `Models/OperationContext.cs` - Operation context with correlation ID
- `Models/CryptographicResult.cs` - Result wrapper for operations

### 6. Logging and Telemetry
- `Logging/LoggingExtensions.cs` - Structured logging helpers
- `Logging/OperationLogger.cs` - Operation-specific logging
- `Telemetry/PerformanceTracker.cs` - Performance metrics tracking

### 7. Update Program.cs
- Register all services with proper lifetimes
- Configure gRPC with appropriate options
- Set up request logging middleware
- Configure health checks
- Enable gRPC reflection for development

## Standards and Guidelines to Follow

### C# Coding Standards (from csharp-coding-standards.md)
- Use 4 spaces for indentation
- K&R brace style
- Async methods suffixed with 'Async'
- Use nullable reference types
- Follow .NET naming conventions
- Implement proper disposal patterns
- Use ConfigureAwait(false) in library code

### Error Handling (from error-handling-guide.md)
- Backend service errors: 1000-1999
- Include correlation IDs in all errors
- Map to appropriate gRPC status codes
- Log errors with appropriate context
- Never expose internal implementation details

### Logging Standards (from logging-standards.md)
- Use structured JSON logging
- Include required fields: timestamp, level, component, operation, correlation_id
- Follow log level guidelines
- Never log sensitive cryptographic material
- Include operation duration for performance tracking

## Deliverables

1. **Fully implemented gRPC service** with all 8 methods
2. **Complete validation layer** using FluentValidation
3. **Comprehensive error handling** with proper error mapping
4. **Mock service implementations** for testing
5. **Structured logging** throughout the codebase
6. **Updated Program.cs** with all service registrations
7. **Service runs successfully** and responds to health checks
8. **Memory Bank log entry** documenting implementation progress

## Success Criteria

- [ ] All protobuf code generates successfully
- [ ] All 8 gRPC methods are implemented
- [ ] Request validation works for all operations
- [ ] Error handling follows the error code standards
- [ ] Logging includes correlation IDs and proper structure
- [ ] Mock services return realistic responses
- [ ] Service starts and responds to health checks
- [ ] Code follows C# coding standards
- [ ] All async operations use proper patterns
- [ ] Cancellation tokens are propagated correctly
- [ ] No build warnings related to nullable references
- [ ] XML documentation is complete for public APIs

## Testing Approach

While comprehensive testing will be in Task 2.6, ensure basic functionality:
- Service starts without errors
- Health check endpoint responds
- Each gRPC method can be called (returns mock data)
- Validation rejects invalid requests
- Errors are properly mapped to gRPC status codes
- Logs are properly structured and written

## Important Notes

1. **Do NOT implement actual Azure Key Vault integration** - use mock implementations
2. **Do NOT implement real cryptographic operations** - return simulated results
3. **Focus on the service structure and patterns** that will support real implementation
4. **Prepare interfaces for circuit breaker patterns** but don't implement them yet
5. **Use correlation IDs consistently** for request tracking
6. **Follow the established project structure** from Task 2.1

## Memory Bank Requirements

Create detailed log entries in `/Users/ludicrypt/Dev/supacrypt/supacrypt-common/Memory/Phase_2_Backend_Service/Task_2_2_Core_Implementation_Log.md` documenting:
- Protobuf integration approach
- Service implementation decisions
- Validation strategy
- Error handling patterns
- Mock implementation design
- Any challenges encountered
- Deviations from the plan
- Next steps for Task 2.3

## Example Code Snippets

### gRPC Service Method Example
```csharp
public override async Task<GenerateKeyResponse> GenerateKey(
    GenerateKeyRequest request,
    ServerCallContext context)
{
    var correlationId = GetOrCreateCorrelationId(context);
    using var activity = Activity.StartActivity("GenerateKey");
    
    try
    {
        _logger.LogInformation("Starting key generation: CorrelationId={CorrelationId}, KeyName={KeyName}, Algorithm={Algorithm}",
            correlationId, request.Name, request.Algorithm);
            
        await _generateKeyValidator.ValidateAndThrowAsync(request, context.CancellationToken)
            .ConfigureAwait(false);
            
        var result = await _keyManagementService.GenerateKeyAsync(
            request, 
            correlationId, 
            context.CancellationToken)
            .ConfigureAwait(false);
            
        _logger.LogInformation("Key generation completed: CorrelationId={CorrelationId}, KeyId={KeyId}, Duration={Duration}ms",
            correlationId, result.KeyId, activity.Duration.TotalMilliseconds);
            
        return new GenerateKeyResponse
        {
            Success = new GenerateKeySuccess
            {
                Metadata = result.Metadata,
                PublicKey = result.PublicKey
            }
        };
    }
    catch (ValidationException ex)
    {
        _logger.LogWarning(ex, "Validation failed for key generation: CorrelationId={CorrelationId}", correlationId);
        throw new RpcException(new Status(StatusCode.InvalidArgument, ex.Message));
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Key generation failed: CorrelationId={CorrelationId}", correlationId);
        throw new RpcException(new Status(StatusCode.Internal, "Key generation failed"));
    }
}
```

## Getting Started

1. Review the protobuf definition in `supacrypt-common/proto/supacrypt.proto`
2. Review the C# coding standards and error handling guide
3. Set up the protobuf compilation in the project
4. Create the service interfaces first
5. Implement mock services
6. Build the gRPC service implementation
7. Add validation and error handling
8. Implement comprehensive logging
9. Update Program.cs with all registrations
10. Test the service startup and basic operations

Remember: This task establishes the foundation for the entire backend service. Take time to get the structure right, as future tasks will build upon this implementation.