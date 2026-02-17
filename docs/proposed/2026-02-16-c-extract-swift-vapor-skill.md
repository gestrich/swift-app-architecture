# Extract swift-vapor Skill from Vapor Repos

## Relevant Skills

| Skill | Description |
|-------|-------------|
| `swift-architecture` | 4-layer Swift app architecture — placement guidance and code style |

## Background

Bill has two Vapor-related repos: [vapor-terraform-sample](https://github.com/gestrich/vapor-terraform-sample) and [sample-vapor-app](https://github.com/gestrich/sample-vapor-app), plus Vapor usage in [SwiftEverywhere](https://github.com/gestrich/SwiftEverywhere). These are older (2021-2022) but Bill's reorg plan explicitly mentions wanting a Vapor skill. The repos cover Vapor app setup and Terraform infrastructure-as-code. Content may need updating to modern Vapor conventions.

**Source repos:**
- https://github.com/gestrich/vapor-terraform-sample (primary)
- https://github.com/gestrich/sample-vapor-app (primary)
- https://github.com/gestrich/SwiftEverywhere (supplementary — Vapor server component)

## Phases

## - [ ] Phase 1: Deep-dive Vapor patterns

**Skills to read**: `swift-architecture`

Read both Vapor repos and the SwiftEverywhere Vapor component. Document:
- Vapor app setup and configuration
- Route definitions and controller patterns
- Middleware usage
- Database integration (Fluent ORM)
- Terraform infrastructure-as-code
- Docker deployment
- Any patterns worth preserving vs. patterns that are outdated

Note which patterns are still current vs. need modernization.

## - [ ] Phase 2: Create swift-vapor skill

**Skills to read**: `swift-architecture`

Create `plugin/skills/swift-vapor/SKILL.md` covering:
- Project setup and dependencies
- Route and controller patterns
- Middleware
- Database with Fluent
- Infrastructure-as-code (Terraform)
- Deployment (Docker, cloud)
- Layer placement guidance
- Code examples

Flag any sections where the source repos are outdated and Bill's input is needed.

## - [ ] Phase 3: Validation

Review the new skill for:
- Accuracy against the source repos
- Consistency with existing skill format
- Clear indication of which patterns may need updating
- Practical usefulness
