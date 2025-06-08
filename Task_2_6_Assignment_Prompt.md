# Task Assignment: Create Comprehensive Test Suite

## Agent Profile
**Type:** Implementation Agent - QA Engineer  
**Expertise Required:** .NET Testing, xUnit, Moq, Integration Testing, Performance Testing, Test-Driven Development

## Task Overview
Develop complete testing coverage for the backend service including unit tests (targeting 100% coverage), integration tests with Azure Key Vault, performance benchmarks, load tests, and end-to-end gRPC client tests.

## Context
- **Repository:** `supacrypt-backend-akv`
- **Current State:** Service fully implemented with Azure Key Vault, mTLS, and observability
- **Target:** Production-ready test suite with comprehensive coverage
- **Testing Standards:** Follow guidelines from `supacrypt-common/docs/standards/testing-standards.md`

## Detailed Requirements

### 1. Unit Testing Infrastructure

#### Test Project Organization
```
tests/
├── Supacrypt.Backend.Tests/
│   ├── Services/
│   │   ├── SupacryptGrpcServiceTests.cs
│   │   ├── Azure/
│   │   │   ├── AzureKeyVaultClientFactoryTests.cs
│   │   │   ├── AzureKeyVaultCryptographicOperationsTests.cs
│   │   │   ├── AzureKeyVaultKeyManagementServiceTests.cs
│   │   │   ├── AzureKeyVaultKeyRepositoryTests.cs
│   │   │   └── AzureKeyVaultResiliencePolicyTests.cs
│   │   └── Security/
│   │       ├── CertificateValidationServiceTests.cs
│   │       ├── CertificateLoaderTests.cs
│   │       └── SecurityEventLoggerTests.cs
│   ├── Validation/
│   │   └── [All validator tests]
│   ├── ErrorHandling/
│   │   └── ErrorMapperTests.cs
│   ├── Middleware/
│   │   └── ClientCertificateAuthenticationMiddlewareTests.cs
│   └── TestHelpers/
│       ├── MockFactories.cs
│       ├── TestCertificates.cs
│       └── TestConstants.cs
```

#### Key Testing Patterns

##### Mock Azure Key Vault
```csharp
public class MockKeyClient : KeyClient
{
    private readonly Dictionary<string, KeyVaultKey> _keys = new();
    private readonly Mock<Response> _mockResponse;
    
    // Implement all KeyClient methods with in-memory behavior
    // Support configurable failure scenarios
}
```

##### Test Data Builders
```csharp
public class KeyRequestBuilder
{
    private GenerateKeyRequest _request = new();
    
    public KeyRequestBuilder WithAlgorithm(KeyAlgorithm algorithm) { ... }
    public KeyRequestBuilder WithKeySize(RSAKeySize size) { ... }
    public KeyRequestBuilder WithValidTags() { ... }
    public GenerateKeyRequest Build() => _request;
}
```

### 2. Service Layer Unit Tests

#### SupacryptGrpcServiceTests
Test all 8 gRPC methods with:
- Valid request scenarios
- Validation failure cases
- Service layer exception handling
- Authorization verification
- Correlation ID propagation
- Metrics and tracing verification

#### Azure Service Tests
For each Azure service implementation:
- Success path testing
- Azure SDK exception scenarios
- Retry policy verification
- Circuit breaker behavior
- Timeout handling
- Rate limiting responses

### 3. Integration Testing

#### Test Project Setup
```
tests/
└── Supacrypt.Backend.IntegrationTests/
    ├── Fixtures/
    │   ├── TestServerFixture.cs
    │   ├── AzureKeyVaultFixture.cs
    │   └── TestCertificateFixture.cs
    ├── GrpcIntegrationTests.cs
    ├── AzureKeyVaultIntegrationTests.cs
    ├── SecurityIntegrationTests.cs
    └── HealthCheckIntegrationTests.cs
```

#### TestServerFixture Implementation
```csharp
public class TestServerFixture : IAsyncLifetime
{
    public TestServer Server { get; private set; }
    public GrpcChannel Channel { get; private set; }
    public SupacryptService.SupacryptServiceClient Client { get; private set; }
    
    public async Task InitializeAsync()
    {
        var builder = new WebHostBuilder()
            .UseTestServer()
            .ConfigureServices(services =>
            {
                // Override with test implementations
                services.AddSingleton<IKeyClient>(new MockKeyClient());
            })
            .UseStartup<Startup>();
            
        Server = new TestServer(builder);
        // Configure gRPC client
    }
}
```

#### Integration Test Categories

##### Azure Key Vault Integration
- Real Key Vault operations (using test vault)
- Key lifecycle testing
- Permission validation
- Soft delete/purge scenarios
- Performance characteristics

##### Security Integration
- mTLS with test certificates
- Certificate validation scenarios
- Authorization policy testing
- Security event logging verification

##### End-to-End gRPC Tests
- Complete operation flows
- Error propagation
- Concurrent operations
- Long-running operations

### 4. Performance Testing

#### Benchmark Project
```
tests/
└── Supacrypt.Backend.Benchmarks/
    ├── CryptographicOperationsBenchmark.cs
    ├── KeyManagementBenchmark.cs
    ├── ValidationBenchmark.cs
    └── Program.cs
```

#### BenchmarkDotNet Implementation
```csharp
[MemoryDiagnoser]
[SimpleJob(RuntimeMoniker.Net90)]
public class CryptographicOperationsBenchmark
{
    private SupacryptService.SupacryptServiceClient _client;
    private SignDataRequest _signRequest;
    
    [GlobalSetup]
    public void Setup() { ... }
    
    [Benchmark]
    public async Task SignData_RSA2048() { ... }
    
    [Benchmark]
    public async Task SignData_ECDSAp256() { ... }
    
    [Benchmark]
    public async Task VerifySignature_RSA2048() { ... }
}
```

#### Performance Targets
- Sign operation: < 50ms (excluding Azure latency)
- Verify operation: < 30ms
- Key generation: < 200ms
- List operations: < 100ms for 100 keys

### 5. Load Testing

#### NBomber Load Tests
```csharp
public class LoadTestScenarios
{
    public static Scenario CryptoOperationsScenario()
    {
        return Scenario.Create("crypto_operations", async context =>
        {
            // Mix of operations simulating real usage
            var random = new Random();
            switch (random.Next(4))
            {
                case 0: return await GenerateKey(context);
                case 1: return await SignData(context);
                case 2: return await VerifySignature(context);
                case 3: return await ListKeys(context);
            }
        })
        .WithLoadSimulations(
            Simulation.InjectPerSec(rate: 100, during: TimeSpan.FromMinutes(5)),
            Simulation.KeepConstant(copies: 50, during: TimeSpan.FromMinutes(10))
        );
    }
}
```

#### Load Test Metrics
- Throughput (operations/second)
- Response time percentiles (P50, P95, P99)
- Error rates under load
- Resource utilization
- Connection pool efficiency

### 6. Test Helpers and Utilities

#### Mock Factories
```csharp
public static class MockFactories
{
    public static Mock<IKeyClient> CreateKeyClient(params KeyVaultKey[] keys)
    {
        var mock = new Mock<IKeyClient>();
        // Configure common scenarios
        return mock;
    }
    
    public static X509Certificate2 CreateTestCertificate(
        string subject, 
        bool isValid = true,
        X509KeyUsageFlags usage = X509KeyUsageFlags.DigitalSignature)
    {
        // Generate test certificates
    }
}
```

#### Test Constants
```csharp
public static class TestConstants
{
    public const string TestKeyId = "test-key-12345678";
    public const string TestVaultUri = "https://test-vault.vault.azure.net/";
    public static readonly byte[] TestData = Encoding.UTF8.GetBytes("test data");
    
    public static class ErrorMessages
    {
        public const string InvalidKeyAlgorithm = "Unsupported key algorithm";
        // Other standard error messages
    }
}
```

### 7. Test Configuration

#### Test Settings
```json
// testsettings.json
{
  "AzureKeyVault": {
    "VaultUri": "https://supacrypt-test.vault.azure.net/",
    "UseManagedIdentity": false,
    "ClientId": "test-client-id",
    "TenantId": "test-tenant-id"
  },
  "TestOptions": {
    "UseRealAzureKeyVault": false,
    "EnablePerformanceTests": true,
    "LoadTestDuration": "00:05:00"
  }
}
```

### 8. Code Coverage Requirements

#### Minimum Coverage Targets
- Overall: 80% line coverage
- Critical paths: 100% coverage
  - gRPC service methods
  - Azure Key Vault operations
  - Security validation
  - Error handling paths

#### Coverage Exclusions
- Generated code (protobuf)
- Startup/configuration code
- Simple DTOs/POCOs
- Test code itself

### 9. Testing Best Practices

#### Test Organization
- Arrange-Act-Assert pattern
- One assertion per test (when practical)
- Descriptive test names: `MethodName_StateUnderTest_ExpectedBehavior`
- Use test categories for organization

#### Async Testing
```csharp
[Fact]
public async Task SignData_WithValidRequest_ReturnsSignature()
{
    // Proper async/await usage
    var result = await _service.SignDataAsync(request);
    
    // Avoid .Result or .Wait()
    Assert.NotNull(result.Success);
}
```

#### Exception Testing
```csharp
[Fact]
public async Task GenerateKey_WithInvalidAlgorithm_ThrowsRpcException()
{
    var exception = await Assert.ThrowsAsync<RpcException>(
        async () => await _client.GenerateKeyAsync(invalidRequest));
        
    Assert.Equal(StatusCode.InvalidArgument, exception.StatusCode);
    Assert.Contains("Unsupported algorithm", exception.Status.Detail);
}
```

### 10. Continuous Integration

#### Test Execution Strategy
```yaml
# In CI pipeline
- name: Unit Tests
  run: dotnet test tests/Supacrypt.Backend.Tests --collect:"XPlat Code Coverage"
  
- name: Integration Tests
  run: dotnet test tests/Supacrypt.Backend.IntegrationTests
  env:
    AZURE_CLIENT_ID: $(AZURE_CLIENT_ID)
    
- name: Performance Tests
  run: dotnet run -c Release --project tests/Supacrypt.Backend.Benchmarks
  if: github.event_name == 'pull_request'
```

## Implementation Steps

1. **Create Test Infrastructure**
   - Set up test projects with proper references
   - Create mock factories and test helpers
   - Configure test settings

2. **Implement Unit Tests**
   - Start with service layer tests
   - Add validation tests
   - Cover error handling scenarios

3. **Create Integration Tests**
   - Set up test fixtures
   - Implement end-to-end scenarios
   - Add security integration tests

4. **Add Performance Tests**
   - Create benchmarks for critical paths
   - Implement load test scenarios
   - Establish performance baselines

5. **Ensure Coverage**
   - Run coverage analysis
   - Fill gaps in critical paths
   - Document exclusions

## Validation Criteria
Your implementation will be considered complete when:
1. ✅ Unit test coverage ≥ 80% overall, 100% for critical paths
2. ✅ All integration tests passing with test Azure Key Vault
3. ✅ Performance benchmarks established and documented
4. ✅ Load tests demonstrate stability under expected load
5. ✅ Test helpers and utilities reduce code duplication
6. ✅ CI-ready test execution configuration
7. ✅ Clear test documentation and examples
8. ✅ Mock implementations support all test scenarios

## Important Notes
- Use dependency injection to enable testability
- Avoid testing implementation details, focus on behavior
- Keep tests maintainable and readable
- Document any flaky tests with mitigation strategies
- Consider test data privacy (no real keys/certificates)

## Memory Bank Logging
Document your work in `supacrypt-common/Memory/Phase_2_Backend_Service/Task_2_6_Testing_Suite_Log.md` following the established format. Include:
- Test coverage metrics
- Performance benchmark results
- Any testing challenges encountered
- Load test results and analysis
- Recommendations for ongoing testing

Begin by setting up the test project structure and implementing the core test infrastructure.