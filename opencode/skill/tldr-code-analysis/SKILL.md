---
name: tldr-code-analysis
description: >
  Code analysis tool that delivers 90-95% token savings vs reading files directly. 
  Use FIRST when exploring unfamiliar codebases to understand structure before reading files.
  Provides semantic search, architecture discovery, and dependency analysis for Python, 
  TypeScript, JavaScript, Go, Rust, Java, and R.
---

# TLDR Code Analysis Skill

**Save 90-95% of tokens** by using TLDR's structural analysis instead of reading raw files. This tool helps you understand codebase architecture, find specific functions, trace call graphs, and perform impact analysis—**always use BEFORE reading files** to focus your investigation.

## 🚀 Value Proposition: Navigate First, Read Targeted

**The 90-95% Token Savings Rule:** Reading a typical 500-line file costs ~2,000 tokens. TLDR's structural analysis of the same file costs ~100-200 tokens—**a 90-95% reduction** that reveals function signatures, dependencies, and relationships without file content.

**Default Workflow:** `TLDR Navigate → Read Targeted Files → Implement`

## Decision Tree: When to Use TLDR vs Read/Grep

```
Need to understand codebase structure?
├─ Yes → Use TLDR structure/arch commands
└─ No → Need specific code details?
    ├─ Yes → Do you know exact file/location?
    │   ├─ Yes → Read the file directly
    │   └─ No → Use TLDR semantic search first
    └─ No → Need to find patterns/relationships?
        ├─ Yes → Use TLDR (calls/impact/arch)
        └─ No → Use grep for simple text search
```

## Agent-Specific Guidance

### For Exploration Agents
**Mission:** Map unfamiliar territory efficiently
- **Start with:** `tldr structure . --max 20` to get oriented
- **Then:** `tldr semantic search "your topic"` to find relevant code
- **Finally:** Read only the files TLDR identifies as relevant
- **Token budget:** 500-1,000 tokens for initial exploration vs 10,000+ for blind reading

### For Orchestrator Agents  
**Mission:** Coordinate complex analysis across multiple files
- **Use TLDR to:** Identify which files contain relevant functions
- **Delegate to:** Subagents with specific file targets
- **Combine results:** From targeted reads, not broad exploration
- **Pattern:** `TLDR → delegate specific files → synthesize`

## When NOT to Use TLDR

**Skip TLDR when:**
- You already know the exact file and location you need
- You're making minor edits to familiar code
- You need to see actual implementation details immediately
- The codebase is tiny (<5 files)
- You're debugging syntax errors line-by-line

**Use raw file reads when:**
- You have specific line numbers from error messages
- You need to see variable names, comments, or exact logic
- You're reviewing PR changes (use git diff instead)
- TLDR already identified the target file and you need implementation details

## Core Commands Reference

### 🔍 Quick Start: Essential Navigation
```bash
# 1. Get oriented - 95% token savings vs reading all files
uvx --from 'git+https://github.com/sims1253/llm-tldr@dev[r]' tldr structure . --lang r --max 20

# 2. Find relevant code without reading files
uvx --from 'git+https://github.com/sims1253/llm-tldr@dev' tldr semantic search "input validation" --k 3

# 3. Understand relationships before touching code
uvx --from 'git+https://github.com/sims1253/llm-tldr@dev[r]' tldr impact function_name . --lang r
```

### Project Structure Analysis
Understand organization without reading files:
```bash
uvx --from 'git+https://github.com/sims1253/llm-tldr@dev[r]' tldr structure . --lang r --max 20
```
**When:** Always your first command in unfamiliar codebases. Reveals entry points, module organization, and architectural patterns in ~200 tokens vs thousands for file reads.

### Semantic Search
Find code by purpose, not exact text:
```bash
uvx --from 'git+https://github.com/sims1253/llm-tldr@dev' tldr semantic search "database connection pooling" --k 5
```
**When:** You know what the code should do but not what it's called. Build index first with `tldr semantic index --lang python .`

### Call Graph & Impact Analysis
Trace relationships before making changes:
```bash
# What calls this function?
uvx --from 'git+https://github.com/sims1253/llm-tldr@dev[r]' tldr impact target_function . --lang r

# What does this function call?
uvx --from 'git+https://github.com/sims1253/llm-tldr@dev' tldr calls . --lang python
```
**When:** Before modifying code to understand ripple effects. Prevents breaking changes by mapping dependencies first.

## Navigate → Read Workflow Pattern

**Efficient Investigation Pattern:**
1. **Navigate with TLDR** (200 tokens) → Understand structure and find targets
2. **Read targeted files** (500 tokens) → Get implementation details  
3. **Analyze with TLDR** (100 tokens) → Trace relationships and impact
4. **Read specific sections** (200 tokens) → Focus on relevant code only

**Total:** ~1,000 tokens vs 5,000+ for blind exploration

### Example Workflow
```bash
# Step 1: Navigate - understand the landscape
uvx --from 'git+https://github.com/sims1253/llm-tldr@dev[r]' tldr structure . --lang r --max 15

# Step 2: Search - find relevant functions  
uvx --from 'git+https://github.com/sims1253/llm-tldr@dev' tldr semantic search "data validation" --k 3

# Step 3: Analyze - understand impact before changes
uvx --from 'git+https://github.com/sims1253/llm-tldr@dev[r]' tldr impact validate_user_input . --lang r

# Step 4: Read - only the files you identified
# Now read ./R/validation.R since TLDR showed it's relevant
```

## Language Support & Configuration

### Supported Languages
- **Python** (.py) - Full analysis including async/await patterns
- **TypeScript/JavaScript** (.ts, .tsx, .js, .jsx) - React component analysis
- **Go** (.go) - Goroutine and channel patterns  
- **Rust** (.rs) - Ownership and lifetime analysis
- **Java** (.java) - Spring framework patterns
- **R** (.R, .r) - Enhanced support with tidyverse patterns

### R-Specific Enhancements
```bash
# Use [r] extra for R projects
uvx --from 'git+https://github.com/sims1253/llm-tldr@dev[r]' tldr <command>
```

**R-exclusive features:**
- Control Flow Graph (CFG) for complex functions
- Data Flow Graph (DFG) for variable tracking
- Program slicing for variable impact analysis
- S7 class system support
- Tidyverse pattern recognition

## Performance & Caching

### Warm Cache for Interactive Sessions
```bash
uvx --from 'git+https://github.com/sims1253/llm-tldr@dev' tldr warm .
```
**When:** Starting analysis sessions on large codebases. Pre-loads analysis data for faster subsequent queries.

### Semantic Index (One-time Setup)
```bash
uvx --from 'git+https://github.com/sims1253/llm-tldr@dev[r]' tldr semantic index --lang r .
```
**When:** Before first semantic search on a project. Rebuild when codebase changes significantly.

## Integration Patterns

### Multi-Agent Workflows
**Orchestrator Pattern:**
1. Main agent uses TLDR to map codebase and identify targets
2. Subagents receive specific file targets for detailed analysis
3. Results synthesized from focused investigations

**Example:**
```bash
# Main agent: Map the territory
uvx --from 'git+https://github.com/sims1253/llm-tldr@dev[r]' tldr semantic search "authentication middleware" --k 5

# Delegate to subagent: "Analyze auth.R and middleware.R for security patterns"
# Subagent reads specific files identified by TLDR
```

### Command Chaining for Comprehensive Analysis
```bash
# Quick comprehensive overview (500 tokens total)
uvx --from 'git+https://github.com/sims1253/llm-tldr@dev[r]' tldr structure . --lang r --max 20
uvx --from 'git+https://github.com/sims1253/llm-tldr@dev[r]' tldr arch . --lang r
uvx --from 'git+https://github.com/sims1253/llm-tldr@dev[r]' tldr semantic search "main entry point" --k 3
```

## Best Practices Summary

1. **Always navigate first** - Use TLDR before reading any files in unfamiliar codebases
2. **Specify language** - Use `--lang` flag for accurate analysis
3. **Build semantic index once** - Before using natural language searches
4. **Warm cache for large projects** - Speeds up interactive analysis sessions
5. **Use impact analysis before changes** - Prevent breaking changes by understanding dependencies
6. **Read files last** - Only after TLDR identifies what's relevant to your task

**Remember:** TLDR is your codebase GPS. Use it to navigate efficiently, then read only what you need.