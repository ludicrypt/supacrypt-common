# Supacrypt Project Memory Bank

This directory contains the Memory Bank for the Supacrypt project, organized according to the APM (Agentic Project Management) framework.

## Structure Overview

The Memory Bank is organized by project phases, with each phase containing individual task logs:

```
Memory/
├── README.md (this file)
├── Phase_1_Foundation/
├── Phase_2_Backend_Service/
├── Phase_3_PKCS11_Provider/
├── Phase_4_Windows_Providers/
└── Phase_5_macOS_Provider/
```

## Purpose

Each log file serves as a chronological record of:
- Implementation decisions and rationale
- Code snippets and technical details
- Problems encountered and solutions
- Testing results and observations
- Important discoveries or insights

## Naming Convention

Log files follow the pattern: `Task_X_Y_Description_Log.md`
- X: Phase number
- Y: Task number within the phase
- Description: Brief task identifier

## Usage Guidelines

1. Implementation Agents should log all significant actions in their assigned task log
2. Entries should be timestamped and include the agent identifier
3. Code snippets should be properly formatted with language tags
4. Each log should maintain chronological order
5. Cross-references to other logs should use relative paths

## Log Entry Format

All log entries must follow the format specified in `prompts/02_Utility_Prompts_And_Format_Definitions/Memory_Bank_Log_Format.md`