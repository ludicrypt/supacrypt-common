# Task Assignment: Create .NET Aspire Project Structure

## Agent Profile
**Type:** Implementation Agent - .NET Specialist  
**Expertise Required:** .NET 9, .NET Aspire 9.3, C# 13, gRPC services, Azure SDK experience

## Task Overview
You are tasked with initializing the .NET Aspire 9.3 worker service project structure for `supacrypt-backend-akv`. This service will act as the central cryptographic operations hub, delegating operations to Azure Key Vault and exposing them via gRPC to all Supacrypt crypto providers.

## Context
- **Repository:** `supacrypt-backend-akv`
- **Project Type:** .NET Aspire 9.3 Worker Service with gRPC
- **Purpose:** Backend service that implements the gRPC interface defined in `supacrypt-common/proto/supacrypt.proto`
- **Key Technologies:** .NET 9, C# 13, .NET Aspire, gRPC, Azure Key Vault SDK
- **Standards:** Follow the C# coding standards established in `supacrypt-common/docs/standards/csharp-coding-standards.md`

## Detailed Requirements

### 1. Solution and Project Structure
Create a well-organized .NET solution with the following structure:
```
supacrypt-backend-akv/
├── src/
│   ├── Supacrypt.Backend/
│   │   ├── Supacrypt.Backend.csproj
│   │   ├── Program.cs
│   │   ├── appsettings.json
│   │   ├── appsettings.Development.json
│   │   ├── Services/
│   │   ├── Configuration/
│   │   ├── Extensions/
│   │   └── Protos/
│   └── Supacrypt.Backend.AppHost/
│       ├── Supacrypt.Backend.AppHost.csproj
│       └── Program.cs
├── tests/
│   ├── Supacrypt.Backend.Tests/
│   │   └── Supacrypt.Backend.Tests.csproj
│   └── Supacrypt.Backend.IntegrationTests/
│       └── Supacrypt.Backend.IntegrationTests.csproj
├── Supacrypt.Backend.sln
├── Directory.Build.props
├── Directory.Packages.props
└── global.json
```

### 2. Project Configuration

#### Supacrypt.Backend.csproj
- Target framework: net9.0
- Enable nullable reference types
- Enable implicit usings
- Configure as .NET Aspire Worker Service
- Enable gRPC service support
- Copy protobuf file from supacrypt-common

#### Required NuGet Packages
Include these packages with appropriate version constraints:
- **Core Aspire packages:**
  - Aspire.Hosting.AppHost (9.3.*)
  - Aspire.Hosting (9.3.*)
  
- **gRPC packages:**
  - Grpc.AspNetCore (2.*)
  - Grpc.Tools (2.*)
  - Google.Protobuf (3.*)
  
- **Azure packages:**
  - Azure.Security.KeyVault.Keys (4.*)
  - Azure.Identity (1.*)
  - Azure.Extensions.AspNetCore.Configuration.Secrets (1.*)
  
- **Observability packages:**
  - OpenTelemetry.Exporter.OpenTelemetryProtocol (1.*)
  - OpenTelemetry.Extensions.Hosting (1.*)
  - OpenTelemetry.Instrumentation.AspNetCore (1.*)
  - OpenTelemetry.Instrumentation.GrpcNetClient (1.*)
  - OpenTelemetry.Instrumentation.Http (1.*)
  
- **Testing packages (for test projects):**
  - Microsoft.NET.Test.Sdk (17.*)
  - xUnit (2.*)
  - xUnit.runner.visualstudio (2.*)
  - Moq (4.*)
  - FluentAssertions (6.*)

### 3. Configuration Structure

#### appsettings.json
```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning",
      "Grpc": "Information"
    }
  },
  "Kestrel": {
    "EndpointDefaults": {
      "Protocols": "Http2"
    }
  },
  "AzureKeyVault": {
    "VaultUri": "",
    "ClientId": "",
    "TenantId": "",
    "RetryOptions": {
      "MaxRetries": 3,
      "Delay": "00:00:02",
      "MaxDelay": "00:00:16",
      "Mode": "Exponential"
    }
  },
  "Security": {
    "mTLS": {
      "Enabled": true,
      "RequireClientCertificate": true,
      "ValidationMode": "ChainTrust",
      "AllowedThumbprints": []
    }
  },
  "OpenTelemetry": {
    "ServiceName": "supacrypt-backend",
    "ServiceVersion": "1.0.0",
    "Otlp": {
      "Endpoint": "http://localhost:4317"
    }
  }
}
```

#### appsettings.Development.json
Override with development-specific settings, including disabled mTLS for local testing.

### 4. Initial Code Structure

#### Program.cs
- Configure .NET Aspire integration
- Set up dependency injection container
- Configure gRPC services
- Add OpenTelemetry configuration
- Configure health checks
- Set up proper host configuration

#### Service Structure
Create placeholder folders and interfaces:
- `Services/` - For gRPC service implementations
- `Services/Interfaces/` - Service contracts
- `Configuration/` - Configuration models and options
- `Extensions/` - Service collection extensions
- `Protos/` - Location for protobuf files (copied from common)

### 5. Build Configuration

#### Directory.Build.props
Set common properties:
- Company and product information
- Version properties
- Code analysis settings
- Nullable reference types
- Warning as errors for release builds

#### Directory.Packages.props
Configure central package management with all package versions.

#### global.json
Pin .NET SDK version to ensure consistency:
```json
{
  "sdk": {
    "version": "9.0.100",
    "rollForward": "latestMinor"
  }
}
```

### 6. Protobuf Integration
- Copy `supacrypt.proto` from `supacrypt-common/proto/` to `src/Supacrypt.Backend/Protos/`
- Configure automatic code generation in the project file
- Set up proper namespace for generated code

### 7. Documentation
Update the existing README.md with:
- Build instructions
- Configuration requirements
- Development setup guide
- Dependencies list

## Validation Criteria
Your implementation will be considered complete when:
1. Solution builds successfully with `dotnet build`
2. All projects are properly referenced
3. Package restore completes without errors
4. Basic project runs with `dotnet run` (even if just showing startup logs)
5. Test projects are properly configured
6. Protobuf compilation is configured (even if service not yet implemented)

## Important Notes
- Do NOT implement actual service logic - only create the project structure
- Ensure all configuration is environment-driven (no hardcoded values)
- Follow the established C# coding standards from the documentation
- Use consistent naming following .NET conventions
- Prepare the structure for future mTLS implementation but don't implement it yet

## Memory Bank Logging
Document your work in `supacrypt-common/Memory/Phase_2_Backend_Service/Task_2_1_Project_Structure_Log.md` following the established format. Include:
- Exact commands used to create projects
- Package versions selected and rationale
- Any deviations from the plan and why
- Configuration decisions made
- Next steps for Task 2.2

Begin by examining the existing repository structure and the protobuf definition, then proceed with the implementation.