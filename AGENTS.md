# Working on FlareUI RP

## Workflow

1. **Check dependencies.** Fetch tags and the upstream default branches in `../FlareUI` and `../Total-RP-3`. Verify the latest public Forever releases of [FlareUI](https://github.com/malkkav/FlareUI/releases) and [TRP3](https://github.com/Total-RP/Total-RP-3/releases). Read the released source with `git show <release>:<path>` without changing either checkout. Report the versions and briefly summarise any unreleased changes and their relevance; don’t depend on them.
2. **Implement and verify** the feature against those releases. Leave changes uncommitted unless asked.
3. **When asked to prepare a release,** review changes since the last tag, update `CHANGELOG.md` and `## Version` in `FlareUI_RP.toc`, and run `./tools/check`. Give the maintainer the exact Git commands to tag the release commit and push the branch and tag together; pushing the tag publishes the addon.
4. **Check the CurseForge description** against the release. If it’s still accurate, say so. If it’s stale, provide a concise, paste-ready Markdown replacement. If you can’t read the live description, ask for its current text.

## Design principle: substitute RP identity, preserve FlareUI’s choices

For each feature, ask: **What would stock FlareUI show for this unit, in this layout and state?**

- **Names:** Where FlareUI shows a player’s game name, substitute the available RP name in the selected first/full-name format. Keep the label’s placement, visibility and level prefix. A hidden name stays hidden.
- **Colours:** Where FlareUI would use a class colour, substitute the available RP colour. Determine this from the setting and unit state, not by comparing RGB values. A green bar with Class Colours off stays green; a health warning, reaction colour, or party/raid name colour keeps its meaning.
- **Fallbacks:** Treat name and colour independently. A profile with only a name changes only the name. When data is unavailable, restricted, or an option is switched off, leave or restore the normal FlareUI display.

When adding a new display surface, test both a case where substitution is expected and one where FlareUI’s choice must win.

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

Use mocks for settings, missing helpers, late profile updates and recycled plates. Visual behaviour, combat restrictions and taint need in-game verification on released dependencies.
