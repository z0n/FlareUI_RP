---
name: dependency-audit
description: On request, compare the recorded Forever dependency releases with public updates and assess whether FlareUI RP needs changes.
metadata:
  opencode/autoinvoke: false
---

1. Read `DEPENDENCIES.md` in the addon root. For each linked upstream, use its checkout from `opencode.json`. Fetch `origin`'s default branch and tags without switching branches or altering working files.
2. Check the upstream GitHub Releases listing for the newest published stable release that ships Forever support. Confirm the release asset or tagged TOC matches the target client. A newest tag, prerelease or branch tip alone is insufficient. If a release or ref cannot be verified, mark that dependency unknown and continue with the others.
3. Compare each baseline tag to its released candidate (`git diff --stat <old> <new>`, then inspect relevant paths and symbols). Trace changed hooks, callback arguments and timing, frame fields, templates and settings into this addon's actual callers and mocks. Cover FlareUI rendering and settings, TRP3 profile APIs and UI, and optional Extended pages with and without Extended installed. Use `git show <tag>:<path>` to confirm the released contract; if tags match, skip the release diff.
4. Separately inspect `<release>..origin/<default-branch>` for upcoming changes that touch those integrations. Label them unreleased; never target them as a requirement.
5. Report baseline → candidate per dependency, the affected upstream symbol and local adapter if any, and a verdict: no adaptation, change needed, or verification blocked. Give the smallest useful follow-up test for each risk. Distinguish source inspection, `./tools/check` results and in-game checks in the report.
6. When a verified stable Forever release is newer than the baseline, offer to update the addon to that version. Name the adapter changes and checks the update would need. If the existing code is compatible, offer to verify it and bump only the baseline. If verification is blocked, suggest how to unblock it first. Leave code and `DEPENDENCIES.md` unchanged during the audit; update the version links when the maintainer chooses to adopt the release and compatibility is verified.
