# APM Task Assignment: Establish Project-Wide Standards and Conventions

## 1. Agent Role & APM Context

**Introduction:** You are activated as an Implementation Agent - Standards Architect within the Agentic Project Management (APM) framework for the Supacrypt cryptographic software suite project.

**Your Role:** As an Implementation Agent, you are responsible for executing assigned tasks diligently, implementing solutions according to specifications, and meticulously logging your work to the Memory Bank for project tracking and continuity.

**Workflow:** You will work under the guidance of the Manager Agent (communicated via the User), following the Implementation Plan and contributing to the project's Memory Bank located at `./Memory/`.

## 2. Onboarding / Context from Prior Work

**Previous Task Context:** Task 1.1 has been completed successfully. The Implementation Agent - Protobuf Specialist has created the comprehensive protobuf definition at `supacrypt-common/proto/supacrypt.proto`. This establishes the gRPC service interface with support for:
- RSA (2048/3072/4096-bit) and ECC (P-256/P-384/P-521) operations
- Key generation, signing, verification, encryption, decryption, and management
- Comprehensive error handling with provider-specific error codes
- Versioned package structure (`supacrypt.v1`) with extensibility

This protobuf definition serves as the contract that all components must adhere to, making standardization across the project critical.

## 3. Task Assignment

**Reference Implementation Plan:** This assignment corresponds to **Phase 1: Foundation & Core Infrastructure, Task 1.2: Establish Project-Wide Standards and Conventions** in the Implementation Plan.

**Objective:** Create comprehensive documentation for coding standards, naming conventions, and best practices across all components of the Supacrypt suite.

**Detailed Action Steps:**

1. **Define C++20/C17 coding standards for native providers:**
   - Create coding standards document covering:
     - Code formatting rules (indentation, brace style, line length)
     - Naming conventions for classes, functions, variables, constants
     - Memory management patterns (RAII, smart pointers usage)
     - Error handling patterns (exception usage vs error codes)
     - Thread safety requirements and patterns
   - Address platform-specific considerations:
     - Cross-platform compatibility requirements
     - Platform-specific API usage guidelines
     - Conditional compilation patterns
   - Include specific guidance for:
     - PKCS#11 provider implementation patterns
     - Windows CSP/KSP specific conventions
     - macOS CTK framework integration patterns

2. **Establish .NET/C# 13 standards for backend service:**
   - Define C# coding conventions including:
     - .NET naming conventions aligned with Microsoft guidelines
     - Async/await patterns and best practices
     - Dependency injection patterns
     - Exception handling and logging patterns
   - Specify .NET Aspire 9.3 specific patterns:
     - Service registration conventions
     - Configuration management patterns
     - Health check implementation standards
   - Document gRPC service implementation patterns:
     - Service class structure
     - Request validation patterns
     - Response building conventions

3. **Create naming conventions for cross-component elements:**
   - gRPC services and methods:
     - Service naming patterns (already established as SupacryptService)
     - Method naming consistency with protobuf definitions
     - Request/response message naming patterns
   - Configuration parameters:
     - Environment variable naming (SUPACRYPT_*)
     - Configuration file section naming
     - Secret/credential naming patterns
   - OpenTelemetry metrics and traces:
     - Metric naming conventions (e.g., supacrypt.operations.count)
     - Trace span naming patterns
     - Attribute naming standards
     - Tag conventions for different components

4. **Document error handling patterns:**
   - Define error code ranges for different components:
     - Backend service errors (1000-1999)
     - PKCS#11 provider errors (2000-2999)
     - CSP errors (3000-3999)
     - KSP errors (4000-4999)
     - CTK errors (5000-5999)
   - Establish error propagation patterns:
     - How provider errors map to gRPC status codes
     - Error detail message formats
     - Logging requirements for errors
   - Create error documentation template

5. **Establish logging standards across all components:**
   - Define log levels and when to use them:
     - Debug, Information, Warning, Error, Critical
   - Specify structured logging formats:
     - Required fields (timestamp, component, operation, correlation_id)
     - Optional fields (user_id, key_id, duration)
   - Create logging message templates for common operations
   - Define sensitive data handling in logs (no key material, no PII)

6. **Define integration testing approaches:**
   - Establish test naming conventions
   - Define test organization patterns:
     - Unit tests structure
     - Integration tests structure
     - End-to-end tests structure
   - Specify mocking patterns for external dependencies
   - Create test coverage requirements (minimum 80% unit test coverage)
   - Define performance testing standards

**Create the Following Documentation Files:**
- `docs/standards/cpp-coding-standards.md` - C++20/C17 standards for native providers
- `docs/standards/csharp-coding-standards.md` - C# 13/.NET standards for backend
- `docs/standards/naming-conventions.md` - Cross-component naming standards
- `docs/standards/error-handling-guide.md` - Error handling patterns and codes
- `docs/standards/logging-standards.md` - Logging conventions and patterns
- `docs/standards/testing-standards.md` - Testing approaches and requirements

## 4. Expected Output & Deliverables

**Define Success:**
- Comprehensive standards documentation that can be followed by all Implementation Agents
- Clear, actionable guidelines with examples
- Standards that ensure consistency across all six components
- Documentation that addresses the specific needs of each technology stack

**Specify Deliverables:**
1. Six standards documents created in `supacrypt-common/docs/standards/`:
   - `cpp-coding-standards.md`
   - `csharp-coding-standards.md`
   - `naming-conventions.md`
   - `error-handling-guide.md`
   - `logging-standards.md`
   - `testing-standards.md`
2. Each document should include:
   - Clear guidelines with rationale
   - Code examples demonstrating the standards
   - Do's and don'ts sections where appropriate
   - References to industry best practices

## 5. Memory Bank Logging Instructions

**Instruction:** Upon successful completion of this task, you **must** log your work comprehensively to the Memory Bank file at `./Memory/Phase_1_Foundation/Task_1_2_Standards_Documentation_Log.md`.

**Format Adherence:** Adhere strictly to the established logging format as defined in the Memory Bank Log Format guide. Ensure your log includes:
- Task Reference: "Phase 1 / Task 1.2 / Establish Project-Wide Standards and Conventions"
- Summary of standards established for each technology stack
- Key decisions made regarding conventions
- Any challenges in reconciling different platform requirements
- Confirmation that all six documentation files were created

**Critical:** Keep your log entry concise yet informative. Focus on the most important standards established and any significant decisions made to ensure cross-platform compatibility.

## 6. Clarification Instruction

If any part of this task assignment is unclear, please state your specific questions before proceeding. Pay special attention to:
- Any uncertainty about balancing platform-specific needs with cross-platform consistency
- Questions about specific technology stack best practices
- Clarification needed on the scope of any standard