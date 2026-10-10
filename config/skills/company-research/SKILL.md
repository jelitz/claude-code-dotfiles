---
name: company-research
description: Company research using Exa search. Finds company info, competitors, news, financials, LinkedIn profiles, builds company lists. Use when researching companies, doing competitor analysis, market research, or building company lists.
context: fork
---

# Company Research

## Tool Restriction

ONLY use `web_search_advanced_exa`. Do NOT use `web_search_exa` or any other Exa tools.

## Token Isolation

This skill runs in a forked context (`context: fork`), so raw Exa results stay out of the main conversation. Run the searches here and return only distilled output (compact JSON or brief markdown).

## Dynamic Tuning

This skill runs without the conversation history, so the arguments are the only view of the request:
- Arguments give a number → match it
- Arguments ask for comprehensive coverage → 50-100
- Otherwise → 10-20

## Query Variation

Exa returns different results for different phrasings. For coverage:
- Generate 2-3 query variations
- Run in parallel
- Merge and deduplicate

## Categories

Use appropriate Exa `category` depending on what you need:
- `company` → homepages, rich metadata (headcount, location, funding, revenue)
- `news` → press coverage, announcements
- `people` → LinkedIn profiles (public data)
- No category (`type: "auto"`) → general web results, deep dives, broader context

Start with `category: "company"` for discovery, then use other categories or no category for deeper research.

### Category-Specific Filter Restrictions

When using `category: "company"`, these parameters cause 400 errors:
- `includeDomains` / `excludeDomains`
- `startPublishedDate` / `endPublishedDate`
- `startCrawlDate` / `endCrawlDate`

When searching without a category (or with `news`), domain and date filters work fine.

**Universal restriction:** `includeText` and `excludeText` only support **single-item arrays**. Multi-item arrays cause 400 errors across all categories.

## LinkedIn

Public LinkedIn via Exa: `category: "people"`, no other filters.
Auth-required LinkedIn → use Claude in Chrome browser fallback.

## Browser Fallback

Auto-fallback to Claude in Chrome when:
- Exa returns insufficient results
- Content is auth-gated
- Dynamic pages need JavaScript

## Examples

### Discovery: find companies in a space
```
web_search_advanced_exa {
  "query": "AI infrastructure startups San Francisco",
  "category": "company",
  "numResults": 20,
  "type": "auto"
}
```

### Deep dive: research a specific company
```
web_search_advanced_exa {
  "query": "Anthropic funding rounds valuation",
  "type": "deep",
  "numResults": 10,
  "includeDomains": ["techcrunch.com", "crunchbase.com", "bloomberg.com"]
}
```

### News coverage
```
web_search_advanced_exa {
  "query": "Anthropic AI safety",
  "category": "news",
  "numResults": 15,
  "startPublishedDate": "<YYYY-MM-DD, relative to today>"
}
```

### LinkedIn profiles
```
web_search_advanced_exa {
  "query": "VP Engineering AI infrastructure",
  "category": "people",
  "numResults": 20
}
```

## Output Format

Return:
1) Results (structured list; one company per row)
2) Sources (URLs; 1-line relevance each)
3) Notes (uncertainty/conflicts)
