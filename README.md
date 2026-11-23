# FlareUI RP

FlareUI RP displays Total RP 3 names and colours on FlareUI’s player, target, focus, target of target, target of focus, party and raid frames and floating player nameplates in **WoW: Forever**. If a profile has a name but no custom colour, you still see the RP name with FlareUI’s usual colours. Profiles that arrive later appear without retargeting.

## Install and configure

1. Install **FlareUI RP**, [FlareUI](https://www.curseforge.com/wow/addons/flareui), and [Total RP 3](https://www.curseforge.com/wow/addons/total-rp-3). For a manual install, place `FlareUI_RP` inside `Interface/AddOns`.
2. Enable **Unit Frames**, **Nameplates**, or both in FlareUI.
3. Open **Total RP 3 → Settings → FlareUI RP**. Options are on by default and can be changed independently without a reload.

If a FlareUI setting prevents RP health colours, a hint points you to the setting to change.

For manual installs from [GitHub Releases](https://github.com/z0n/FlareUI_RP/releases), download the **FlareUI_RP addon ZIP** under **Assets**, not GitHub’s automatic **Source code (zip)**. Extract it so `Interface/AddOns/FlareUI_RP/FlareUI_RP.toc` exists. If your addon manager supports GitHub sources and WoW: Forever, use `https://github.com/z0n/FlareUI_RP` as the source.

**Unit frames:** Player, Target, Focus, Target of Target and Target of Focus share the **Show RP Names** switch. Each has its own RP health-colour switch. Enable **Look > Class Colours** on the corresponding FlareUI frame to use the player's profile colour. Low-health warnings and health gradients keep priority. RP names work independently and follow each label’s first/full-name choice. When the player’s identity is restricted or the unit is an NPC, FlareUI keeps its usual display.

**Party and raid:** Each has separate RP name and health-colour switches. In Edit Mode, select **Party** or **Raid** and enable **Look → Class Colours** to use RP health colours on member tiles. Party settings follow the active Classic or Raid Style; raid main-tank member tiles follow the raid settings. Pets, members’ targets and boss frames are unaffected.

**Nameplates:** Choose **Class & Reaction** in FlareUI to use RP colours on player health fills. Reaction colours and health gradients stay as configured. RP colour replaces class-coloured text in **Name Only** mode and on full plates with **Colour Names by Class** enabled, including their above-plate names. Party, raid and guild name colours keep priority. NPCs keep their normal display.

**Names Above Plate** uses its own first/full-name setting, even when no name is shown inside the bar.

## Development

Run `./tools/check` with LuaJIT installed to check the addon manifest, compile the shipped Lua, and run the tests. GitHub Actions runs the same checks on pull requests and pushes to `main`. See [AGENTS.md](AGENTS.md) for coding conventions and how to verify upstream releases.

## Publishing

To publish, update `## Version` in `FlareUI_RP.toc` and push a matching tag, such as `v0.1.0`. The [release workflow](.github/workflows/release.yml) tests and packages once, uploads the ZIP to CurseForge and GitHub Releases, and attaches `release.json` on GitHub for addon managers.

## License

[MIT](LICENSE)
