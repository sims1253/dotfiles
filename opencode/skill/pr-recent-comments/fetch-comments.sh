#!/bin/bash
set -euo pipefail

# Argument parsing for --since-commit option
since_commit=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --since-commit)
      since_commit="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

# Use provided commit or default to HEAD
if [ -n "$since_commit" ]; then
  commit_sha="$since_commit"
  commit_timestamp=$(git log -1 --format=%cI "$commit_sha")
else
  commit_sha=$(git rev-parse HEAD)
  commit_timestamp=$(git log -1 --format=%cI)
fi

# Get current branch
branch=$(git branch --show-current)

# Extract repo from git remote
remote_url=$(git config --get remote.origin.url)
repo=$(echo "$remote_url" | sed -E 's/.*github.com[:/](.*)\.git/\1/')
if [ -z "$repo" ]; then
  echo "error: \"Could not detect repository from git remote\""
  exit 0
fi

# Detect PR for current branch
pr_info=$(gh pr view "$branch" --json number 2>/dev/null) || {
  echo "error: \"No PR found for current branch: $branch\""
  exit 0
}
pr_number=$(echo "$pr_info" | jq -r '.number')

# Simple caching to avoid redundant fetches (after pr_number is defined)
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/pr-recent-comments"
mkdir -p "$cache_dir"
cache_file="$cache_dir/pr-${pr_number}-${commit_sha}.json"

# Check if we have a recent cache (less than 2 minutes old)
if [ -f "$cache_file" ]; then
  cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || date +%s)))
  if [ "$cache_age" -lt 120 ]; then
    cat "$cache_file"
    exit 0
  fi
fi

# Function to handle GitHub API calls with rate limit handling
safe_gh_api() {
  local result
  result=$(gh api "$@" 2>&1)
  if echo "$result" | grep -qi "rate limit"; then
    echo "error: \"GitHub API rate limit exceeded. Wait a few minutes and try again.\""
    exit 1
  fi
  echo "$result"
}

# Function to extract outside diff comments using simplified approach
# Function to extract outside diff comments using simplified approach
extract_outside_diff() {
  local body="$1"
  
  # Look for the pattern "**file:lines**: **Title**" followed by body text
  # This is a more robust pattern than HTML parsing
  printf '%s' "$body" | perl -0777 -e '
    use utf8;
    binmode(STDIN, ":utf8");
    binmode(STDOUT, ":utf8");
    $_ = <STDIN>;
    
    # Find Outside diff range section by looking for the pattern
    # Pattern: **filename.ext:line**: **Title** followed by content
    my @comments;
    while (/\*\*([^:]+):(\d+(?:-\d+)?)\*\*:\s*\*\*(.+?)\*\*\s*\n(.*?)(?=\*\*[^:]+:\d+(?:-\d+)?\*\*:|$)/sg) {
      my $file = $1;
      my $lines = $2;
      my $title = $3;
      my $content = $4;
      
      # Clean up the content - remove HTML tags more aggressively
      $content =~ s/<[^>]+>//g;
      $content =~ s/&nbsp;/ /g;
      $content =~ s/&lt;/</g;
      $content =~ s/&gt;/>/g;
      $content =~ s/&amp;/&/g;
      
      # Clean up excessive newlines
      $content =~ s/\n{3,}/\n\n/g;
      $content =~ s/^\s+|\s+$//g;
      
      push @comments, "$file:$lines\n$title\n$content";
    }
    
    if (@comments) {
      print "Outside diff comments:\n";
      print join("\n\n", @comments);
      print "\n";
    }
  ' 2>/dev/null
}

# Function to filter comment body (simplified approach)
filter_body() {
  local body="$1"
  
  # Extract "outside of diff" comments first
  outside_content=""
  if printf '%s' "$body" | grep -qi "Outside diff range"; then
    outside_content=$(extract_outside_diff "$body")
  fi
  
  # Use perl for comprehensive filtering
  filtered=$(printf '%s' "$body" | perl -0777 -pe '
    # Remove Analysis chain details blocks (contains Script executed noise)
    s/<details>\s*<summary>🧩 Analysis chain<\/summary>.*?<\/details>//gs;
    
    # Remove AI Agents prompt blocks
    s/<details>\s*<summary>🤖 Prompt for AI Agents<\/summary>.*?<\/details>//gs;
    
    # Remove ENTIRE 📜 Review details section (contains non-actionable metadata and approval comments)
    s/<details>\s*<summary>📜 Review details<\/summary>.*//gs;
    
    # Remove entire CAUTION blockquote section (outside diff already extracted separately)
    s/>\s*\[!CAUTION\][\s\S]*?>\s*<\/blockquote><\/details>\s*\n*//gs;
    
    # Remove emoji severity badges at start of comment (_🧹 Nitpick_ | _🔵 Trivial_, etc.)
    s/^_[⚠️🧹🔵🔴🟡][^_]*_\s*\|\s*_[^_]+_\s*\n+//s;
    
    # Remove HTML comments (fingerprinting, auto-generated, review status)
    s/<!--[^>]*-->//g;
    
    # Unwrap useful <details> blocks (🔎 Proposed fix, etc.) - keep content, remove tags
    s/<details>\s*<summary>(🔎[^<]*)<\/summary>\s*/$1\n/gs;
    s/<\/details>//g;
    
    # Remove stray HTML tags
    s/<\/?(?:blockquote|summary)>//g;
    s/<details>//g;
    
    # Remove boilerplate lines from top-level reviews
    s/^\*\*Actionable comments posted: \d+\*\*\s*\n*//m;
    
    # Remove stray leading > from blockquotes
    s/^>\s*$//gm;
    s/^>\s+//gm;
    
    # Collapse multiple empty lines
    s/\n{3,}/\n\n/g;
    
    # Trim leading/trailing whitespace
    s/^\s+|\s+$//g;
  ' 2>/dev/null || echo "$body")
  
  # Remove review metadata lines
  filtered=$(printf '%s' "$filtered" | grep -vE '^\*\*(Configuration|Review profile|Plan|Knowledge base|Context|Commits|Files|Additional comments)')
  
  # If filter left us with empty/whitespace only, use outside content exclusively
  filtered_trimmed=$(printf '%s' "$filtered" | tr -d '[:space:]')
  if [ -z "$filtered_trimmed" ] && [ -n "$outside_content" ]; then
    echo "$outside_content"
    return
  fi
  
  # Append outside diff content if we extracted it
  if [ -n "$outside_content" ]; then
    filtered=$(printf '%s\n\n%s' "$filtered" "$outside_content")
  fi
  
  echo "$filtered"
}

# Fetch inline review comments and top-level reviews since commit
echo "Fetching comments since $commit_timestamp..."
inline_comments=$(safe_gh_api "repos/$repo/pulls/$pr_number/comments" \
  --jq "[.[] | select(.updated_at >= \"$commit_timestamp\") | {path, line, body}]")

top_level_reviews=$(safe_gh_api "repos/$repo/pulls/$pr_number/reviews" \
  --jq "[.[] | select(.submitted_at >= \"$commit_timestamp\") | {body}]")

# Filter inline comments - skip addressed and extract core message
filtered_inline_tmp=$(mktemp)
filtered_reviews_tmp=$(mktemp)

# Process inline comments (use process substitution to avoid subshell)
while read -r comment; do
  [ -z "$comment" ] && continue
  body=$(echo "$comment" | jq -r '.body')
  
  # Skip if already addressed
  if echo "$body" | grep -qiE "Addressed in commit|✅ Addressed"; then
    continue
  fi
  
  # Skip LGTM and confirmation comments
  if echo "$body" | grep -qiE "LGTM|All.*issues.*addressed|comments not posted|no issues found"; then
    continue
  fi
  
  # Filter body using function
  filtered_body=$(filter_body "$body")
  
  # Limit to first 30 lines and 2500 chars
  filtered_body=$(printf '%s' "$filtered_body" | head -30)
  filtered_body=${filtered_body:0:2500}
  if [ ${#filtered_body} -ge 2500 ]; then
    filtered_body="${filtered_body}..."
  fi
  
  # Trim whitespace
  filtered_body=$(printf '%s' "$filtered_body" | sed -e 's/^[[:space:]]*//; s/[[:space:]]*$//')
  
  # Skip if empty
  if [ -z "$filtered_body" ]; then
    continue
  fi
  
  # Extract priority from emoji prefix
  priority="normal"
  if echo "$body" | grep -q "^_⚠️"; then priority="high"; fi
  if echo "$body" | grep -q "^_🧹"; then priority="low"; fi
  if echo "$body" | grep -q "^_🔵"; then priority="trivial"; fi
  if echo "$body" | grep -q "^_♻️"; then priority="duplicate"; fi
  
  # Output filtered comment (only essential fields)
  echo "$comment" | jq --arg body "$filtered_body" --arg priority "$priority" '{path, line, body: $body, priority: $priority}' >> "$filtered_inline_tmp"
done < <(echo "$inline_comments" | jq -r '.[] | @json')

# Process top-level reviews (use process substitution to avoid subshell)
while read -r comment; do
  [ -z "$comment" ] && continue
  body=$(echo "$comment" | jq -r '.body')
  
  # Skip if already addressed
  if echo "$body" | grep -qiE "Addressed in commit|✅ Addressed"; then
    continue
  fi
  
  # Skip LGTM and confirmation comments
  if echo "$body" | grep -qiE "LGTM|All.*issues.*addressed|comments not posted|no issues found"; then
    continue
  fi
  
  # Filter body using function
  filtered_body=$(filter_body "$body")
  
  # Limit to first 30 lines and 2500 chars
  filtered_body=$(printf '%s' "$filtered_body" | head -30)
  filtered_body=${filtered_body:0:2500}
  if [ ${#filtered_body} -ge 2500 ]; then
    filtered_body="${filtered_body}..."
  fi
  
  # Trim whitespace
  filtered_body=$(printf '%s' "$filtered_body" | sed -e 's/^[[:space:]]*//; s/[[:space:]]*$//')
  
  # Skip if empty
  if [ -z "$filtered_body" ]; then
    continue
  fi
  
  # Output filtered review (only body)
  echo "$comment" | jq --arg body "$filtered_body" '{body: $body}' >> "$filtered_reviews_tmp"
done < <(echo "$top_level_reviews" | jq -r '.[] | @json')

# Read filtered results
filtered_inline=$(cat "$filtered_inline_tmp" | jq -s '.' || echo '[]')
filtered_reviews=$(cat "$filtered_reviews_tmp" | jq -s '.' || echo '[]')
rm -f "$filtered_inline_tmp" "$filtered_reviews_tmp"

# Count
inline_count=$(echo "$filtered_inline" | jq 'length')
reviews_count=$(echo "$filtered_reviews" | jq 'length')
total=$((inline_count + reviews_count))

if [ "$total" -eq 0 ]; then
  echo "pr:
  number: $pr_number
  current_commit: \"$commit_sha\"
  commit_timestamp: \"$commit_timestamp\"
comments_since: 0
message: \"No actionable comments found since last commit\""
  exit 0
fi

# Build TOON output
combined_json=$(jq -n \
  --argjson inline "$filtered_inline" \
  --argjson reviews "$filtered_reviews" \
  --arg number "$pr_number" \
  --arg sha "$commit_sha" \
  --arg timestamp "$commit_timestamp" \
  --arg total "$total" \
  --arg inline_count "$inline_count" \
  --arg reviews_count "$reviews_count" \
  '{
    pr: {
      number: ($number | tonumber),
      current_commit: $sha,
      commit_timestamp: $timestamp,
      comments_since: ($total | tonumber),
      inline_comments: ($inline_count | tonumber),
      top_level_reviews: ($reviews_count | tonumber)
    },
    comments: $inline,
    reviews: $reviews
  }')

echo "$combined_json" | bunx @toon-format/cli --delimiter=","

# Save to cache
echo "$combined_json" > "$cache_file"
