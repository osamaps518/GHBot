# Contributing

How we work on GHbot. We don't have fixed schedules, so whoever has time picks something up. These rules exist so nobody duplicates work or breaks `main`.

## Setup

Coming once there's code to run.

## Finding work

1. Open the project board and filter by the **current milestone**. That's what we're focused on right now.
2. Pick an issue from the **Ready** column. Issues in **Backlog** aren't ready yet: they still need discussion or details.
3. **Assign yourself and move the card to In Progress before you start.** This is how the others know it's taken.
4. If you have to stop, leave a comment saying where you got to. If an issue has had no update for about a week, anyone can comment, unassign it, and move it back to Ready.

Large features may have a parent issue that describes the whole feature. The smaller task issues link to it under **Parent**. Read the parent first so you know where your piece fits.

## Writing issues

Use **New issue** and pick a template:

- **Feature idea:** something the app should do. Describe the problem and who has it, not how to build it.
- **Bug report:** something that's broken.

Everything new lands in **Backlog**. We go through it, add details, put it in a milestone, and move it to **Ready** when it's clear enough to work on.

An issue is ready when someone who wasn't part of the discussion could pick it up and know when it's done.

## Branches

Never commit to `main` directly. Branch off an up-to-date `main`:

```bash
git switch main
git pull
git switch -c feat/12-login-screen
```

Name branches `<type>/<issue-number>-<short-description>`:

| Type | For |
|---|---|
| `feat` | new functionality |
| `fix` | bug fixes |
| `docs` | documentation only |
| `chore` | setup, tooling, dependencies |

## Pull requests

1. Keep PRs small: one issue per PR. A PR that's quick to review gets merged quickly.
2. In the description, write **`Closes #12`** (with your issue number). Merging the PR then closes the issue automatically.
3. Explain *what* changed and *why*. Add screenshots for anything visible in the app.
4. Move the card to **In Review** and wait for **1 approval** from someone else.
5. Merge with **Squash and merge**, then delete the branch.

When reviewing, ask about anything you don't understand. That's part of the review, not a waste of the author's time.

## Decisions

Big technical choices (a library, an architecture change, a new service) go in [`docs/decisions.md`](docs/decisions.md) with the reasoning, in the same PR that introduces them.
