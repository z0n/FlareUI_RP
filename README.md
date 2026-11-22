# FlareUI RP

FlareUI RP displays Total RP 3 names and colours on FlareUI’s player and target frames and floating player nameplates in **WoW: Forever**. If a profile has a name but no custom colour, you still see the RP name with FlareUI’s usual colours. Profiles that arrive later appear without retargeting.

## Install and configure

1. Install **FlareUI RP**, [FlareUI](https://www.curseforge.com/wow/addons/flareui), and [Total RP 3](https://www.curseforge.com/wow/addons/total-rp-3). For a manual install, place `FlareUI_RP` inside `Interface/AddOns`.
2. Enable **Unit Frames**, **Nameplates**, or both in FlareUI.
3. Open **Total RP 3 → Settings → FlareUI RP**. All five options are on by default and can be changed independently without a reload.

**Unit frames:** Show RP names inside the player and target frames and, when enabled, above them. Each label respects its own first/full-name choice. Player and target health colours have separate switches; FlareUI’s low-health warnings and health gradients keep priority.

**Nameplates:** Toggle RP names and colours separately. On full plates, the RP colour goes on the health fill and FlareUI controls the text colour. In **Name Only** mode, the colour goes on the text instead. NPCs keep their normal display.

**Names Above Plate** uses its own first/full-name setting, even when no name is shown inside the bar.

## Development

Run `./tools/check` with LuaJIT installed to check the addon manifest, compile the shipped Lua, and run the tests. GitHub Actions runs the same checks on pull requests and pushes to `main`. See [AGENTS.md](AGENTS.md) for coding conventions and how to verify upstream releases.

## Publishing to CurseForge

To publish, update `## Version` in `FlareUI_RP.toc` and push a matching tag, such as `v0.1.0`. The [release workflow](.github/workflows/release.yml) tests, packages, and uploads the addon.

## License

[MIT](LICENSE)
