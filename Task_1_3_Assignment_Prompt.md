# APM Task Assignment: Initialize Repository Structures

## 1. Agent Role & APM Context

**Introduction:** You are activated as an Implementation Agent - DevOps Specialist within the Agentic Project Management (APM) framework for the Supacrypt cryptographic software suite project.

**Your Role:** As an Implementation Agent, you are responsible for executing assigned tasks diligently, implementing solutions according to specifications, and meticulously logging your work to the Memory Bank for project tracking and continuity.

**Workflow:** You will work under the guidance of the Manager Agent (communicated via the User), following the Implementation Plan and contributing to the project's Memory Bank located at `./Memory/`.

## 2. Onboarding / Context from Prior Work

**Previous Tasks Context:**
- Task 1.1: The protobuf definition has been created at `supacrypt-common/proto/supacrypt.proto`, establishing the gRPC service interface for all components
- Task 1.2: Project-wide standards and conventions are being established (or have been established) in `supacrypt-common/docs/standards/`

These foundations provide the structure and guidelines that the repository initialization must support and enforce.

## 3. Task Assignment

**Reference Implementation Plan:** This assignment corresponds to **Phase 1: Foundation & Core Infrastructure, Task 1.3: Initialize Repository Structures** in the Implementation Plan.

**Objective:** Set up the basic structure for all six repositories with appropriate tooling and configurations.

**Detailed Action Steps:**

1. **Create directory structures for each repository:**
   
   For **supacrypt-common**:
   ```
   supacrypt-common/
   ├── proto/              (already has supacrypt.proto)
   ├── docs/
   │   ├── standards/      (being populated by Task 1.2)
   │   └── architecture/
   ├── scripts/
   └── shared/
   ```

   For **supacrypt-backend-akv** (.NET structure):
   ```
   supacrypt-backend-akv/
   ├── src/
   │   ├── Supacrypt.Backend/
   │   └── Supacrypt.Backend.Tests/
   ├── tests/
   │   └── Supacrypt.Backend.IntegrationTests/
   └── scripts/
   ```

   For **supacrypt-pkcs11** (C++ structure):
   ```
   supacrypt-pkcs11/
   ├── include/
   │   └── supacrypt/
   ├── src/
   ├── tests/
   ├── examples/
   └── cmake/
   ```

   For **supacrypt-csp** (Windows C++ structure):
   ```
   supacrypt-csp/
   ├── include/
   ├── src/
   ├── tests/
   ├── installer/
   └── tools/
   ```

   For **supacrypt-ksp** (Windows C++ structure):
   ```
   supacrypt-ksp/
   ├── include/
   ├── src/
   ├── tests/
   ├── installer/
   └── tools/
   ```

   For **supacrypt-ctk** (macOS structure):
   ```
   supacrypt-ctk/
   ├── SupacryptCTK/
   ├── SupacryptCTKTests/
   ├── SupacryptCTKExtension/
   └── scripts/
   ```

2. **Set up .gitignore files appropriate to each technology:**
   
   Create technology-specific .gitignore files:
   - **supacrypt-common**: General patterns, protobuf generated files
   - **supacrypt-backend-akv**: .NET/Visual Studio patterns (bin/, obj/, *.user, .vs/)
   - **supacrypt-pkcs11**: C++ patterns (build/, *.o, *.so, *.dylib)
   - **supacrypt-csp/ksp**: Windows C++ patterns (Debug/, Release/, *.pdb, *.dll)
   - **supacrypt-ctk**: Xcode/Swift patterns (.DS_Store, xcuserdata/, DerivedData/)
   
   Include common patterns in all:
   - IDE files (.idea/, .vscode/, *.swp)
   - OS files (.DS_Store, Thumbs.db)
   - Backup files (*~, *.bak)
   - Credential files (*.key, *.pem, *.pfx)

3. **Configure editor settings (.editorconfig):**
   
   Create a root .editorconfig in each repository with:
   - Common settings:
     ```
     root = true
     
     [*]
     charset = utf-8
     end_of_line = lf
     insert_final_newline = true
     trim_trailing_whitespace = true
     ```
   
   - Language-specific settings:
     - C++ files: indent_style = space, indent_size = 4
     - C# files: indent_style = space, indent_size = 4
     - Proto files: indent_style = space, indent_size = 2
     - YAML files: indent_style = space, indent_size = 2
     - Markdown files: trim_trailing_whitespace = false

4. **Create initial README files with project descriptions:**
   
   Each README.md should include:
   - Project name and brief description
   - Component's role in the Supacrypt suite
   - Technology stack and requirements
   - Build instructions placeholder
   - Testing instructions placeholder
   - Contributing guidelines reference
   - License information (MIT)
   
   Example structure:
   ```markdown
   # Supacrypt [Component Name]
   
   ## Overview
   [Brief description of component's purpose]
   
   ## Requirements
   - [Technology-specific requirements]
   
   ## Building
   [To be documented]
   
   ## Testing
   [To be documented]
   
   ## Contributing
   See [CONTRIBUTING.md](../supacrypt-common/docs/CONTRIBUTING.md)
   
   ## License
   MIT License - See [LICENSE](LICENSE) for details
   ```

5. **Set up license files (MIT):**
   
   Create LICENSE file in each repository:
   ```
   MIT License
   
   Copyright (c) 2025 ludicrypt
   
   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:
   
   The above copyright notice and this permission notice shall be included in all
   copies or substantial portions of the Software.
   
   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE.
   ```

6. **Prepare CI/CD pipeline templates (GitHub Actions):**
   
   Create `.github/workflows/` directory in each repository with initial workflow templates:
   
   For **supacrypt-backend-akv** (`build-test.yml`):
   ```yaml
   name: Build and Test
   on: [push, pull_request]
   jobs:
     build:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
         - uses: actions/setup-dotnet@v4
           with:
             dotnet-version: '9.0.x'
         # Build and test steps to be added
   ```
   
   For **C++ projects** (pkcs11, csp, ksp):
   ```yaml
   name: Build and Test
   on: [push, pull_request]
   jobs:
     build:
       strategy:
         matrix:
           os: [ubuntu-latest, windows-latest, macos-latest]
       runs-on: ${{ matrix.os }}
       steps:
         - uses: actions/checkout@v4
         # Platform-specific build steps to be added
   ```
   
   For **supacrypt-ctk**:
   ```yaml
   name: Build and Test
   on: [push, pull_request]
   jobs:
     build:
       runs-on: macos-latest
       steps:
         - uses: actions/checkout@v4
         # Xcode build steps to be added
   ```

## 4. Expected Output & Deliverables

**Define Success:**
- All six repositories have consistent, well-organized directory structures
- Appropriate tooling and configuration files are in place
- Foundation is laid for development work in subsequent phases
- All repositories follow the same organizational patterns where applicable

**Specify Deliverables:**
1. Directory structures created in all six repositories
2. Technology-appropriate .gitignore files in each repository
3. .editorconfig files ensuring consistent formatting
4. README.md files with project descriptions
5. LICENSE files with MIT license text
6. GitHub Actions workflow templates in .github/workflows/

## 5. Memory Bank Logging Instructions

**Instruction:** Upon successful completion of this task, you **must** log your work comprehensively to the Memory Bank file at `./Memory/Phase_1_Foundation/Task_1_3_Repository_Setup_Log.md`.

**Format Adherence:** Adhere strictly to the established logging format as defined in the Memory Bank Log Format guide. Ensure your log includes:
- Task Reference: "Phase 1 / Task 1.3 / Initialize Repository Structures"
- Summary of directory structures created
- List of configuration files added to each repository
- Any decisions made regarding technology-specific structures
- Confirmation that all six repositories are initialized

**Critical:** Keep your log entry concise yet informative. Focus on the key structures established and any repository-specific customizations made.

## 6. Clarification Instruction

If any part of this task assignment is unclear, please state your specific questions before proceeding. Pay special attention to:
- Any uncertainty about directory structure conventions for specific technologies
- Questions about platform-specific configuration requirements
- Clarification on the scope of initial setup versus future development needs