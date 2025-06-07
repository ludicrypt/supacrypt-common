# Testing Standards for Supacrypt Components

## Overview

This document establishes comprehensive testing standards and approaches for all Supacrypt components to ensure reliability, security, and maintainability across the cryptographic software suite.

## Test Organization and Naming

### Test Naming Conventions
Use descriptive names that clearly indicate the test purpose and expected outcome:

```csharp
// Pattern: [MethodName]_[Scenario]_[ExpectedBehavior]
public class KeyManagementServiceTests
{
    [Test]
    public void GenerateKey_WithValidRsaParameters_ShouldReturnSuccessfulResult()
    
    [Test]
    public void GenerateKey_WithInvalidKeySize_ShouldThrowValidationException()
    
    [Test]
    public void GenerateKey_WhenKeyVaultUnavailable_ShouldRetryAndEventuallyFail()
    
    [Test]
    public void SignData_WithValidKeyAndData_ShouldProduceValidSignature()
    
    [Test]
    public void SignData_WithNonExistentKey_ShouldReturnKeyNotFoundError()
}
```

### Test Organization Structure

#### .NET Backend Service Testing
```
supacrypt-backend/
├── tests/
│   ├── Supacrypt.Backend.UnitTests/
│   │   ├── Services/
│   │   │   ├── CryptographicServiceTests.cs
│   │   │   ├── KeyManagementServiceTests.cs
│   │   │   └── AuthenticationServiceTests.cs
│   │   ├── Controllers/
│   │   │   ├── KeysControllerTests.cs
│   │   │   └── HealthControllerTests.cs
│   │   ├── Validators/
│   │   └── Helpers/
│   ├── Supacrypt.Backend.IntegrationTests/
│   │   ├── GrpcServices/
│   │   ├── KeyVault/
│   │   ├── Database/
│   │   └── EndToEnd/
│   └── Supacrypt.Backend.PerformanceTests/
│       ├── LoadTests/
│       ├── StressTests/
│       └── Benchmarks/
```

#### C++ Native Provider Testing
```
supacrypt-pkcs11/
├── tests/
│   ├── unit/
│   │   ├── test_session_management.cpp
│   │   ├── test_key_generation.cpp
│   │   ├── test_cryptographic_operations.cpp
│   │   └── test_error_handling.cpp
│   ├── integration/
│   │   ├── test_pkcs11_compliance.cpp
│   │   ├── test_backend_integration.cpp
│   │   └── test_platform_compatibility.cpp
│   ├── performance/
│   │   ├── benchmark_key_operations.cpp
│   │   └── benchmark_crypto_operations.cpp
│   └── compliance/
│       ├── pkcs11_conformance_tests.cpp
│       └── security_validation_tests.cpp
```

## Unit Testing Standards

### Test Coverage Requirements
- **Minimum coverage**: 80% line coverage across all components
- **Critical path coverage**: 95% for cryptographic operations
- **Error handling coverage**: 90% for all exception scenarios
- **Public API coverage**: 100% for all public methods and properties

### Unit Test Structure
Follow the Arrange-Act-Assert (AAA) pattern consistently:

```csharp
[TestFixture]
public class CryptographicServiceTests
{
    private Mock<IKeyVaultClient> _mockKeyVaultClient;
    private Mock<ILogger<CryptographicService>> _mockLogger;
    private CryptographicService _service;
    
    [SetUp]
    public void Setup()
    {
        _mockKeyVaultClient = new Mock<IKeyVaultClient>();
        _mockLogger = new Mock<ILogger<CryptographicService>>();
        _service = new CryptographicService(_mockKeyVaultClient.Object, _mockLogger.Object);
    }
    
    [Test]
    public async Task GenerateRsaKey_WithValidParameters_ShouldReturnGeneratedKey()
    {
        // Arrange
        var request = new GenerateKeyRequest
        {
            KeyId = "test-rsa-key",
            KeyType = KeyType.Rsa,
            KeySize = 2048
        };
        
        var expectedKey = new KeyVaultKey("test-rsa-key", KeyType.Rsa);
        _mockKeyVaultClient
            .Setup(x => x.CreateRsaKeyAsync(request.KeyId, request.KeySize, It.IsAny<CancellationToken>()))
            .ReturnsAsync(expectedKey);
        
        // Act
        var result = await _service.GenerateKeyAsync(request);
        
        // Assert
        Assert.That(result.Success, Is.True);
        Assert.That(result.KeyId, Is.EqualTo(request.KeyId));
        Assert.That(result.KeyType, Is.EqualTo(KeyType.Rsa));
        
        _mockKeyVaultClient.Verify(
            x => x.CreateRsaKeyAsync(request.KeyId, request.KeySize, It.IsAny<CancellationToken>()),
            Times.Once);
    }
    
    [Test]
    public void GenerateRsaKey_WithInvalidKeySize_ShouldThrowValidationException()
    {
        // Arrange
        var request = new GenerateKeyRequest
        {
            KeyId = "test-rsa-key",
            KeyType = KeyType.Rsa,
            KeySize = 1024 // Invalid size
        };
        
        // Act & Assert
        var exception = Assert.ThrowsAsync<ValidationException>(
            () => _service.GenerateKeyAsync(request));
        
        Assert.That(exception.Message, Contains.Substring("key size"));
        Assert.That(exception.Message, Contains.Substring("2048"));
    }
}
```

### C++ Unit Testing with Google Test
```cpp
#include <gtest/gtest.h>
#include <gmock/gmock.h>
#include "supacrypt/pkcs11/session_manager.h"
#include "supacrypt/pkcs11/key_generator.h"

class MockBackendClient : public IBackendClient 
{
public:
    MOCK_METHOD(CK_RV, GenerateKeyPair, 
               (const std::string& keyId, KeyType keyType, uint32_t keySize,
                CK_OBJECT_HANDLE_PTR publicKey, CK_OBJECT_HANDLE_PTR privateKey), 
               (override));
    
    MOCK_METHOD(CK_RV, SignData, 
               (CK_OBJECT_HANDLE keyHandle, const std::vector<uint8_t>& data,
                std::vector<uint8_t>& signature), 
               (override));
};

class PKCS11KeyGeneratorTest : public ::testing::Test 
{
protected:
    void SetUp() override 
    {
        mock_backend_ = std::make_shared<MockBackendClient>();
        key_generator_ = std::make_unique<KeyGenerator>(mock_backend_);
    }
    
    void TearDown() override 
    {
        key_generator_.reset();
        mock_backend_.reset();
    }
    
    std::shared_ptr<MockBackendClient> mock_backend_;
    std::unique_ptr<KeyGenerator> key_generator_;
};

TEST_F(PKCS11KeyGeneratorTest, GenerateRsaKeyPair_ValidParameters_ReturnsSuccess) 
{
    // Arrange
    CK_MECHANISM mechanism = { CKM_RSA_PKCS_KEY_PAIR_GEN, nullptr, 0 };
    CK_OBJECT_HANDLE public_key = 0, private_key = 0;
    
    EXPECT_CALL(*mock_backend_, GenerateKeyPair(
        testing::_, KeyType::RSA, 2048, testing::_, testing::_))
        .WillOnce(testing::DoAll(
            testing::SetArgPointee<3>(1001), // public key handle
            testing::SetArgPointee<4>(1002), // private key handle
            testing::Return(CKR_OK)));
    
    // Act
    CK_RV result = key_generator_->GenerateKeyPair(
        &mechanism, nullptr, 0, nullptr, 0, &public_key, &private_key);
    
    // Assert
    EXPECT_EQ(result, CKR_OK);
    EXPECT_EQ(public_key, 1001);
    EXPECT_EQ(private_key, 1002);
}

TEST_F(PKCS11KeyGeneratorTest, GenerateRsaKeyPair_BackendFailure_ReturnsError) 
{
    // Arrange
    CK_MECHANISM mechanism = { CKM_RSA_PKCS_KEY_PAIR_GEN, nullptr, 0 };
    CK_OBJECT_HANDLE public_key = 0, private_key = 0;
    
    EXPECT_CALL(*mock_backend_, GenerateKeyPair(testing::_, testing::_, testing::_, testing::_, testing::_))
        .WillOnce(testing::Return(CKR_SUPACRYPT_BACKEND_UNAVAILABLE));
    
    // Act
    CK_RV result = key_generator_->GenerateKeyPair(
        &mechanism, nullptr, 0, nullptr, 0, &public_key, &private_key);
    
    // Assert
    EXPECT_EQ(result, CKR_SUPACRYPT_BACKEND_UNAVAILABLE);
    EXPECT_EQ(public_key, 0);
    EXPECT_EQ(private_key, 0);
}
```

## Integration Testing Standards

### Test Environment Setup
```csharp
[TestFixture]
public class CryptographicServiceIntegrationTests
{
    private WebApplicationFactory<Program> _factory;
    private HttpClient _client;
    private string _testKeyVaultUrl;
    
    [OneTimeSetUp]
    public void OneTimeSetUp()
    {
        // Use test Key Vault or emulator
        _testKeyVaultUrl = Environment.GetEnvironmentVariable("TEST_KEYVAULT_URL") 
                          ?? "https://test-supacrypt.vault.azure.net/";
        
        _factory = new WebApplicationFactory<Program>()
            .WithWebHostBuilder(builder =>
            {
                builder.ConfigureAppConfiguration((context, config) =>
                {
                    config.AddInMemoryCollection(new[]
                    {
                        new KeyValuePair<string, string>("KeyVault:Url", _testKeyVaultUrl),
                        new KeyValuePair<string, string>("Testing:Environment", "Integration"),
                        new KeyValuePair<string, string>("Logging:LogLevel:Default", "Debug")
                    });
                });
                
                builder.ConfigureTestServices(services =>
                {
                    // Replace production services with test doubles where needed
                    services.AddSingleton<ITestDataSeeder, IntegrationTestDataSeeder>();
                });
            });
        
        _client = _factory.CreateClient();
    }
    
    [SetUp]
    public void SetUp()
    {
        // Clean up test data before each test
        var seeder = _factory.Services.GetRequiredService<ITestDataSeeder>();
        seeder.CleanupTestData().Wait();
    }
    
    [Test]
    public async Task EndToEndKeyGeneration_RsaKey_ShouldCompleteSuccessfully()
    {
        // Arrange
        var request = new GenerateKeyRequest
        {
            KeyId = $"integration-test-{Guid.NewGuid()}",
            KeyType = KeyType.Rsa,
            KeySize = 2048
        };
        
        // Act - Generate key via gRPC
        var generateResponse = await CallGrpcService(client => 
            client.GenerateKeyAsync(request));
        
        // Assert - Key generation succeeded
        Assert.That(generateResponse.Success, Is.True);
        Assert.That(generateResponse.KeyId, Is.EqualTo(request.KeyId));
        
        // Act - Sign data with generated key
        var signRequest = new SignRequest
        {
            KeyId = request.KeyId,
            Data = ByteString.CopyFromUtf8("test data for signing"),
            Algorithm = "RS256"
        };
        
        var signResponse = await CallGrpcService(client => 
            client.SignDataAsync(signRequest));
        
        // Assert - Signing succeeded
        Assert.That(signResponse.Success, Is.True);
        Assert.That(signResponse.Signature.Length, Is.GreaterThan(0));
        
        // Act - Verify signature
        var verifyRequest = new VerifyRequest
        {
            KeyId = request.KeyId,
            Data = signRequest.Data,
            Signature = signResponse.Signature,
            Algorithm = signRequest.Algorithm
        };
        
        var verifyResponse = await CallGrpcService(client => 
            client.VerifySignatureAsync(verifyRequest));
        
        // Assert - Verification succeeded
        Assert.That(verifyResponse.Success, Is.True);
        Assert.That(verifyResponse.IsValid, Is.True);
    }
}
```

### Backend-Provider Integration Testing
```cpp
class BackendIntegrationTest : public ::testing::Test 
{
protected:
    void SetUp() override 
    {
        // Start test backend service
        backend_process_ = StartTestBackendService();
        
        // Wait for service to be ready
        WaitForServiceReady("localhost:50051", std::chrono::seconds(30));
        
        // Initialize PKCS#11 provider
        provider_ = std::make_unique<PKCS11Provider>("localhost:50051");
        ASSERT_EQ(provider_->Initialize(), CKR_OK);
    }
    
    void TearDown() override 
    {
        if (provider_) {
            provider_->Finalize();
            provider_.reset();
        }
        
        if (backend_process_) {
            TerminateProcess(backend_process_);
        }
    }
    
    std::unique_ptr<Process> backend_process_;
    std::unique_ptr<PKCS11Provider> provider_;
};

TEST_F(BackendIntegrationTest, PKCS11_GenerateAndUseRsaKey_ShouldWorkEndToEnd) 
{
    // Arrange
    CK_SESSION_HANDLE session;
    ASSERT_EQ(provider_->OpenSession(0, CKF_SERIAL_SESSION | CKF_RW_SESSION, 
                                   nullptr, nullptr, &session), CKR_OK);
    
    CK_MECHANISM mechanism = { CKM_RSA_PKCS_KEY_PAIR_GEN, nullptr, 0 };
    CK_ULONG key_size = 2048;
    CK_BYTE key_id[] = "integration-test-key";
    
    CK_ATTRIBUTE public_template[] = {
        { CKA_MODULUS_BITS, &key_size, sizeof(key_size) },
        { CKA_ID, key_id, sizeof(key_id) - 1 },
        { CKA_VERIFY, &ck_true, sizeof(ck_true) }
    };
    
    CK_ATTRIBUTE private_template[] = {
        { CKA_ID, key_id, sizeof(key_id) - 1 },
        { CKA_SIGN, &ck_true, sizeof(ck_true) }
    };
    
    CK_OBJECT_HANDLE public_key, private_key;
    
    // Act - Generate key pair
    CK_RV result = provider_->GenerateKeyPair(
        session, &mechanism,
        public_template, sizeof(public_template) / sizeof(CK_ATTRIBUTE),
        private_template, sizeof(private_template) / sizeof(CK_ATTRIBUTE),
        &public_key, &private_key);
    
    // Assert - Key generation succeeded
    ASSERT_EQ(result, CKR_OK);
    ASSERT_NE(public_key, CK_INVALID_HANDLE);
    ASSERT_NE(private_key, CK_INVALID_HANDLE);
    
    // Act - Sign data
    CK_MECHANISM sign_mechanism = { CKM_RSA_PKCS, nullptr, 0 };
    std::vector<uint8_t> data = { 0x01, 0x02, 0x03, 0x04 };
    std::vector<uint8_t> signature(256); // RSA-2048 signature size
    CK_ULONG signature_len = signature.size();
    
    ASSERT_EQ(provider_->SignInit(session, &sign_mechanism, private_key), CKR_OK);
    ASSERT_EQ(provider_->Sign(session, data.data(), data.size(), 
                            signature.data(), &signature_len), CKR_OK);
    
    // Act - Verify signature
    ASSERT_EQ(provider_->VerifyInit(session, &sign_mechanism, public_key), CKR_OK);
    ASSERT_EQ(provider_->Verify(session, data.data(), data.size(),
                              signature.data(), signature_len), CKR_OK);
    
    // Cleanup
    provider_->CloseSession(session);
}
```

## End-to-End Testing

### Multi-Component Test Scenarios
```csharp
[TestFixture]
public class EndToEndTests
{
    private TestEnvironment _testEnv;
    
    [OneTimeSetUp]
    public async Task OneTimeSetUp()
    {
        _testEnv = new TestEnvironment();
        await _testEnv.StartAsync();
    }
    
    [OneTimeTearDown]
    public async Task OneTimeTearDown()
    {
        await _testEnv.StopAsync();
    }
    
    [Test]
    public async Task CrossPlatformCompatibility_WindowsCSPToBackendToPKCS11_ShouldMaintainInteroperability()
    {
        // Arrange - Generate key using Windows CSP
        var cspKeyId = await GenerateKeyUsingWindowsCSP("test-interop-key", 2048);
        
        // Act - Export public key via backend service
        var publicKey = await _testEnv.BackendClient.ExportPublicKeyAsync(cspKeyId);
        
        // Act - Import public key into PKCS#11 provider
        var pkcs11KeyHandle = await ImportKeyIntoPKCS11Provider(publicKey);
        
        // Act - Sign data using CSP, verify using PKCS#11
        var testData = Encoding.UTF8.GetBytes("cross-platform test data");
        var signature = await SignDataUsingCSP(cspKeyId, testData);
        var isValid = await VerifySignatureUsingPKCS11(pkcs11KeyHandle, testData, signature);
        
        // Assert
        Assert.That(isValid, Is.True, "Cross-platform signature verification failed");
    }
    
    [Test]
    public async Task HighAvailability_BackendFailover_ShouldMaintainServiceContinuity()
    {
        // Arrange - Start with primary backend
        await _testEnv.StartPrimaryBackend();
        var keyId = await GenerateTestKey();
        
        // Act - Simulate primary backend failure
        await _testEnv.StopPrimaryBackend();
        await _testEnv.StartSecondaryBackend();
        
        // Wait for failover detection
        await Task.Delay(TimeSpan.FromSeconds(5));
        
        // Act - Attempt to use existing key
        var testData = new byte[] { 1, 2, 3, 4, 5 };
        var signResult = await _testEnv.ClientProvider.SignDataAsync(keyId, testData);
        
        // Assert
        Assert.That(signResult.Success, Is.True, "Service should continue after failover");
    }
}
```

## Mocking Patterns for External Dependencies

### Azure Key Vault Mocking
```csharp
public class MockKeyVaultClientBuilder
{
    private readonly Mock<KeyVaultClient> _mock;
    private readonly Dictionary<string, KeyVaultKey> _keys;
    
    public MockKeyVaultClientBuilder()
    {
        _mock = new Mock<KeyVaultClient>();
        _keys = new Dictionary<string, KeyVaultKey>();
        SetupDefaultBehavior();
    }
    
    public MockKeyVaultClientBuilder WithKey(string keyId, KeyType keyType, int keySize)
    {
        var key = new KeyVaultKey(keyId, keyType) { KeySize = keySize };
        _keys[keyId] = key;
        
        _mock.Setup(x => x.GetKeyAsync(keyId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(key);
            
        return this;
    }
    
    public MockKeyVaultClientBuilder WithGenerateKeyFailure(string keyId, Exception exception)
    {
        _mock.Setup(x => x.CreateRsaKeyAsync(keyId, It.IsAny<int>(), It.IsAny<CancellationToken>()))
            .ThrowsAsync(exception);
            
        return this;
    }
    
    public MockKeyVaultClientBuilder WithNetworkDelay(TimeSpan delay)
    {
        _mock.Setup(x => x.GetKeyAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .Returns(async (string keyId, CancellationToken ct) =>
            {
                await Task.Delay(delay, ct);
                return _keys.TryGetValue(keyId, out var key) ? key : throw new KeyNotFoundException();
            });
            
        return this;
    }
    
    public KeyVaultClient Build() => _mock.Object;
}

// Usage in tests
[Test]
public async Task GenerateKey_WhenKeyVaultHasNetworkDelay_ShouldTimeoutAppropriately()
{
    // Arrange
    var mockKeyVault = new MockKeyVaultClientBuilder()
        .WithNetworkDelay(TimeSpan.FromSeconds(35)) // Longer than timeout
        .Build();
        
    var service = new CryptographicService(mockKeyVault, _logger);
    
    // Act & Assert
    var exception = await Assert.ThrowsAsync<TimeoutException>(
        () => service.GenerateKeyAsync(new GenerateKeyRequest 
        { 
            KeyId = "test-key", 
            KeyType = KeyType.Rsa 
        }));
}
```

### Provider Communication Mocking
```cpp
class MockGrpcClient : public ISupacryptGrpcClient 
{
private:
    std::map<std::string, GenerateKeyResponse> key_responses_;
    std::map<std::string, SignResponse> sign_responses_;
    bool simulate_network_failure_ = false;
    std::chrono::milliseconds network_delay_{0};
    
public:
    void SetGenerateKeyResponse(const std::string& key_id, const GenerateKeyResponse& response) 
    {
        key_responses_[key_id] = response;
    }
    
    void SetSignResponse(const std::string& key_id, const SignResponse& response) 
    {
        sign_responses_[key_id] = response;
    }
    
    void SimulateNetworkFailure(bool fail) 
    {
        simulate_network_failure_ = fail;
    }
    
    void SetNetworkDelay(std::chrono::milliseconds delay) 
    {
        network_delay_ = delay;
    }
    
    grpc::Status GenerateKey(const GenerateKeyRequest& request, 
                           GenerateKeyResponse* response) override 
    {
        if (simulate_network_failure_) {
            return grpc::Status(grpc::StatusCode::UNAVAILABLE, "Simulated network failure");
        }
        
        if (network_delay_.count() > 0) {
            std::this_thread::sleep_for(network_delay_);
        }
        
        auto it = key_responses_.find(request.key_id());
        if (it != key_responses_.end()) {
            *response = it->second;
            return grpc::Status::OK;
        }
        
        return grpc::Status(grpc::StatusCode::NOT_FOUND, "Key not found in mock");
    }
};

// Usage in tests
TEST_F(PKCS11ProviderTest, GenerateKey_WithNetworkFailure_ShouldRetryAndEventuallyFail) 
{
    // Arrange
    auto mock_client = std::make_shared<MockGrpcClient>();
    mock_client->SimulateNetworkFailure(true);
    
    auto provider = std::make_unique<PKCS11Provider>(mock_client);
    
    // Act
    CK_SESSION_HANDLE session;
    provider->OpenSession(0, CKF_SERIAL_SESSION, nullptr, nullptr, &session);
    
    CK_MECHANISM mechanism = { CKM_RSA_PKCS_KEY_PAIR_GEN, nullptr, 0 };
    CK_OBJECT_HANDLE public_key, private_key;
    
    CK_RV result = provider->GenerateKeyPair(session, &mechanism, 
                                           nullptr, 0, nullptr, 0,
                                           &public_key, &private_key);
    
    // Assert
    EXPECT_EQ(result, CKR_SUPACRYPT_BACKEND_UNAVAILABLE);
}
```

## Performance Testing Standards

### Benchmark Testing
```csharp
[MemoryDiagnoser]
[SimpleJob(RuntimeMoniker.Net80)]
public class CryptographicOperationsBenchmark
{
    private CryptographicService _service;
    private string _testKeyId;
    private byte[] _testData;
    
    [GlobalSetup]
    public async Task GlobalSetup()
    {
        _service = CreateTestService();
        _testKeyId = await CreateTestKey();
        _testData = new byte[1024]; // 1KB test data
        Random.Shared.NextBytes(_testData);
    }
    
    [Benchmark]
    [Arguments(2048)]
    [Arguments(3072)]
    [Arguments(4096)]
    public async Task GenerateRsaKey(int keySize)
    {
        var request = new GenerateKeyRequest
        {
            KeyId = $"benchmark-key-{Guid.NewGuid()}",
            KeyType = KeyType.Rsa,
            KeySize = keySize
        };
        
        await _service.GenerateKeyAsync(request);
    }
    
    [Benchmark]
    [Arguments(256)]   // 256 bytes
    [Arguments(1024)]  // 1KB
    [Arguments(10240)] // 10KB
    public async Task SignData(int dataSize)
    {
        var data = new byte[dataSize];
        Random.Shared.NextBytes(data);
        
        var request = new SignRequest
        {
            KeyId = _testKeyId,
            Data = ByteString.CopyFrom(data),
            Algorithm = "RS256"
        };
        
        await _service.SignDataAsync(request);
    }
    
    [Benchmark]
    public async Task VerifySignature()
    {
        // First sign the data
        var signRequest = new SignRequest
        {
            KeyId = _testKeyId,
            Data = ByteString.CopyFrom(_testData),
            Algorithm = "RS256"
        };
        
        var signResponse = await _service.SignDataAsync(signRequest);
        
        // Then verify the signature
        var verifyRequest = new VerifyRequest
        {
            KeyId = _testKeyId,
            Data = signRequest.Data,
            Signature = signResponse.Signature,
            Algorithm = signRequest.Algorithm
        };
        
        await _service.VerifySignatureAsync(verifyRequest);
    }
}
```

### Load Testing
```csharp
[TestFixture]
public class LoadTests
{
    private WebApplicationFactory<Program> _factory;
    private readonly List<Task> _concurrentTasks = new();
    
    [Test]
    public async Task ConcurrentKeyGeneration_100SimultaneousRequests_ShouldHandleLoad()
    {
        // Arrange
        const int concurrentRequests = 100;
        var client = _factory.CreateClient();
        var semaphore = new SemaphoreSlim(10); // Limit concurrent connections
        
        // Act
        var tasks = Enumerable.Range(0, concurrentRequests)
            .Select(async i =>
            {
                await semaphore.WaitAsync();
                try
                {
                    var request = new GenerateKeyRequest
                    {
                        KeyId = $"load-test-key-{i}",
                        KeyType = KeyType.Rsa,
                        KeySize = 2048
                    };
                    
                    var response = await CallGrpcService(client, svc => svc.GenerateKeyAsync(request));
                    return response.Success;
                }
                finally
                {
                    semaphore.Release();
                }
            });
        
        var results = await Task.WhenAll(tasks);
        
        // Assert
        var successCount = results.Count(r => r);
        var successRate = (double)successCount / concurrentRequests;
        
        Assert.That(successRate, Is.GreaterThan(0.95), 
            $"Success rate {successRate:P2} below acceptable threshold");
    }
    
    [Test]
    public async Task SustainedLoad_1000RequestsOver60Seconds_ShouldMaintainPerformance()
    {
        // Arrange
        const int totalRequests = 1000;
        const int durationSeconds = 60;
        var client = _factory.CreateClient();
        var requestInterval = TimeSpan.FromMilliseconds(durationSeconds * 1000.0 / totalRequests);
        
        var results = new ConcurrentBag<(bool success, TimeSpan duration)>();
        
        // Act
        await Parallel.ForEachAsync(
            Enumerable.Range(0, totalRequests),
            new ParallelOptions { MaxDegreeOfParallelism = 20 },
            async (i, ct) =>
            {
                await Task.Delay(requestInterval * i, ct);
                
                var stopwatch = Stopwatch.StartNew();
                try
                {
                    var request = new SignRequest
                    {
                        KeyId = "load-test-key",
                        Data = ByteString.CopyFrom(Encoding.UTF8.GetBytes($"test data {i}")),
                        Algorithm = "RS256"
                    };
                    
                    var response = await CallGrpcService(client, svc => svc.SignDataAsync(request));
                    results.Add((response.Success, stopwatch.Elapsed));
                }
                catch
                {
                    results.Add((false, stopwatch.Elapsed));
                }
            });
        
        // Assert
        var successCount = results.Count(r => r.success);
        var averageLatency = results.Where(r => r.success).Average(r => r.duration.TotalMilliseconds);
        var p95Latency = results.Where(r => r.success)
            .Select(r => r.duration.TotalMilliseconds)
            .OrderBy(x => x)
            .Skip((int)(successCount * 0.95))
            .FirstOrDefault();
        
        Assert.That(successCount / (double)totalRequests, Is.GreaterThan(0.99));
        Assert.That(averageLatency, Is.LessThan(100)); // 100ms average
        Assert.That(p95Latency, Is.LessThan(500)); // 500ms P95
    }
}
```

## Security Testing

### Cryptographic Validation Tests
```csharp
[TestFixture]
public class CryptographicValidationTests
{
    [Test]
    public async Task RsaKeyGeneration_ShouldProduceValidKeyPairs()
    {
        // Arrange
        var request = new GenerateKeyRequest
        {
            KeyId = "crypto-validation-test",
            KeyType = KeyType.Rsa,
            KeySize = 2048
        };
        
        // Act
        var response = await _service.GenerateKeyAsync(request);
        
        // Assert - Basic validation
        Assert.That(response.Success, Is.True);
        Assert.That(response.PublicKey.Length, Is.GreaterThan(0));
        
        // Assert - Cryptographic validation
        using var rsa = RSA.Create();
        rsa.ImportRSAPublicKey(response.PublicKey.ToByteArray(), out _);
        
        // Validate key size
        Assert.That(rsa.KeySize, Is.EqualTo(2048));
        
        // Validate public exponent (should be 65537 for security)
        var parameters = rsa.ExportParameters(false);
        var publicExponent = new BigInteger(parameters.Exponent, isUnsigned: true);
        Assert.That(publicExponent, Is.EqualTo(65537));
        
        // Validate modulus length
        Assert.That(parameters.Modulus.Length, Is.EqualTo(256)); // 2048 bits = 256 bytes
    }
    
    [Test]
    public async Task SignatureGeneration_ShouldProduceUniqueSignatures()
    {
        // Arrange
        var keyId = await CreateTestKey();
        var testData = Encoding.UTF8.GetBytes("test data for signing");
        
        // Act - Generate multiple signatures of the same data
        var signatures = new List<byte[]>();
        for (int i = 0; i < 10; i++)
        {
            var signRequest = new SignRequest
            {
                KeyId = keyId,
                Data = ByteString.CopyFrom(testData),
                Algorithm = "RS256"
            };
            
            var response = await _service.SignDataAsync(signRequest);
            signatures.Add(response.Signature.ToByteArray());
        }
        
        // Assert - All signatures should be different (due to PSS padding randomness)
        for (int i = 0; i < signatures.Count; i++)
        {
            for (int j = i + 1; j < signatures.Count; j++)
            {
                Assert.That(signatures[i], Is.Not.EqualTo(signatures[j]),
                    "Signatures should be unique due to randomization");
            }
        }
        
        // Assert - All signatures should verify correctly
        foreach (var signature in signatures)
        {
            var verifyRequest = new VerifyRequest
            {
                KeyId = keyId,
                Data = ByteString.CopyFrom(testData),
                Signature = ByteString.CopyFrom(signature),
                Algorithm = "RS256"
            };
            
            var verifyResponse = await _service.VerifySignatureAsync(verifyRequest);
            Assert.That(verifyResponse.IsValid, Is.True);
        }
    }
    
    [Test]
    public void KeyGeneration_ShouldUseSecureRandomness()
    {
        // This test validates that key generation uses cryptographically secure randomness
        // by checking for statistical properties in generated keys
        
        var publicExponents = new List<byte[]>();
        var modulusBytes = new List<byte[]>();
        
        // Generate multiple keys and collect entropy-sensitive parts
        for (int i = 0; i < 50; i++)
        {
            var keyData = GenerateTestKeyAndExtractPublicKey();
            
            using var rsa = RSA.Create();
            rsa.ImportRSAPublicKey(keyData, out _);
            var parameters = rsa.ExportParameters(false);
            
            publicExponents.Add(parameters.Exponent);
            modulusBytes.Add(parameters.Modulus);
        }
        
        // Statistical tests for randomness
        Assert.That(modulusBytes.Select(m => m[0]).Distinct().Count(), Is.GreaterThan(10),
            "First bytes of modulus should show randomness");
            
        Assert.That(modulusBytes.Select(m => m[^1]).Distinct().Count(), Is.GreaterThan(10),
            "Last bytes of modulus should show randomness");
    }
}
```

### Vulnerability Testing
```csharp
[TestFixture]
public class SecurityVulnerabilityTests
{
    [Test]
    public async Task SignatureVerification_WithModifiedSignature_ShouldRejectInvalidSignature()
    {
        // Arrange
        var keyId = await CreateTestKey();
        var testData = Encoding.UTF8.GetBytes("original test data");
        
        var signResponse = await _service.SignDataAsync(new SignRequest
        {
            KeyId = keyId,
            Data = ByteString.CopyFrom(testData),
            Algorithm = "RS256"
        });
        
        // Act - Modify signature bytes
        var modifiedSignature = signResponse.Signature.ToByteArray();
        modifiedSignature[0] ^= 0x01; // Flip one bit
        
        var verifyResponse = await _service.VerifySignatureAsync(new VerifyRequest
        {
            KeyId = keyId,
            Data = ByteString.CopyFrom(testData),
            Signature = ByteString.CopyFrom(modifiedSignature),
            Algorithm = "RS256"
        });
        
        // Assert
        Assert.That(verifyResponse.IsValid, Is.False,
            "Modified signature should be rejected");
    }
    
    [Test]
    public async Task KeyAccess_WithoutAuthentication_ShouldDenyAccess()
    {
        // Arrange
        var unauthorizedClient = CreateUnauthenticatedClient();
        
        // Act & Assert
        var exception = await Assert.ThrowsAsync<RpcException>(
            () => unauthorizedClient.GenerateKeyAsync(new GenerateKeyRequest
            {
                KeyId = "unauthorized-key",
                KeyType = KeyType.Rsa,
                KeySize = 2048
            }));
        
        Assert.That(exception.StatusCode, Is.EqualTo(StatusCode.Unauthenticated));
    }
    
    [Test]
    public void InputValidation_MaliciousKeyId_ShouldRejectInvalidInput()
    {
        // Test various injection attempts
        var maliciousInputs = new[]
        {
            "../../../etc/passwd",
            "<script>alert('xss')</script>",
            "'; DROP TABLE keys; --",
            new string('A', 10000), // Extremely long input
            "\0\r\n\t", // Control characters
            "测试中文字符", // Unicode characters
        };
        
        foreach (var maliciousInput in maliciousInputs)
        {
            var exception = Assert.ThrowsAsync<ValidationException>(
                () => _service.GenerateKeyAsync(new GenerateKeyRequest
                {
                    KeyId = maliciousInput,
                    KeyType = KeyType.Rsa,
                    KeySize = 2048
                }));
                
            Assert.That(exception.Message, Contains.Substring("invalid"),
                $"Should reject malicious input: {maliciousInput}");
        }
    }
}
```

## Test Coverage Reporting

### Coverage Configuration
```xml
<!-- Directory.Build.props -->
<Project>
  <PropertyGroup>
    <CollectCoverage>true</CollectCoverage>
    <CoverletOutputFormat>opencover,lcov,json</CoverletOutputFormat>
    <CoverletOutput>./TestResults/coverage</CoverletOutput>
    <ExcludeByFile>**/Migrations/*.cs,**/Generated/*.cs</ExcludeByFile>
    <ExcludeByAttribute>Obsolete,GeneratedCode,ExcludeFromCodeCoverage</ExcludeByAttribute>
    <Include>[Supacrypt.*]*</Include>
    <Exclude>[*.Tests]*,[*.TestHelpers]*</Exclude>
    <Threshold>80</Threshold>
    <ThresholdType>line,branch</ThresholdType>
    <ThresholdStat>minimum</ThresholdStat>
  </PropertyGroup>
</Project>
```

### Coverage Analysis Scripts
```bash
#!/bin/bash
# coverage-report.sh

# Run tests with coverage
dotnet test --collect:"XPlat Code Coverage" --results-directory ./TestResults

# Generate HTML report
reportgenerator \
    -reports:"./TestResults/*/coverage.cobertura.xml" \
    -targetdir:"./TestResults/CoverageReport" \
    -reporttypes:"Html;Badges;TextSummary"

# Check coverage thresholds
COVERAGE=$(grep -o 'Line coverage: [0-9.]*%' ./TestResults/CoverageReport/Summary.txt | grep -o '[0-9.]*')
THRESHOLD=80

if (( $(echo "$COVERAGE < $THRESHOLD" | bc -l) )); then
    echo "Coverage $COVERAGE% below threshold $THRESHOLD%"
    exit 1
else
    echo "Coverage $COVERAGE% meets threshold $THRESHOLD%"
fi
```

## Best Practices Summary

### Testing Do's
1. Write tests before implementing features (TDD approach)
2. Use descriptive test names that explain the scenario
3. Follow the AAA pattern (Arrange-Act-Assert)
4. Test both happy path and error conditions
5. Use mocks and stubs for external dependencies
6. Maintain high test coverage (minimum 80%)
7. Include performance and security tests
8. Automate test execution in CI/CD pipelines

### Testing Don'ts
1. Don't test implementation details, test behavior
2. Don't write tests that depend on external services in unit tests
3. Don't ignore flaky tests - fix or remove them
4. Don't test private methods directly
5. Don't use production data in tests
6. Don't skip security and vulnerability testing
7. Don't forget to test error handling paths
8. Don't write tests without clear assertions

### Security Testing Considerations
- Always test cryptographic operations for correctness
- Validate that sensitive data is not logged or exposed
- Test input validation thoroughly
- Verify authentication and authorization mechanisms
- Test for timing attacks and side-channel vulnerabilities
- Ensure proper key lifecycle management

## References

- [NUnit Documentation](https://docs.nunit.org/)
- [Google Test Framework](https://github.com/google/googletest)
- [BenchmarkDotNet](https://benchmarkdotnet.org/)
- [Moq Framework](https://github.com/moq/moq4)
- [ASP.NET Core Testing](https://docs.microsoft.com/en-us/aspnet/core/test/)
- [OWASP Testing Guide](https://owasp.org/www-project-web-security-testing-guide/)
- [Cryptographic Testing Standards](https://csrc.nist.gov/projects/cryptographic-algorithm-validation-program)