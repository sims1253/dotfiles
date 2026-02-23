---
name: pr-recent-comments
description: Fetch GitHub PR comments posted after the last commit in token-efficient TOON format
license: MIT
compatibility: opencode
---

## What I Do

I fetch GitHub PR inline review comments and top-level reviews posted or updated after the last commit, filter out addressed comments, and return them in TOON format for optimal token efficiency.

## When to Use Me

Use this when you need to see PR comments posted after your last commit:

- Getting a quick overview of new review feedback
- Before implementing code review feedback from bots (coderabbitai, greptile, etc.)
- Checking for new comments on recent commits before pushing changes

## Timing Notes

AI review bots (CodeRabbit, Greptile, etc.) typically take 5-15 minutes to process PRs after a push. For large PRs with many changed files, wait at least 10 minutes before fetching comments.

If no comments appear, the bot may still be processing. Try again in a few minutes.

## Output Format (TOON)

### Success with comments

```toon
pr:
  number: 3
  current_commit: "553061d11acced2c6a6bee60a3c5f7df2b284efc"
  commit_timestamp: "2025-12-29T12:22:42Z"
  comments_since: 4
  inline_comments: 3
  top_level_reviews: 1

comments[3]{path,line,body}:
  src/pages/index.astro,198,"Consider extracting the hardcoded width to a CSS custom property."
  src/scripts/theme-toggle.ts,30,"Consider a more specific return type."
  src/scripts/theme-toggle.ts,52,"Consider refining the theme parameter type."

reviews[1]{body}:
  "Actionable comments posted: 3"
```

### No PR found

```toon
error: "No PR found for current branch: dev"
```

### No comments since commit

```toon
pr:
  number: 3
  current_commit: "553061d11acced2c6a6bee60a3c5f7df2b284efc"
  commit_timestamp: "2025-12-29T12:22:42Z"
comments_since: 0
message: "No actionable comments found since last commit"
```

## Error Handling

| Scenario                           | Behavior                                                                                                  |
| ---------------------------------- | --------------------------------------------------------------------------------------------------------- |
| No PR for current branch           | Returns `error: "No PR found for current branch: <branch>"`                                               |
| Cannot detect repo from git remote | Returns `error: "Could not detect repository from git remote"`                                            |
| No comments since last commit      | Returns metadata with `comments_since: 0` and `message: "No actionable comments found since last commit"` |
| `gh` CLI not available             | Assumes it's installed (skill requirement)                                                                |
| Network/API errors                 | Fails fast with gh CLI error message                                                                      |

## Implementation

The implementation is in `fetch-comments.sh`. It fetches both inline review comments (with `path`, `line`, `body`) and top-level reviews (with just `body`) by `updated_at >= commit_timestamp` to catch both new comments and edits, removes addressed comments (those containing "✅ Addressed" or "Addressed in commit"), strips noise like `<details>` blocks, code blocks, suggestions, and emoji badges, then outputs them as separate `comments[]` and `reviews[]` arrays.
