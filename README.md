# FlareUI RP

FlareUI RP shows Total RP 3 names and colours on FlareUI unit frames and nameplates in **WoW: Forever**. It can also style the TRP3 interface.

## Install and configure

1. Install FlareUI RP alongside [FlareUI](https://www.curseforge.com/wow/addons/flareui) and [Total RP 3](https://www.curseforge.com/wow/addons/total-rp-3).
2. Enable **Unit Frames**, **Nameplates**, or both in FlareUI.
3. Open **Total RP 3 > Settings > FlareUI RP**. RP names and colours are on by default.

**Manual install:** Extract the **addon ZIP** from [GitHub Releases](https://github.com/z0n/FlareUI_RP/releases) into `Interface/AddOns/`. Check that `Interface/AddOns/FlareUI_RP/FlareUI_RP.toc` exists.

## RP names and colours

Players and linked companions share the same settings. You can use RP names, RP colours or both. If a profile lacks a name or colour, FlareUI keeps its usual one.

Player names follow each label’s first, last or full name setting. A missing surname falls back to the first name. **Names Above Plate** has its own name format.

### Unit frames

RP colours affect the **health bar**. Names inside and above the frame keep FlareUI’s text colour.

For the Pet frame, use **RP Health Bar Colours > Pet**. For other frames, also enable **Look > Class Colours** in FlareUI’s Edit Mode. Health warnings and gradients keep priority.

### Nameplates

- **Name Only:** The name uses the profile colour.
- **Full plates:** Enable **Colour Names by Class** for the name. Choose **Class & Reaction** for the health bar.

Party, raid and guild name colours keep priority.

### Optional titles and guilds

These features are off by default and apply to **Name Only** plates.

- **Titles:** Enable **Show Titles** for the plate type (usually **Minor** for pets). In FlareUI RP, choose **Short title** or **Full title**. Full titles can span multiple lines. A missing full player title falls back to the short title. Companions use their single title in either mode.
- **Guild names:** Enable **Show Guild Name** in FlareUI and **Use RP Guild Names** in FlareUI RP. Player plates then show the guild from TRP3 Characteristics, even without an in-game guild.
- **Guildmate colours:** Enable **Colour Guild Members** and **Colour RP Guild Members** to highlight friendly players who share your TRP3 guild. This works even with guild names hidden.

## TRP3 appearance

Toggle **Use FlareUI Styling** separately for the main window, toolbar or target bar.

- **Main window:** Bronze and stone styling keeps the character-sheet parchment and custom artwork.
- **Toolbar:** Defaults to **Quest Tracker** style.
- **Target bar and At First Glance panel:** Default to **Frames** style.

With **Total RP 3: Extended**, main-window styling adds FlareUI bag slots to **Character > Inventory**. Set **Skin Item Slots** to **Off** for native borders, or choose **Thin** or **Thick** for bronze borders. Enable **Colour by Rarity** to use item quality colours instead.

## Development

With LuaJIT installed, run `./tools/check`. See [AGENTS.md](AGENTS.md) for development and release instructions.

## License

[MIT](LICENSE)
