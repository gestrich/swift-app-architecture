# Swift Experiment Repos Inventory

**Source:** GitHub `gestrich/*` repositories (excluding GoldenPath, already inventoried)
**Surveyed:** 2026-02-15

## Overview

Bill has 80+ repos on GitHub. This inventory focuses on Swift repos with experiment/learning value that could become skills or be absorbed into existing skills. Repos are categorized by skill potential.

## High Potential — Strong Skill Candidates

### 1. SwiftCLI
- **Repo:** [gestrich/SwiftCLI](https://github.com/gestrich/SwiftCLI)
- **Description:** Framework for building type-safe CLI tool wrappers using Swift macros
- **Language:** Swift | **Updated:** 2026-02-12
- **Key Patterns:**
  - `@CLIProgram`, `@CLICommand`, `@Flag`, `@Option`, `@Positional` macros
  - Declarative command definitions as Swift types
  - Async execution via `CLIClient`
  - Structured output parsing
- **Skill Potential:** **High** — Could become a `swift-cli` skill covering CLI app patterns, macro-based DSLs, and type-safe command wrappers. Already follows clean architecture. Used by other Bill projects (PRRadar).
- **Overlap:** None with existing skills

### 2. swift-lambda-sample
- **Repo:** [gestrich/swift-lambda-sample](https://github.com/gestrich/swift-lambda-sample)
- **Description:** Complete serverless app using Swift on AWS Lambda
- **Language:** Swift | **Updated:** 2026-01-04
- **Key Patterns:**
  - AWS Lambda with API Gateway, DynamoDB, RDS (PostgreSQL), S3, SQS, Secrets Manager
  - VPC configuration with public/private subnets
  - Infrastructure-as-code via AWS CDK (TypeScript)
  - CI/CD with GitHub Actions
  - Custom CLIApp for deployment management
  - Mac app companion for deployment
- **Skill Potential:** **High** — Natural fit for a `swift-lambda` skill. Covers the full lifecycle: build, deploy, test, CI/CD. Bill's reorg plan explicitly mentions wanting an AWS Lambda skill.
- **Overlap:** None with existing skills

### 3. PRRadar
- **Repo:** [gestrich/PRRadar](https://github.com/gestrich/PRRadar)
- **Description:** AI-powered PR review tool using Claude Agent SDK
- **Language:** Swift | **Updated:** 2026-02-14
- **Key Patterns:**
  - 4-layer architecture (explicitly follows swift-app-architecture)
  - Pipeline pattern: diff → rules → evaluate → report → comment
  - Python bridge for Claude Agent SDK integration
  - JSON Schema validation for structured AI outputs
  - Rule-based filtering with regex patterns
  - Both SwiftUI GUI and CLI entry points
- **Skill Potential:** **Medium-High** — More of a reference app than a skill source, but demonstrates advanced patterns: Swift/Python bridging, pipeline architecture, structured AI outputs. Could contribute patterns to architecture skill.
- **Overlap:** Follows `swift-architecture` patterns (validates them)

### 4. xcode-sim-automation (XCUITestControl)
- **Repo:** [gestrich/xcode-sim-automation](https://github.com/gestrich/xcode-sim-automation)
- **Description:** File-based interactive control of iOS apps through XCUITest for AI agents
- **Language:** Swift | **Updated:** 2026-02-12
- **Key Patterns:**
  - JSON protocol for AI → XCUITest communication
  - Polling loop architecture
  - UI hierarchy snapshot + screenshot capture
  - CLI ↔ XCUITest bridge pattern
- **Skill Potential:** **Medium** — Niche but could become a `swift-xcuitest-automation` skill for AI-driven UI testing. Unique approach not covered elsewhere.
- **Overlap:** Related to `swift-snapshot-testing` skill (different approach)

## Medium Potential — Useful Patterns

### 5. background-processing-experiments
- **Repo:** [gestrich/background-processing-experiments](https://github.com/gestrich/background-processing-experiments)
- **Description:** iOS app demonstrating background capabilities
- **Language:** Swift | **Updated:** 2025-08-30
- **Key Patterns:**
  - BGAppRefreshTask, BGProcessingTask usage
  - Background URL Session downloads
  - Background audio for continuous execution
  - SwiftData persistence for tracking task execution
  - Debug mode for immediate testing
- **Skill Potential:** **Medium** — Could contribute a "background processing" section to a broader iOS skill. Covers an area many developers struggle with.
- **Overlap:** None

### 6. SwiftEverywhere
- **Repo:** [gestrich/SwiftEverywhere](https://github.com/gestrich/SwiftEverywhere)
- **Description:** Cross-platform Swift project (iOS, Lambda, Raspberry Pi, Vapor)
- **Language:** Swift | **Updated:** 2024-12-24
- **Key Patterns:**
  - Shared Swift Package (`SECommon`) across all platforms
  - Swift Lambda handlers
  - Vapor server
  - Raspberry Pi GPIO/hardware integration
  - Docker deployment
  - GitHub Actions CI/CD
- **Skill Potential:** **Medium** — Demonstrates cross-platform code sharing. Lambda and Vapor patterns may overlap with swift-lambda-sample. The shared package approach is interesting.
- **Overlap:** Partial with swift-lambda-sample

### 7. vapor-terraform-sample / sample-vapor-app
- **Repos:** [gestrich/vapor-terraform-sample](https://github.com/gestrich/vapor-terraform-sample), [gestrich/sample-vapor-app](https://github.com/gestrich/sample-vapor-app)
- **Description:** Vapor server-side Swift examples
- **Language:** Swift | **Updated:** 2022-07 / 2021-11
- **Key Patterns:**
  - Vapor app setup
  - Terraform infrastructure-as-code
- **Skill Potential:** **Medium** — Bill's reorg plan mentions wanting a Vapor skill. These are older but provide a starting point.
- **Overlap:** None

### 8. swift-server-utilities
- **Repo:** [gestrich/swift-server-utilities](https://github.com/gestrich/swift-server-utilities)
- **Description:** Helpers for NIO and AWS Lambda Runtime
- **Language:** Swift | **Updated:** 2021-11
- **Key Patterns:**
  - NIO helpers
  - Lambda runtime utilities
- **Skill Potential:** **Low-Medium** — Utility library, may have patterns worth extracting for Lambda/server skills.
- **Overlap:** Related to swift-lambda-sample

## Low Potential — Reference Only

### 9. claude-tools-skills
- **Repo:** [gestrich/claude-tools-skills](https://github.com/gestrich/claude-tools-skills)
- **Description:** Skills for Claude tools (planning, next-task, review)
- **Language:** Swift | **Updated:** 2026-02-15
- **Skill Potential:** **Low** — Already integrated as skills in the current setup. Not Swift learning content.

### 10. LoopCaregiver
- **Repo:** [gestrich/LoopCaregiver](https://github.com/gestrich/LoopCaregiver)
- **Description:** iOS/watchOS app for remote insulin delivery monitoring
- **Language:** Swift | **Updated:** 2026-02-01
- **Skill Potential:** **Low** — Domain-specific medical app. Large codebase but patterns are Loop ecosystem-specific (fork of LoopKit).

### 11. SwiftRestTools
- **Repo:** [gestrich/SwiftRestTools](https://github.com/gestrich/SwiftRestTools)
- **Description:** REST API tools (WIP)
- **Language:** Swift | **Updated:** 2025-10
- **Skill Potential:** **Low** — Minimal content, WIP status.

### 12. swift-utilities
- **Repo:** [gestrich/swift-utilities](https://github.com/gestrich/swift-utilities)
- **Description:** NS* and Swift helpers
- **Language:** Swift | **Updated:** 2024-01
- **Skill Potential:** **Low** — Generic utility library, no authored principles.

### 13. Other Swift repos (minimal skill value)
- **BillTestApp** — Test app scaffold
- **Claude-Code-Test** — Test project
- **ShareSheetSample** — Share sheet demo
- **git-swift** — Git client in Swift
- **Jira-Swift** — Jira API client
- **slack-swift** — Slack client
- **FFGitClient** — Experimental git client
- **Swift-Lambda-M1** — M1 Lambda build demo (superseded by swift-lambda-sample)
- **SwiftCharts** — Charts library
- **WaterMonitor** — IoT project
- **SlideButton** — UI component
- **SwiftyGPIO** — Raspberry Pi GPIO library (fork)
- **Loop/LoopKit** — Insulin delivery (forks)

## Recommendations for Skill Creation

### Priority 1: New Skills (align with Bill's reorg plan)
| Proposed Skill | Primary Source Repo(s) | Status |
|---------------|----------------------|--------|
| `swift-cli` | SwiftCLI | Ready — well-documented, macro-based patterns |
| `swift-lambda` | swift-lambda-sample, SwiftEverywhere | Ready — comprehensive, includes CDK + CI/CD |
| `swift-vapor` | vapor-terraform-sample, sample-vapor-app, SwiftEverywhere | Needs work — older repos, may need updating |

### Priority 2: Patterns to Absorb into Existing Skills
| Pattern | Source | Target Skill |
|---------|--------|-------------|
| Pipeline architecture | PRRadar | `swift-architecture` (as an example pattern) |
| Swift/Python bridging | PRRadar | New sub-doc or standalone |
| Background processing | background-processing-experiments | Could be `swift-ios-background` or section in broader iOS skill |
| AI-driven XCUITest | xcode-sim-automation | `swift-snapshot-testing` or new skill |

### Priority 3: Reference Apps (validate architecture, not skill sources)
- PRRadar — validates 4-layer architecture in practice
- GetRicher — validates architecture for macOS apps
- LoopCaregiver — large real-world Swift app (domain-specific)

## Content NOT Found (Gaps)
These were mentioned in Bill's reorg plan but don't have dedicated repos:
- **watchOS patterns** — only LoopCaregiver has watchOS, very domain-specific
- **Widget development** — no dedicated repo found
- **SwiftData patterns** — background-processing-experiments uses SwiftData but no authored principles
