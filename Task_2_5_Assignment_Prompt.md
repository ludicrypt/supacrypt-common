# Task 2.5: Add OpenTelemetry Observability - Assignment Prompt

## Role Definition

You are an Implementation Agent specializing in observability and monitoring systems. Your expertise includes OpenTelemetry, distributed tracing, metrics collection, and production-grade monitoring solutions. You will enhance the Supacrypt backend service with comprehensive observability capabilities.

## Task Overview

Implement OpenTelemetry-based observability for the Supacrypt backend service, providing comprehensive logging, metrics, and distributed tracing capabilities. This implementation will enable deep visibility into service behavior, performance characteristics, and operational health.

## Context and Dependencies

### Current State
- Existing Supacrypt backend service with:
  - gRPC API serving cryptographic operations
  - Azure Key Vault integration for key management
  - mTLS authentication and authorization
  - Basic health check endpoints
  - Structured logging foundation

### Prerequisites Review
Before starting, review these existing resources:
- `/supacrypt-backend-akv/src/Supacrypt.Backend/` - Current implementation
- `/supacrypt-common/docs/standards/logging-standards.md` - Logging conventions
- Task 2.2, 2.3, and 2.4 Memory Bank logs for implementation context

## Detailed Requirements

### 1. OpenTelemetry Configuration

#### 1.1 Provider Setup
- Configure OpenTelemetry SDK for .NET
- Set up providers for:
  - **Logging**: Integrate with existing ILogger infrastructure
  - **Metrics**: Configure metric instruments and readers
  - **Tracing**: Set up activity sources and span processors

#### 1.2 Service Information
- Add resource attributes:
  - Service name: `supacrypt-backend`
  - Service version: From assembly version
  - Service instance ID: Unique per deployment
  - Environment: Development/Staging/Production
  - Cloud provider and region (for Azure deployments)

### 2. Custom Metrics Implementation

#### 2.1 Metric Naming Convention
Follow the pattern: `supacrypt.[component].[metric_type].[name]`

Examples:
- `supacrypt.crypto.operation.count`
- `supacrypt.crypto.operation.duration`
- `supacrypt.akv.request.latency`
- `supacrypt.grpc.request.size`

#### 2.2 Required Metrics

**Cryptographic Operations:**
- Operation count by type (sign, verify, encrypt, decrypt)
- Operation duration histogram
- Operation errors by type
- Key usage frequency
- Algorithm distribution

**Azure Key Vault:**
- Request latency histogram
- Request count by operation
- Error rate by error type
- Token refresh count
- Connection pool statistics

**gRPC Service:**
- Request rate by method
- Request duration by method
- Request/response size histograms
- Active connection count
- Error rate by status code

**System Health:**
- Memory usage (heap, non-heap)
- CPU utilization
- Thread pool statistics
- GC statistics
- Certificate expiration time remaining

### 3. Distributed Tracing

#### 3.1 Trace Propagation
- Implement W3C Trace Context propagation
- Extract trace context from incoming gRPC metadata
- Inject trace context into outgoing Azure Key Vault requests
- Support B3 propagation for backward compatibility

#### 3.2 Span Attributes
Add semantic attributes to spans:
- `crypto.operation.type`: sign, verify, encrypt, decrypt
- `crypto.key.id`: Key identifier (sanitized)
- `crypto.algorithm`: Algorithm used
- `akv.vault.name`: Key Vault name
- `rpc.grpc.status_code`: gRPC status
- `enduser.id`: Client certificate CN

#### 3.3 Span Events
Record significant events:
- Key rotation detected
- Rate limit encountered
- Circuit breaker state changes
- Authentication failures
- Cache hits/misses

### 4. Exporter Configuration

#### 4.1 Development Environment
```csharp
// Console exporter for local debugging
.AddConsoleExporter()
// OTLP exporter to local collector
.AddOtlpExporter(options =>
{
    options.Endpoint = new Uri("http://localhost:4317");
    options.Protocol = OtlpExportProtocol.Grpc;
})
```

#### 4.2 Production Environment
```csharp
// OTLP exporter with authentication
.AddOtlpExporter(options =>
{
    options.Endpoint = new Uri(configuration["Observability:OtlpEndpoint"]);
    options.Headers = configuration["Observability:OtlpHeaders"];
    options.Protocol = OtlpExportProtocol.Grpc;
})
// Batch processor configuration
.SetResourceBuilder(ResourceBuilder.CreateDefault()
    .AddService("supacrypt-backend")
    .AddAttributes(productionAttributes))
```

### 5. Health Checks and Readiness Probes

#### 5.1 Enhanced Health Checks
Extend existing health checks with:
- OpenTelemetry exporter health
- Metric collection health
- Trace sampling rate
- Buffer saturation levels

#### 5.2 Metrics for Health Monitoring
- `supacrypt.health.check.duration`: Health check execution time
- `supacrypt.health.check.status`: Current health status (1=healthy, 0=unhealthy)
- `supacrypt.health.component.status`: Per-component health status

### 6. Performance Tracking

#### 6.1 Operation Latency Tracking
```csharp
// Example histogram for crypto operations
private static readonly Histogram<double> CryptoOperationDuration = 
    Meter.CreateHistogram<double>(
        "supacrypt.crypto.operation.duration",
        unit: "ms",
        description: "Duration of cryptographic operations");

// Usage with attributes
CryptoOperationDuration.Record(
    duration.TotalMilliseconds,
    new KeyValuePair<string, object?>("operation", "sign"),
    new KeyValuePair<string, object?>("algorithm", "RS256"));
```

#### 6.2 SLA Metrics
- P50, P95, P99 latency percentiles
- Success rate percentage
- Error budget consumption
- Throughput (operations per second)

### 7. Dashboard-Ready Metrics

Ensure all metrics are compatible with common dashboarding solutions:

#### 7.1 Prometheus Format
- Use appropriate metric types (Counter, Gauge, Histogram)
- Include necessary labels for aggregation
- Follow Prometheus naming conventions where applicable

#### 7.2 Grafana Integration
Structure metrics to support common queries:
- Rate calculations: `rate(supacrypt_crypto_operation_count[5m])`
- Latency percentiles: `histogram_quantile(0.95, ...)`
- Error rates: `rate(errors[5m]) / rate(total[5m])`

### 8. Configuration Management

#### 8.1 Configuration Structure
```json
{
  "Observability": {
    "ServiceName": "supacrypt-backend",
    "Metrics": {
      "Enabled": true,
      "ExportInterval": 60000,
      "Exemplars": true
    },
    "Tracing": {
      "Enabled": true,
      "SamplingRatio": 0.1,
      "AlwaysSampleErrors": true
    },
    "Logging": {
      "IncludeScopes": true,
      "IncludeFormattedMessage": true
    },
    "Exporters": {
      "Otlp": {
        "Endpoint": "http://localhost:4317",
        "Headers": "",
        "Timeout": 10000
      }
    }
  }
}
```

#### 8.2 Environment-Specific Settings
- Development: Verbose logging, 100% sampling, console exporters
- Staging: Normal logging, 10% sampling, OTLP to staging collector
- Production: Structured logging only, 1% sampling (100% for errors), OTLP with auth

### 9. Correlation and Context

#### 9.1 Correlation IDs
- Generate or extract correlation IDs for all requests
- Propagate through all layers (gRPC → Service → Azure Key Vault)
- Include in all log entries and trace spans

#### 9.2 Baggage Propagation
- Client identifier
- Tenant/organization ID
- Request priority
- Feature flags

### 10. Implementation Guidelines

#### 10.1 Code Organization
```
Supacrypt.Backend/
├── Observability/
│   ├── ObservabilityExtensions.cs      # Service collection extensions
│   ├── Metrics/
│   │   ├── CryptoMetrics.cs           # Crypto operation metrics
│   │   ├── AkvMetrics.cs              # Azure Key Vault metrics
│   │   └── SystemMetrics.cs           # System health metrics
│   ├── Tracing/
│   │   ├── ActivitySources.cs         # Activity source definitions
│   │   └── TracingEnricher.cs         # Span enrichment logic
│   └── HealthChecks/
│       └── ObservabilityHealthCheck.cs # Observability system health
```

#### 10.2 Integration Points
- Instrument all public service methods
- Add metrics to Azure Key Vault client wrapper
- Enhance gRPC interceptors with tracing
- Integrate with existing logging infrastructure

## Testing Requirements

### 1. Unit Tests
- Metric recording accuracy
- Trace propagation logic
- Health check functionality
- Configuration validation

### 2. Integration Tests
- End-to-end trace flow
- Metric export verification
- Performance overhead measurement
- Error scenario handling

### 3. Load Tests
- Metric accuracy under load
- Trace sampling effectiveness
- Buffer overflow handling
- Export backpressure management

## Memory Bank Requirements

Log all significant implementation decisions and technical details to:
`/supacrypt-common/Memory/Phase_2_Backend_Service/Task_2_5_Observability_Log.md`

Include:
- OpenTelemetry configuration choices
- Custom metric definitions
- Performance impact measurements
- Integration challenges and solutions
- Testing approach and results

## Success Criteria

1. **Complete Observability**
   - All operations instrumented with metrics and traces
   - Comprehensive error tracking and alerting capability
   - Full request lifecycle visibility

2. **Performance**
   - Overhead < 5% for normal operations
   - Efficient batching and export
   - No memory leaks or unbounded growth

3. **Operational Excellence**
   - Easy to understand dashboards
   - Actionable alerts based on SLIs
   - Effective debugging capabilities

4. **Standards Compliance**
   - Follows OpenTelemetry semantic conventions
   - Adheres to logging standards
   - Consistent metric naming

## Deliverables

1. **Implementation**
   - Complete OpenTelemetry integration
   - Custom metrics and traces
   - Health check enhancements
   - Configuration management

2. **Documentation**
   - Metric catalog with descriptions
   - Tracing guide with examples
   - Dashboard setup instructions
   - Troubleshooting guide

3. **Tests**
   - Comprehensive test coverage
   - Performance benchmarks
   - Integration test suite

4. **Memory Bank Entry**
   - Complete implementation log
   - Decision rationale
   - Lessons learned

## Additional Notes

- Prioritize actionable insights over data volume
- Consider future integration with APM solutions
- Design for multi-region deployment scenarios
- Plan for metric cardinality limits
- Implement graceful degradation if exporters fail

Remember: The goal is to provide deep operational visibility while maintaining service performance and reliability. Focus on metrics that drive actionable insights and support both debugging and business intelligence needs.