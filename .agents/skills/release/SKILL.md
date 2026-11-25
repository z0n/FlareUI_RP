---
name: release
description: Prepare a FlareUI RP addon release, review the proposed changelog with the maintainer, and publish the approved branch and tag after final confirmation.
---

Run from the addon root. A release request starts preparation; only the final confirmation authorizes publication.

## 1. Establish what would ship

- Inspect the current branch, upstream, push destination and working tree (including staged and untracked files). Start on `main` with a clean tree. If local work is pending, stop and let the maintainer decide what belongs in the release; never stash or sweep it into the release commit.
- Fetch the release remote's branch and tags. Stop if the branch is behind or diverged. Local commits ahead are fine: identify them explicitly because the push will publish those too.
- Find the latest release tag reachable on `main` (`git describe --tags --match 'v[0-9]*' --abbrev=0`). Cross-check it against the remote release tags, TOC version and current changelog heading; resolve any discrepancy before choosing a version.
- Read both the commit log and the net diff from that tag to HEAD. Summarize player-visible changes and maintainer-only work separately. Consult `DEPENDENCIES.md` for baseline versions. Use work summaries or PRs for verification details; distinguish recorded in-game results from mock checks and outstanding testing.

## 2. Review the proposal

Show the base tag and candidate HEAD, recommend a version with a reason, and present the **full proposed `CHANGELOG.md`** starting with `# FlareUI RP X.Y.Z`. Write for players: what changed, where settings live, and what they may need to do. Keep internal work and test results in the summary. Review `CURSEFORGE.md` against the candidate and explain any proposed description edit.

Ask the maintainer to accept or revise the version and wording before editing. If they request revisions, show the revised proposal. Acceptance here approves preparation only.

## 3. Prepare and verify

- Prepend the outgoing `CHANGELOG.md` verbatim to `CHANGELOG-history.md`, newest first, exactly once. Replace `CHANGELOG.md` with only the approved release entry: `.pkgmeta` publishes the whole file. Update `## Version` in `FlareUI_RP.toc` and apply agreed description edits.
- Read `.github/workflows/release.yml`. Check that the TOC has a positive numeric `X-Curse-Project-ID` and the proposed `vX.Y.Z` tag matches the TOC. Check availability of the `CF_API_KEY` Actions secret by name only; if visibility is restricted, ask the maintainer to confirm it is configured. Never request its value. Resolve missing prerequisites before publication.
- Run `./tools/check` and `git diff --check`. Review the full release diff, the archive order and any baseline changes. Report failures and unresolved in-game checks accurately. Stop on failed checks; if fixes change release contents, review them and rerun verification.

## 4. Final authorization and publication

Refresh remote refs, verify that the proposed tag is unused locally and remotely, and that the push is a fast-forward to the intended branch. Stage only the reviewed release files by name. Inspect the staged diff and record its tree ID (`git write-tree`) and parent HEAD. Require an otherwise clean tree.

Show the exact destination, branch, outgoing commits, parent HEAD, staged tree, files, approved notes, check results, commit subject and annotated tag. Show the exact commands with concrete values that approval will authorize. Follow the recent tagged releases' format (inspect their tagged commit subjects and tag annotations):

```sh
git commit -m "chore(release): prepare X.Y.Z"
git tag -a vX.Y.Z -m "FlareUI RP X.Y.Z" HEAD
git -c push.followTags=false push --atomic REMOTE HEAD:refs/heads/main refs/tags/vX.Y.Z:refs/tags/vX.Y.Z
```

Ask explicitly: **“Authorize creating this release commit and annotated tag, and pushing main and vX.Y.Z to REMOTE now? Pushing the tag starts addon publication.”** Substitute actual values. Wait for a positive answer to this question. On cancellation or an ambiguous answer, leave the prepared files available for review.

After approval, recheck destination, branch, HEAD, index tree, worktree, remote branch and tag availability. If anything changed, refresh the review and ask again. Otherwise execute the approved commands in order, stopping on any error. Verify the new commit has the reviewed tree and parent before tagging. Never force a push, move a tag, push all tags, or fall back to sequential pushes. On failure report which local and remote refs exist; do not retry publication without confirmation.

Verify the remote branch and peeled annotated tag point to the release commit. Link the tag-triggered Actions run when available; distinguish a successful Git push from a successful package upload. If `CURSEFORGE.md` changed between the previous and new tags, remind the maintainer to copy the **tagged** description into the CurseForge project editor.
