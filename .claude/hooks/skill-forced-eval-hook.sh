#!/bin/bash

# Forced Eval Hook for Claude Code Skills
# 84% activation rate vs 20% for simple instruction
# Reference: https://scottspence.com/posts/claude-code-skill-activation-testing

cat << 'EOF'

=== MANDATORY SKILL EVALUATION ===

Before proceeding with ANY implementation, you MUST complete these steps IN ORDER:

Step 1 - EVALUATE: For EACH available skill below, explicitly state YES or NO with a brief reason:

Available Skills:
- context-loader: Context file loader for code/backend/frontend/docs tasks
  Triggers: create, implement, build, add, fix, refactor, update, modify, write,
            API, endpoint, route, controller, service, repository, database, DB,
            component, page, UI, form, FastAPI, Flutter, Spring Boot

For EACH skill above, write:
"[skill-name]: YES/NO - [one sentence reason based on the user's request]"

Step 2 - ACTIVATE: For every skill you marked YES, you MUST use Skill(skill-name) tool NOW.
Do NOT skip this step. Do NOT proceed to implementation without activating.

Step 3 - IMPLEMENT: Only AFTER activation, proceed with the user's request.

CRITICAL: The evaluation in Step 1 is WORTHLESS unless you complete Step 2.
Skipping activation after saying YES is a FAILURE.

=== END MANDATORY EVALUATION ===

EOF
