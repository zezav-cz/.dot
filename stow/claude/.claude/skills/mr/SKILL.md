---
name: mr
description: Create a GitLab Merge Request using glab CLI with project templates and Conventional Commits
allowed-tools: Bash(glab *), Bash(git *), Glob, Read
argument-hint: "[optional ticket ID or description hint]"
---

# Create GitLab Merge Request

Create a Merge Request using the `glab` CLI utility. Auto-detects the trunk/target
branch, selects a matching MR template if the project provides one, and generates a
descriptive title. This skill is repo-agnostic — it adapts to the current project's
conventions.

## Steps

### 1. Gather Context

Run these commands **in parallel** to understand the current state:

```bash
git status
git branch --show-current
git log --oneline --graph --all --decorate -30   # to identify the parent branch
```

Determine the **target branch** (the branch this branch was created from). Detect the
repository's trunk branch rather than assuming a fixed name:

```bash
# The remote's default branch is the most reliable trunk indicator
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's#.*/##'
# Confirm the current branch descends from a candidate trunk
for t in develop main master trunk; do
  git merge-base --is-ancestor "origin/$t" HEAD 2>/dev/null && echo "$t"
done
```

Prefer the merge-base match closest to HEAD. Fall back to the remote default branch if
detection is ambiguous.

Then gather the diff context:

```bash
git log <target_branch>..HEAD --oneline
git diff <target_branch>...HEAD --stat
```

If there are uncommitted changes, **stop and ask the user** to commit first (or suggest
using `/commit`).

If the branch has not been pushed, push it:

```bash
git push -u origin "$(git branch --show-current)"
```

### 2. Detect Branch Type

Parse the current branch name against the common convention
`<type>/<component>/<description>`. Map the prefix to a template and label:

| Branch Prefix | Template     | Label     | Commit Type |
| ------------- | ------------ | --------- | ----------- |
| `feature/*`   | `feature.md` | `Feature` | `feat`      |
| `bugfix/*`    | `bugfix.md`  | `Bugfix`  | `fix`       |
| `update/*`    | `feature.md` | `Update`  | `chore`     |
| `refactor/*`  | `feature.md` | `Update`  | `refactor`  |
| `docs/*`      | `feature.md` | `Update`  | `docs`      |
| `devops/*`    | `feature.md` | `Update`  | `ci`        |

If the branch doesn't match any known prefix, ask the user which type to use.

### 3. Read Template (if present)

MR templates conventionally live in `.gitlab/merge_request_templates/`. Check whether the
directory exists and whether it contains the template mapped in step 2:

```bash
ls .gitlab/merge_request_templates/ 2>/dev/null
```

- If the mapped template exists, read it and use it as the description skeleton.
- If the directory exists but the mapped template is missing, pick the closest available
  template (or the only one present).
- If the project has **no** MR templates, compose a concise description from scratch:
  a **Description** section (what changed and why) and, if relevant, a **Testing**
  section.

### 4. Compose Title

**Format:** `[TICKET-ID] Descriptive Title` or just `Descriptive Title`

- If `$ARGUMENTS` contains a ticket ID (e.g. `ABC-1234`), use `[ABC-1234] Title`.
- If no ticket ID is provided, use just `Title` without brackets.
- **Description**: A concise summary derived from the commits on the branch. Sentence
  case, under 72 characters total.

### 5. Fill Template & Write Description

Use the template structure (or the from-scratch skeleton) and fill in:

- **Description section**: Analyze `git log` and `git diff --stat` to write a high-level
  summary of what changed and why. Focus on the big picture, not line-by-line changes.
  If applicable, include a simple ASCII diagram showing architecture or data flow.
- **Test/checklist sections**: Leave checkboxes unchecked for the user to fill in.
  If a ticket ID was provided, add it as a reference.

**DO NOT** list every file or line changed. The diff is available in the MR itself.

### 6. Create MR

Use a HEREDOC for the description to preserve formatting:

```bash
glab mr create \
  --assignee @me \
  --target-branch "<target_branch>" \
  --label "<Label>" \
  --title "<title>" \
  --description "$(cat <<'EOF'
<filled template content>
EOF
)"
```

Never add a reviewer — do not pass `--reviewer`. Omit `--label` if it could not be
determined.

### 7. Verify & Report

After creation, report the MR URL to the user.

## Rules

- Target the parent branch (the branch this one was created from), detected from the
  remote default branch / merge-base — never assume a fixed trunk name
- Always assign to `@me`
- Never add a reviewer automatically on MR creation — do not pass `--reviewer`
- Apply the label matching the branch type when a label scheme is in use
- Use `[TICKET] Title` format for the MR title (omit brackets if no ticket)
- Keep the description high-level — reviewers can read the diff
- Never force-push or rewrite history without explicit user request
