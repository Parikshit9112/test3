#!/bin/bash
set -euo pipefail

# ================= Configuration =================
REPO_URL="https://github.com/Parikshit9112/test3.git"
NEW_COMMIT_MSG="Initial commit (history squashed)"
MAIN_BRANCH="main"
# =================================================

echo "⚠️  WARNING:"
echo "  - All local branches except $MAIN_BRANCH will be deleted"
echo "  - All remote branches except $MAIN_BRANCH will be deleted"
echo "  - Remote history will be REPLACED by a single commit (force push)"
echo "  - Repo: $REPO_URL"
echo "Make sure you have an offline backup. Press Enter to continue, Ctrl+C to cancel."
read -r

git rev-parse --is-inside-work-tree >/dev/null

# 1. Squash current working tree into a single orphan commit
echo "[1/4] Squashing working tree into a single commit..."
git checkout --orphan clean_history_temp
git add -A
git commit -m "$NEW_COMMIT_MSG"

# 2. Delete every other local branch
echo "[2/4] Deleting all other local branches..."
for b in $(git for-each-ref --format='%(refname:short)' refs/heads/); do
  if [ "$b" != "clean_history_temp" ]; then
    git branch -D "$b" 2>/dev/null || true
  fi
done

# 3. Rename to main and (re)point origin
echo "[3/4] Renaming to $MAIN_BRANCH and setting origin..."
git branch -m "$MAIN_BRANCH"
git remote remove origin 2>/dev/null || true
git remote add origin "$REPO_URL"

# 4. Force-push main, then delete every other remote branch
echo "[4/4] Force-pushing $MAIN_BRANCH ..."
git push --force -u origin "$MAIN_BRANCH"

echo "Deleting other remote branches..."
for rb in $(git ls-remote --heads origin | awk '{print $2}' | sed 's#refs/heads/##' | grep -v "^${MAIN_BRANCH}$" || true); do
  echo "  deleting: $rb"
  git push origin --delete "$rb" || true
done

echo "✅ Done. $REPO_URL now has only '$MAIN_BRANCH' with a single commit."