#!/bin/bash
# Description: Generates structured, categorized, and cleaned release notes from git history 
# based on Conventional Commits principles for automated GitHub Releases and Discord notifications.
set -euo pipefail

PREVIOUS_TAG="${1:-}"
CURRENT_TAG="${2:-HEAD}"
REPO="${GITHUB_REPOSITORY:-danfreudend/hytale-server-container}"
REPO_URL="https://github.com/${REPO}"

if [ -z "$PREVIOUS_TAG" ]; then
    PREVIOUS_TAG=$(git rev-list --max-parents=0 HEAD)
fi

echo "Generating release notes between $PREVIOUS_TAG and $CURRENT_TAG..." >&2

FEAT_FILE=$(mktemp)
FIX_FILE=$(mktemp)
CI_FILE=$(mktemp)
DOCS_FILE=$(mktemp)
CONTRIB_FILE=$(mktemp)
DEPS_FILE=$(mktemp)

cleanup() {
    rm -f "$FEAT_FILE" "$FIX_FILE" "$CI_FILE" "$DOCS_FILE" "$CONTRIB_FILE" "$DEPS_FILE"
}
trap cleanup EXIT

# Read git log: hash, subject, author name
git log "${PREVIOUS_TAG}..${CURRENT_TAG}" --pretty=format:"%h|%s|%an" --no-merges | while IFS='|' read -r hash subject author; do
    # 1. Omit noise: intermediate syntax/fix commits, merge commits
    if [[ "$subject" =~ ^(fix\ syntax|syntax\ error|wip|draft|Merge\ branch) ]]; then
        continue
    fi

    # Exclude owner from contributors if desired, or keep all external authors
    if [ "$author" != "dependabot[bot]" ] && [ "$author" != "GitHub Actions" ]; then
        echo "@$author" >> "$CONTRIB_FILE"
    fi

    # Parse conventional commit: type(scope): description or type: description
    regex="^([a-z]+)(\(([^\)]+)\))?:[[:space:]]*(.*)$"
    if [[ "$subject" =~ $regex ]]; then
        type="${BASH_REMATCH[1]}"
        scope="${BASH_REMATCH[3]}"
        desc="${BASH_REMATCH[4]}"
    else
        type="chore"
        scope=""
        desc="$subject"
    fi

    # Capitalize first letter of description for imperative format
    desc="$(tr '[:lower:]' '[:upper:]' <<< ${desc:0:1})${desc:1}"

    # Format line
    if [ -n "$scope" ]; then
        line="- **[$scope]:** $desc ([${hash}](${REPO_URL}/commit/${hash}))"
    else
        line="- $desc ([${hash}](${REPO_URL}/commit/${hash}))"
    fi

    # Categorize
    case "$type" in
        feat|feature)
            echo "$line" >> "$FEAT_FILE"
            ;;
        fix|bug)
            echo "$line" >> "$FIX_FILE"
            ;;
        ci|workflow|build)
            echo "$line" >> "$CI_FILE"
            ;;
        deps)
            echo "$desc ([${hash}](${REPO_URL}/commit/${hash}))" >> "$DEPS_FILE"
            ;;
        docs|chore|refactor)
            echo "$line" >> "$DOCS_FILE"
            ;;
        *)
            echo "$line" >> "$DOCS_FILE"
            ;;
    esac
done

# Print output template
echo "## Changes since ${PREVIOUS_TAG}"

if [ -s "$FEAT_FILE" ]; then
    echo ""
    echo "### Features & Enhancements"
    cat "$FEAT_FILE"
fi

if [ -s "$FIX_FILE" ]; then
    echo ""
    echo "### Bug Fixes"
    cat "$FIX_FILE"
fi

if [ -s "$CI_FILE" ]; then
    echo ""
    echo "### CI/CD & Automation"
    cat "$CI_FILE"
fi

# Combine docs, chore, refactor, and grouped deps into Documentation & Maintenance
DOCS_COUNT=$(wc -l < "$DOCS_FILE" | tr -d ' ')
DEPS_COUNT=$(wc -l < "$DEPS_FILE" | tr -d ' ')

if [ "$DOCS_COUNT" -gt 0 ] || [ "$DEPS_COUNT" -gt 0 ]; then
    echo ""
    echo "### Documentation & Maintenance"
    if [ "$DOCS_COUNT" -gt 0 ]; then
        cat "$DOCS_FILE"
    fi
    if [ "$DEPS_COUNT" -gt 0 ]; then
        if [ "$DEPS_COUNT" -eq 1 ]; then
            echo "- Bumped dependency: $(cat "$DEPS_FILE")"
        else
            echo "- Bumped $DEPS_COUNT dependencies"
        fi
    fi
fi

echo ""
echo "---"
echo ""
echo "### Contributors"
if [ -s "$CONTRIB_FILE" ]; then
    sort -u "$CONTRIB_FILE"
else
    echo "- @${GITHUB_REPOSITORY_OWNER:-danfreudend}"
fi
