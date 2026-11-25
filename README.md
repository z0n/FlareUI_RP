# FlareUI RP

FlareUI RP brings Total RP 3 names and colours to FlareUI frames and nameplates in **WoW: Forever**, with optional FlareUI styling for TRP3.

## Install and configure

1. Install FlareUI RP alongside [FlareUI](https://www.curseforge.com/wow/addons/flareui) and [Total RP 3](https://www.curseforge.com/wow/addons/total-rp-3). For a manual install, extract the **addon ZIP** from [GitHub Releases](https://github.com/z0n/FlareUI_RP/releases) into `Interface/AddOns/` so `FlareUI_RP/FlareUI_RP.toc` sits inside.
2. Enable **Unit Frames**, **Nameplates**, or both in FlareUI.
3. Open **Total RP 3 > Settings > FlareUI RP**. RP names and profile colours are on by default; titles, guild names and guildmate colours are opt-in.

## RP names and colours

Each label can show the first, last or full RP name. A missing surname falls back to the first name. Missing names or colours keep their FlareUI defaults until profile data arrives.

- **Unit frames:** Enable **Look > Class Colours** for RP health colours. For party or raid, select the frame in Edit Mode. Health warnings and gradients take priority.
- **Player nameplates:** Choose **Class & Reaction** for RP health colours. Class-coloured names also use RP colours; party, raid and guild colours take priority. **Names Above Plate** has its own name format.
- **Pets and minions:** Linked TRP3 companions show their names on supported frames and nameplates. **Use Companion Name Colours** colours names on full plates only. For companion titles, enable **Show Titles** on the relevant **Name Only** plate type (usually **Minor**) and select either RP title option.

On friendly or enemy **Name Only** player plates:

- **Titles:** Enable FlareUI’s **Show Titles** and choose a short or full RP title. Full titles can span multiple lines and fall back to the short title when empty. If no title is available for your choice, FlareUI keeps its usual line.
- **Guilds:** Enable **Show Guild Name** and **Use RP Guild Names** to show the guild from TRP3 Characteristics, even without an in-game guild.
- **Guildmate colours:** On friendly plates, **Colour RP Guild Members** extends FlareUI’s **Colour Guild Members** to players with the same TRP3 guild as you, even when guild names are hidden.

## TRP3 appearance

The main window uses FlareUI’s bronze and stone styling while keeping character-sheet parchment and custom artwork. The toolbar defaults to **Quest Tracker** style; the target bar and **At First Glance** panel use **Frames** by default. Toggle **Use FlareUI Styling** separately for the window, toolbar or target bar.

With **Total RP 3: Extended**, main-window styling adds FlareUI’s bag-slot background to **Character > Inventory**. Borders follow **Skin Item Slots**: **Off** keeps native borders; **Thin** and **Thick** use bronze or, with **Colour by Rarity**, the item’s quality colour.

## Development

With LuaJIT installed, run `./tools/check`. See [AGENTS.md](AGENTS.md) for development and release instructions.

## License

[MIT](LICENSE)
