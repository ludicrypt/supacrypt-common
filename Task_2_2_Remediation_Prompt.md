# Task Assignment: Fix Task 2.2 Build Errors and Complete Implementation

## Agent Profile
**Type:** Implementation Agent - Backend Developer  
**Expertise Required:** .NET 9, gRPC, Protocol Buffers, C# 13

## Task Overview
Task 2.2 (Backend Core Implementation) has been partially implemented but contains build errors that prevent compilation. Your task is to fix these errors and ensure the gRPC service builds and runs successfully.

## Current State Analysis
The implementation includes:
- ✅ Full gRPC service implementation with all 8 RPC methods
- ✅ Service interfaces (ICryptographicOperations, IKeyManagementService, IKeyRepository)
- ✅ Mock implementations for all services
- ✅ Request validation using FluentValidation
- ✅ Error handling and logging infrastructure
- ❌ Build errors preventing compilation
- ❌ Missing gRPC reflection package
- ❌ Enum naming mismatches between protobuf and C# code

## Critical Issues to Fix

### 1. Enum Naming Mismatch
The protobuf file uses UPPER_SNAKE_CASE for enum values, but the C# code expects PascalCase. This affects:
- `KeyAlgorithm` enum (e.g., `KEY_ALGORITHM_RSA` vs `KeyAlgorithmRsa`)
- `RSAKeySize` enum (e.g., `RSA_KEY_SIZE_2048` vs `RsaKeySize2048`)
- `ECCurve` enum (e.g., `EC_CURVE_P256` vs `EcCurveP256`)
- `HashAlgorithm` enum (e.g., `HASH_ALGORITHM_SHA256` vs `HashAlgorithmSha256`)
- `ErrorCode` enum (e.g., `ERROR_CODE_INVALID_REQUEST` vs `ErrorCodeInvalidRequest`)

### 2. Missing Package Reference
Add the gRPC reflection package to `Supacrypt.Backend.csproj`:
```xml
<PackageReference Include="Grpc.AspNetCore.Server.Reflection" />
```

### 3. Service Registration
Ensure gRPC reflection is properly registered in `Program.cs`:
```csharp
builder.Services.AddGrpcReflection();
```

## Required Actions

### Step 1: Fix Protobuf Code Generation
Update the protobuf compilation settings in `Supacrypt.Backend.csproj` to ensure proper C# naming conventions:
```xml
<Protobuf Include="Protos\supacrypt.proto" GrpcServices="Server">
  <Generator>MSBuild:Compile</Generator>
  <OutputDir>Generated</OutputDir>
  <CompileOutputs>true</CompileOutputs>
</Protobuf>
```

### Step 2: Update All Enum References
Review and update all files that reference protobuf enums to use the correct generated names. Key files to check:
- `Services/SupacryptGrpcService.cs`
- `Services/Implementations/MockCryptographicOperations.cs`
- `Services/Implementations/MockKeyManagementService.cs`
- `Services/Implementations/MockKeyRepository.cs`
- `Infrastructure/ErrorMapper.cs`
- `Validation/*Validator.cs` files

### Step 3: Add Missing Package
Update the central package management in `Directory.Packages.props` to include:
```xml
<PackageVersion Include="Grpc.AspNetCore.Server.Reflection" Version="2.71.0" />
```

### Step 4: Verify Generated Code
After fixing the protobuf settings:
1. Clean the solution: `dotnet clean`
2. Regenerate protobuf code: `dotnet build`
3. Check the generated code in `obj/Debug/net9.0/Protos/` to verify enum naming

### Step 5: Update Service Registration
Ensure `ServiceCollectionExtensions.cs` includes gRPC reflection registration.

### Step 6: Run Build Validation
Execute these commands to verify fixes:
```bash
dotnet restore
dotnet build
dotnet test
dotnet run --project src/Supacrypt.Backend/Supacrypt.Backend.csproj
```

## Validation Criteria
Your fixes will be considered complete when:
1. ✅ Solution builds without errors (`dotnet build` succeeds)
2. ✅ All unit tests pass (`dotnet test` succeeds)
3. ✅ Service starts successfully and listens on configured port
4. ✅ gRPC reflection is working (can be tested with grpcurl)
5. ✅ Health checks respond successfully at `/health` and `/health/ready`

## Additional Tasks

### Update Memory Bank Log
Update `supacrypt-common/Memory/Phase_2_Backend_Service/Task_2_2_Core_Implementation_Log.md` with:
- Status change from PENDING to COMPLETED
- Summary of implementation work done
- List of build issues encountered and fixed
- Validation results
- Any remaining considerations for Task 2.3

### Code Quality Checks
Ensure the fixed code maintains:
- Proper async/await patterns throughout
- Comprehensive XML documentation on public methods
- Structured logging with appropriate log levels
- Consistent error handling using the established error codes (1000-1999)
- Adherence to C# coding standards

## Important Notes
- Do NOT modify the protobuf file itself - work with the generated code
- Maintain all existing functionality while fixing build errors
- Keep mock implementations as-is (Azure Key Vault integration is Task 2.3)
- Ensure backward compatibility with the protobuf contract

Begin by analyzing the current build errors with `dotnet build` and systematically address each issue.