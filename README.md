# FlareUI RP

FlareUI RP brings Total RP 3 names and colours to FlareUI frames and nameplates in **WoW: Forever**. It also gives the TRP3 main window, toolbar and target bar an optional FlareUI appearance.

## Install and configure

1. Install FlareUI RP alongside [FlareUI](https://www.curseforge.com/wow/addons/flareui) and [Total RP 3](https://www.curseforge.com/wow/addons/total-rp-3). For a manual install, download the **addon ZIP** from [GitHub Releases](https://github.com/z0n/FlareUI_RP/releases), not **Source code (zip)**. Extract it so `Interface/AddOns/FlareUI_RP/FlareUI_RP.toc` exists.
2. Enable **Unit Frames**, **Nameplates**, or both in FlareUI.
3. Open **Total RP 3 > Settings > FlareUI RP**. RP names and profile colours are on by default. RP titles, guild names and guildmate colours are opt-in; their setup hints appear only after you enable them.

## RP names and colours

RP names follow each label’s **First Name**, **Last Name** or **Full Name** setting. A missing surname falls back to the RP first name. Names and colours update when profile data arrives; if either is unavailable, FlareUI keeps its usual display for that part.

- **Unit frames:** Enable **Look > Class Colours** on the player, target, focus, target of target or target of focus frame to see RP health colours. For party and raid, select the corresponding frame in Edit Mode. Health warnings and gradients keep priority.
- **Player nameplates:** Choose **Class & Reaction** for RP health colours. RP colours also apply to class-coloured names in **Name Only** mode or with **Colour Names by Class** enabled. Party, raid and guild name colours keep priority. **Names Above Plate** has its own name format.
- **RP guilds:** Enable **Use RP Guild Names** in FlareUI RP and **Show Guild Name** for friendly or enemy **Name Only** plates in FlareUI. The **Guild name** from the player’s TRP3 Characteristics appears beneath the title or name, even without an in-game guild. An empty field keeps the normal guild line.
- **RP titles:** Choose **Short title** or **Full title** under **RP Titles** and enable FlareUI’s **Show Titles** for friendly or enemy **Name Only** plates. Full titles can span multiple rows.

**Colour RP Guild Members** is off by default. Enable it to extend FlareUI’s **Colour Guild Members** on friendly **Name Only** plates. Players whose TRP3 guild matches yours get the same name colour as in-game guildmates, even with **Show Guild Name** off. Party and raid colours still take priority.

## TRP3 appearance

The main window uses FlareUI’s bronze frame and stone background while preserving character-sheet parchment and player-chosen artwork. The toolbar defaults to **Quest Tracker** style; the target bar and **At First Glance** panel default to **Frames**. Turn off **Use FlareUI Styling** for the main window, toolbar or target bar separately to restore its native appearance.

With **Total RP 3: Extended** installed, main-window styling gives **Character > Inventory** FlareUI’s bag-slot background. Slot borders follow FlareUI’s **Skin Item Slots** setting: Off keeps Extended’s native borders; Thin and Thick use bronze, or the RP item’s quality colour when **Colour by Rarity** is enabled. Extended still supplies the item icons and quest markers.

## Development

With LuaJIT installed, run `./tools/check`. See [AGENTS.md](AGENTS.md) for development and release instructions.

## License

[MIT](LICENSE)
