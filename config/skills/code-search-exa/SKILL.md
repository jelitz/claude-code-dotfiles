---
name: code-search-exa
description: Code context using Exa. Finds real snippets and docs from GitHub, StackOverflow, and technical docs. Use when searching for code examples, API syntax, library documentation, or debugging help.
context: fork
---

# Code Context (Exa)

## Tool Restriction

ONLY use `web_search_exa`. Do NOT use other Exa tools.

## Token Isolation

This skill runs in a forked context (`context: fork`), so raw Exa results stay out of the main conversation. Call `web_search_exa` here, deduplicate near-identical results (mirrors, forks, repeated StackOverflow answers), and return only copyable snippets with their constraints and a brief explanation.

## When to Use

Use this when a task needs real snippets or docs from outside the repository:
- API usage and syntax
- SDK/library examples
- config and setup patterns
- framework "how to" questions
- debugging when you need authoritative snippets

## Query Writing Patterns (High Signal)

To reduce irrelevant results and cross-language noise:
- Always include the **programming language** in the query.
  - Example: use **"Go generics"** instead of just **"generics"**.
- When applicable, also include **framework + version** (e.g., "Next.js 14", "React 19", "Python 3.12").
- Include exact identifiers (function/class names, config keys, error messages) when you have them.

## Output Format (Recommended)

Return:
1) Best minimal working snippet(s) (keep it copy/paste friendly)
2) Notes on version / constraints / gotchas
3) Sources (URLs if present in returned context)

Before presenting:
- Deduplicate similar results and keep only the best representative snippet per approach.

## MCP Configuration

```json
{
  "servers": {
    "exa": {
      "type": "http",
      "url": "https://mcp.exa.ai/mcp?tools=web_search_exa"
    }
  }
}
```
