# Extract swift-lambda Skill from swift-lambda-sample Repo

## Relevant Skills

| Skill | Description |
|-------|-------------|
| `swift-architecture` | 4-layer Swift app architecture — placement guidance and code style |

## Background

Bill's [swift-lambda-sample](https://github.com/gestrich/swift-lambda-sample) repo is a complete serverless app using Swift on AWS Lambda. It covers API Gateway, DynamoDB, RDS (PostgreSQL), S3, SQS, Secrets Manager, VPC configuration, AWS CDK infrastructure-as-code, CI/CD with GitHub Actions, and a custom CLIApp for deployment. Bill's reorg plan explicitly mentions wanting an AWS Lambda skill. Additional Lambda patterns exist in [SwiftEverywhere](https://github.com/gestrich/SwiftEverywhere) and [swift-server-utilities](https://github.com/gestrich/swift-server-utilities).

**Source repos:**
- https://github.com/gestrich/swift-lambda-sample (primary)
- https://github.com/gestrich/SwiftEverywhere (supplementary)
- https://github.com/gestrich/swift-server-utilities (supplementary)

## Phases

## - [ ] Phase 1: Deep-dive Lambda patterns

**Skills to read**: `swift-architecture`

Read swift-lambda-sample in detail. Document:
- Lambda handler patterns and runtime setup
- AWS service integrations (DynamoDB, RDS, S3, SQS, Secrets Manager)
- VPC and networking configuration
- CDK infrastructure-as-code approach
- CI/CD pipeline structure
- Deployment CLIApp patterns
- Any patterns from SwiftEverywhere or swift-server-utilities worth including

Produce a summary of extractable patterns.

## - [ ] Phase 2: Create swift-lambda skill

**Skills to read**: `swift-architecture`

Create `plugin/skills/swift-lambda/SKILL.md` covering:
- Project setup and dependencies (swift-aws-lambda-runtime, Soto)
- Lambda handler patterns (async handler, Codable events)
- AWS service integration patterns
- Infrastructure-as-code with CDK
- VPC and networking
- CI/CD with GitHub Actions
- Deployment workflow
- Layer placement guidance
- Code examples

## - [ ] Phase 3: Validation

Review the new skill for:
- Accuracy against the source repos
- Consistency with existing skill format
- No duplication with existing skills
- Practical usefulness (could someone build a Swift Lambda from this?)
