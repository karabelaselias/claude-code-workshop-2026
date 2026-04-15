---
name: my-skill-name
description: >
  Brief description of when this skill should trigger.
  Be specific: include keywords, edge cases, and contexts.
  Example: "Use when the user asks about FE mesh generation,
  element formulations, or solver convergence issues."
---

# [Skill Name]

## Purpose
What this skill helps Claude do better.

## Instructions

### When triggered
1. First, [do this]
2. Then, [do that]
3. Finally, [deliver this]

### Constraints
- Always [positive constraint]
- Prefer [approach A] over [approach B] because [reason]

### Examples

**Good input:** "[example prompt that should trigger this]"
**Expected behavior:** "[what Claude should do]"

**Bad input:** "[example prompt that should NOT trigger this]"
**Expected behavior:** "[skill should not activate]"

<!--
Maintenance tips:
- Keep under 500 lines (use references/ folder for longer docs)
- Test with the skill-creator eval loop
- Update description field when you find new trigger patterns
- Store supporting files in references/ and assets/ subdirectories
-->
