# APM Task Assignment: Design and Implement Shared Protobuf Definition

## 1. Agent Role & APM Context

**Introduction:** You are activated as an Implementation Agent - Protobuf Specialist within the Agentic Project Management (APM) framework for the Supacrypt cryptographic software suite project.

**Your Role:** As an Implementation Agent, you are responsible for executing assigned tasks diligently, implementing solutions according to specifications, and meticulously logging your work to the Memory Bank for project tracking and continuity.

**Workflow:** You will work under the guidance of the Manager Agent (communicated via the User), following the Implementation Plan and contributing to the project's Memory Bank located at `./Memory/`.

## 2. Task Assignment

**Reference Implementation Plan:** This assignment corresponds to **Phase 1: Foundation & Core Infrastructure, Task 1.1: Design and Implement Shared Protobuf Definition** in the Implementation Plan.

**Objective:** Design and create the `supacrypt.proto` file that defines the gRPC service interface between all crypto providers (PKCS#11, CSP, KSP, CTK) and the backend service.

**Detailed Action Steps:**

1. **Analyze cryptographic API requirements:**
   - Research and document the key operation requirements from:
     - PKCS#11 (Cryptoki) standard for cross-platform crypto operations
     - Windows CAPI CSP interface requirements
     - Windows CNG KSP interface requirements
     - macOS CryptoTokenKit (CTK) framework requirements
     - Azure Key Vault API capabilities and limitations
   - Focus specifically on RSA and ECC/ECDSA asymmetric operations
   - Document any API-specific constraints that must be accommodated

2. **Design message structures for cryptographic operations:**
   - Create request/response messages for key generation:
     - Support RSA key sizes (2048, 3072, 4096 bits)
     - Support ECC curves (P-256, P-384, P-521)
     - Include key metadata (key ID, creation time, algorithm parameters)
   - Design signing operation messages:
     - Support various padding schemes for RSA (PKCS#1, PSS)
     - Support hash algorithms (SHA-256, SHA-384, SHA-512)
     - Handle both raw data and pre-hashed inputs
   - Create verification operation messages:
     - Mirror signing operation structures
     - Include signature validation results
   - Implement key management messages:
     - Key listing and retrieval
     - Key deletion (where supported)
     - Key metadata updates
   - Design comprehensive error handling structures:
     - Standard error codes mapping to provider-specific errors
     - Detailed error messages for debugging
     - Operation-specific error contexts

3. **Define gRPC service methods:**
   - Use unary RPC calls exclusively (no streaming)
   - Implement the following service methods:
     ```
     service SupacryptService {
       rpc GenerateKey(GenerateKeyRequest) returns (GenerateKeyResponse);
       rpc SignData(SignDataRequest) returns (SignDataResponse);
       rpc VerifySignature(VerifySignatureRequest) returns (VerifySignatureResponse);
       rpc GetKey(GetKeyRequest) returns (GetKeyResponse);
       rpc ListKeys(ListKeysRequest) returns (ListKeysResponse);
       rpc DeleteKey(DeleteKeyRequest) returns (DeleteKeyResponse);
     }
     ```
   - Ensure all methods have proper error handling returns

4. **Implement versioning and extensibility:**
   - Use protobuf package naming: `supacrypt.v1`
   - Reserve field numbers for future extensions
   - Use `oneof` fields where algorithm-specific parameters are needed
   - Include a version field in all request messages
   - Design for backward compatibility

5. **Document the protobuf definition:**
   - Add comprehensive comments for every message and field
   - Include usage examples in comments
   - Document any Azure Key Vault specific limitations
   - Explain the rationale for design decisions

**Provide Necessary Context/Assets:**
- Location for the protobuf file: `supacrypt-common/proto/supacrypt.proto`
- Use proto3 syntax
- Follow Google's protobuf style guide for naming conventions
- Consider message size implications for performance
- Ensure all timestamps use google.protobuf.Timestamp
- Use appropriate protobuf types for binary data (bytes) and enums for algorithm selections

## 3. Expected Output & Deliverables

**Define Success:** 
- A complete, well-documented `supacrypt.proto` file that can serve as the contract between all crypto providers and the backend service
- The protobuf must compile without errors using protoc
- All cryptographic operations required by the various providers must be representable

**Specify Deliverables:**
1. Created file: `supacrypt-common/proto/supacrypt.proto`
2. The protobuf definition should include:
   - All message definitions for requests/responses
   - The gRPC service definition
   - Comprehensive documentation comments
   - Proper package and import statements

## 4. Memory Bank Logging Instructions

**Instruction:** Upon successful completion of this task, you **must** log your work comprehensively to the Memory Bank file at `./Memory/Phase_1_Foundation/Task_1_1_Protobuf_Design_Log.md`.

**Format Adherence:** Adhere strictly to the established logging format as defined in the Memory Bank Log Format guide. Ensure your log includes:
- Task Reference: "Phase 1 / Task 1.1 / Design and Implement Shared Protobuf Definition"
- A clear description of the design decisions made
- Key protobuf message structures created
- Any challenges encountered in accommodating all provider requirements
- Confirmation that the protobuf compiles successfully

**Critical:** Keep your log entry concise yet informative. Focus on key design decisions, important message structures, and any trade-offs made to accommodate different provider APIs.

## 5. Clarification Instruction

If any part of this task assignment is unclear, please state your specific questions before proceeding. Pay special attention to:
- Any ambiguity in API requirements across different providers
- Uncertainty about Azure Key Vault limitations
- Questions about protobuf best practices for this use case