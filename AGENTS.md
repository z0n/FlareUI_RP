# Working on FlareUI RP

## Workflow

1. **Use the recorded baseline.** For dependency-facing work, consult [DEPENDENCIES.md](DEPENDENCIES.md) and read the relevant tagged source locally with `git show <tag>:<path>`. Routine questions and changes need no upstream fetch or version report. Use `@dependency-audit` when the maintainer requests an update check.
2. **Implement and verify** against that baseline. For dependency-facing changes, update its verification record with the change, checks performed and any in-game results. Leave changes uncommitted unless asked.
3. **When asked to prepare a release,** use the [release skill](.agents/skills/release/SKILL.md) (`@release`). Review the changes and proposed player-facing changelog with the maintainer, prepare the release files and run `./tools/check`. Wait for separate, explicit publication approval before committing, tagging and pushing the reviewed release.
4. **Review [CURSEFORGE.md](CURSEFORGE.md)** against the release. This file is the source for the CurseForge project description. If it needs an update, edit it here. When it has changed since the previous release tag, remind the maintainer to copy the tagged file’s contents into the CurseForge description editor after release.

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
