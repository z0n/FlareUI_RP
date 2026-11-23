# Working on FlareUI RP

## Design principle: substitute RP identity, preserve FlareUI’s choices

For each feature, ask: **What would stock FlareUI show for this unit, in this layout and state?**

- **Names:** Where FlareUI shows a player’s game name, substitute the available RP name in the selected first/full-name format. Keep the label’s placement, visibility and level prefix. A hidden name stays hidden.
- **Colours:** Where FlareUI would use a class colour, substitute the available RP colour. Determine this from the setting and unit state, not by comparing RGB values. A green bar with Class Colours off stays green; a health warning, reaction colour, or party/raid name colour keeps its meaning.
- **Fallbacks:** Treat name and colour independently. A profile with only a name changes only the name. When data is unavailable, restricted, or an option is switched off, leave or restore the normal FlareUI display.

When adding a new display surface, test both a case where substitution is expected and one where FlareUI’s choice must win.

## Verify upstream behaviour against releases

- For every implementation or bug fix, check the latest **public, stable release for WoW: Forever** of **both** [FlareUI](https://github.com/malkkav/FlareUI/releases) and [Total RP 3](https://github.com/Total-RP/Total-RP-3/releases). Do not assume `main`, the newest tag, or the neighbouring working copy is what players have installed.
- Use `../FlareUI` and `../Total-RP-3` as references. Verify each upstream remote, fetch its tags and default branch, match the published version to its tag/commit, then inspect the released file with `git show <release>:<path>`. Do not switch branches in, edit, or reset either checkout to read it.
- Compare each release with its upstream default branch (`git log --oneline <release>..origin/HEAD` and inspect the diff). In your work summary, identify the release versions used. If either project has unreleased code, explicitly say so, briefly describe the changes, and say whether they affect this addon. Do not depend on an unreleased helper or behaviour. If the public release cannot be verified, say what was verified instead.

## Lua conventions

- In game-facing text, separate settings path steps with a spaced ASCII `>` (for example, `Look > Class Colours`). WoW fonts may render Unicode arrows as empty squares.

- Keep the README focused on current behaviour. Put upstream version comparisons and release-specific notes in work summaries, not the README.
- Write release notes for players: describe what changed and any settings they need to know about. Keep test instructions and verification results in development notes or PRs.

- Target the Forever client and Lua 5.1. Each addon file receives the shared private namespace with `local _, ns = ...`. Keep helpers and mutable state `local`; put only cross-file interfaces on `ns`. Keep `FlareUI_RP.toc` in dependency order.
- Prefer clear event-driven code over polling. Keep FlareUI-specific hooks in the rendering adapters and TRP3 identity/profile lookups in `Profile.lua`. Preserve the existing saved setting keys when changing labels.
- Unit tokens, especially nameplate tokens, can be reused. Check that identity values are accessible before branching on them or doing profile lookups. Pass secret health/colour results directly to widgets; don't compare or cache them as ordinary numbers.
- Optimise work in frequently called hooks before introducing caches. Prefer reusing data within a single paint to retaining profiles across target swaps and profile changes.

## Verification

Run from the addon root:

```sh
./tools/check
```

Use mocks for settings, missing helpers, late profile updates and recycled plates. Check visual behaviour, combat restrictions and taint in-game on released dependencies. Distinguish local checks from player-confirmed results. Keep changes uncommitted unless the user asks to commit.
