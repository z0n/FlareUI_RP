---
name: release
description: Prepare a FlareUI RP addon release, review the proposed changelog with the maintainer, and publish the approved branch and tag after final confirmation.
---

Run from the addon root. A release request starts preparation; only the final confirmation authorizes publication.

## 1. Establish what would ship

- Inspect the current branch, upstream, push destination and working tree (including staged and untracked files). Start on `main` with a clean tree. If local work is pending, stop and let the maintainer decide what belongs in the release; never stash or sweep it into the release commit.
- Fetch the release remote's branch and tags. Stop if the branch is behind or diverged. Local commits ahead are fine: identify them explicitly because the push will publish those too.
- Find the latest release tag reachable on `main` (`git describe --tags --match 'v[0-9]*' --abbrev=0`). Cross-check it against the remote release tags, TOC version and current changelog heading; resolve any discrepancy before choosing a version.
- Read the commit log and net diff from that tag to HEAD; consult `DEPENDENCIES.md` for baseline versions. Use player-visible changes for the changelog. Mention maintainer-only work or verification only if it reveals a problem or requires a decision.

## 2. Review the proposal

Recommend a version with a brief reason and present the **full proposed `CHANGELOG.md`**. Use the heading `# FlareUI RP X.Y.Z — <main feature or fix>`. For a compatibility release, name the addon and version in the heading. Write for players. Review `CURSEFORGE.md`; mention it only if proposing an edit.

Assume players can keep their current settings. If a change is needed, tell them which setting to change and where to find it. Otherwise, omit the settings reminder.

Ask the maintainer to accept or revise the version and wording before editing. If they request revisions, show the revised proposal. Acceptance here approves preparation only.

## 3. Prepare and verify

- Prepend the outgoing `CHANGELOG.md` verbatim to `CHANGELOG-history.md`, newest first, exactly once. Replace `CHANGELOG.md` with only the approved release entry: `.pkgmeta` publishes the whole file. Update `## Version` in `FlareUI_RP.toc` and apply agreed description edits.
- Read `.github/workflows/release.yml`. Check that the TOC has a positive numeric `X-Curse-Project-ID` and the proposed `vX.Y.Z` tag matches the TOC. Leave secret validation to the publication workflow; do not query secret metadata or ask for confirmation.
- Run `./tools/check` and `git diff --check`. Review the full release diff, the archive order and any baseline changes. Report failures and unresolved in-game checks accurately. Stop on failed checks; if fixes change release contents, review them and rerun verification.

## 4. Final authorization and publication

Refresh remote refs, verify that the proposed tag is unused locally and remotely, and that the push is a fast-forward to the intended branch. Stage only the reviewed release files by name. Inspect the staged diff and record its tree ID (`git write-tree`) and parent HEAD. Require an otherwise clean tree.

Keep the publication review exception-only. If everything matches the proposal, ask only the authorization question below. If something unexpected would ship or could disrupt publication, explain the discrepancy, its impact and any decision needed. Keep routine Git details, commands, approved notes and passing checks out of the review.

Use the recent tagged releases’ commit and annotation format:

```sh
git commit -m "chore(release): prepare X.Y.Z"
git tag -a vX.Y.Z -m "FlareUI RP X.Y.Z" HEAD
git -c push.followTags=false push --atomic REMOTE HEAD:refs/heads/main refs/tags/vX.Y.Z:refs/tags/vX.Y.Z
```

Ask explicitly: **“Authorize creating this release commit and annotated tag, and pushing main and vX.Y.Z to REMOTE now? Pushing the tag starts addon publication.”** Substitute actual values. Wait for a positive answer to this question. On cancellation or an ambiguous answer, leave the prepared files available for review.

After approval, recheck destination, branch, HEAD, index tree, worktree, remote branch and tag availability. If anything changed, refresh the review and ask again. Otherwise execute the approved commands in order, stopping on any error. Verify the new commit has the reviewed tree and parent before tagging. Never force a push, move a tag, push all tags, or fall back to sequential pushes. On failure report which local and remote refs exist; do not retry publication without confirmation.

Verify the remote branch and peeled annotated tag point to the release commit. Link the tag-triggered Actions run when available; distinguish a successful Git push from a successful package upload. If `CURSEFORGE.md` changed between the previous and new tags, remind the maintainer to copy the **tagged** description into the CurseForge project editor.
