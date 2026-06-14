# Flags

Behavioral flags for Claude Code to enable specific execution modes and tool selection patterns.

## Execution Control Flags

**--loop**

- Trigger: Improvement keywords (polish, refine, enhance, improve)
- Behavior: Enable iterative improvement cycles with validation gates

**--iterations [n]**

- Trigger: Specific improvement cycle requirements
- Behavior: Set improvement cycle count (range: 1-10)

## Analysis Depth Flags

**--ultrathink**

- Trigger: Critical system redesign, legacy modernization, complex debugging
- Behavior: Maximum depth analysis (~32K tokens), enables all MCP servers

## MCP Server Flags

**--c7 / --context7**

- Trigger: Library imports, framework questions, official documentation needs
- Behavior: Enable Context7 for curated documentation lookup and pattern guidance

**--serena**

- Trigger: Symbol operations, project memory needs, large codebase navigation
- Behavior: Enable Serena for semantic understanding and session persistence

## Framework Flags

**--FLUTTER**

- Trigger: FLUTTER 프로젝트 개발/수정 작업
- Behavior: Load @.claude/core/TOSS_FE_GUIDLINES.md + @.claude/core/FRONTEND.md + @.claude/framework/FLUTTER.md

**--SPRING_BOOT**

- Trigger: SPRING_BOOT 프로젝트 개발/테스트 작업
- Behavior: Load @.claude/framework/SPRING_BOOT.md + @.claude/core/BACKEND.md

**--FASTAPI**

- Trigger: FASTAPI 프로젝트 개발/수정 작업
- Behavior: Load @.claude/framework/FASTAPI.md + @.claude/core/BACKEND.md

## Documentation Flags

**--mdx**

- Trigger: MDX/Mermaid 문서 작성/수정
- Behavior: Load @.claude/core/MDX.md
