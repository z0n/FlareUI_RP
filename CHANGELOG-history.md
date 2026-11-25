# FlareUI RP 0.7.1 — FlareUI 7.0.15 Compatibility

- Fixed compatibility with FlareUI 7.0.15 on **Name Only** nameplates. When FlareUI RP applies a profile or guildmate colour, the title and guild lines now follow it as FlareUI intends. An RP guild shown with titles turned off also uses the name colour.

Update FlareUI to **7.0.15** or later.

# FlareUI RP 0.7.0 — RP Titles, Guilds and Companions

- **RP titles:** On Name Only player plates, enable FlareUI’s **Show Titles**, then choose **Short title** or **Full title** in FlareUI RP. Full titles can split into separate lines for each role and fall back to the short title when empty.
- **RP guilds:** Turn on FlareUI’s **Show Guild Name** and **Use RP Guild Names** to show a character’s TRP3 guild on Name Only plates, even if they have no in-game guild. To highlight friendly RP guildmates, enable **Colour Guild Members** in FlareUI and **Colour RP Guild Members** in FlareUI RP. This works with guild names hidden; party and raid colours keep priority.
- **Linked pets and minions:** With **Use RP Names** enabled, linked companions now show their TRP3 names on supported unit frames and nameplates. Either RP title option shows a companion’s title on Name Only plates with **Show Titles** enabled. On full plates, turn on **Use Companion Name Colours** to use the companion’s profile colour.

Find the new options under **Total RP 3 > Settings > FlareUI RP > Nameplates**. Titles, guild names, guildmate colours and companion name colours are off by default. Setup hints point to the relevant FlareUI settings.

# FlareUI RP 0.6.1 — Nameplate Colour Refresh

- Fixed a delay updating player nameplate health bars after a colour restriction ends. With FlareUI 7.0.13, a TRP3 profile update can now restore the RP colour immediately. While the colour or player identity is restricted, the bar keeps FlareUI’s colour.

# FlareUI RP 0.6.0 — TRP3 Main Window Styling

- The Total RP 3 main window now uses FlareUI’s bronze frame and stone background. Character-sheet parchment and custom artwork stay visible. To restore TRP3’s appearance, turn off **Use FlareUI Styling** under **Total RP 3 > Settings > FlareUI RP > TRP3 Main Window**. The toolbar and target bar have separate controls.
- If you use **Total RP 3: Extended**, the same switch also styles the **Inventory** and **Quest Log**. Inventory borders follow FlareUI’s **Skin Item Slots** setting and can show RP item quality when **Colour by Rarity** is enabled.
- Switching targets now refreshes the RP name even when the above-frame label is off. When FlareUI shows a level before an above-frame name, the RP name now keeps that prefix.

# FlareUI RP 0.5.0

- The Total RP 3 toolbar now uses FlareUI’s **Quest Tracker** style by default, with a decorated header and matching button borders. The target bar and its five **At First Glance** slots use the **Frames** style by default.
- Open **Total RP 3 > Settings > FlareUI RP > TRP3 Bar Appearance** to choose a style or turn styling off. The toolbar has its own controls, separate from the target bar and glance slots. TRP3 still controls button size, layout and visibility.
- RP name and colour options are now grouped into collapsible sections for **Player, Target & Focus**, **Party & Raid**, and **Player Nameplates**. Your existing choices carry over.

# FlareUI RP 0.4.2

- Choose **Last Name** in FlareUI 7.0.11 to show an RP surname on unit frames and player nameplates. Labels inside and above each frame or plate follow their own setting. If a profile has no surname, **Last Name** shows its RP first name.
- Raid frames and **Raid Style** party frames now follow their own **Show Name** setting for RP names.
- When Total RP 3 reports a profile update for one character, unrelated players’ nameplates skip the repaint.

# FlareUI RP 0.4.1

- With **Colour Names by Class** enabled, RP names inside class-coloured nameplate bars now use FlareUI’s lighter text shade for readability. The health bar itself, names above the bar and **Name Only** text keep their usual colours.

# FlareUI RP 0.4.0

- If RP health colours aren’t showing, open **Total RP 3 > Settings > FlareUI RP**. A hint identifies the FlareUI setting that’s blocking them and updates as you make changes.
- Use the hint’s button to open the relevant FlareUI settings. A movable note keeps the instructions visible while you edit.

# FlareUI RP 0.3.1

- RP names above player nameplates now keep the level prefix when **Follow Name** is selected.
- With **Colour Names by Class** enabled, a name shown only above the plate can now use the player’s RP colour even when **Show RP Names** is off. Party, raid and guild colours still take priority where FlareUI uses them.
- Party frames in **Raid Style** now follow **Full Player Names** for the member name at the top of each tile.
- Party and raid frames make fewer Total RP 3 lookups when refreshing names and health colours, and skip lookups when the game restricts access to the unit.

# FlareUI RP 0.3.0

- **Focus**, **Target of Target** and **Target of Focus** now show RP names when they point to a player. They follow the same **Show RP Names** switch as Player and Target and respect each label’s first/full-name setting.
- Each new frame has its own RP health-colour switch under **Total RP 3 > Settings > FlareUI RP > Unit Frames**. To use it, enable **Look > Class Colours** on that frame in FlareUI’s Edit Mode. NPC colours, low-health warnings and health gradients keep priority.

# FlareUI RP 0.2.1

- Full nameplates now use RP profile colours when FlareUI’s new **Colour Names by Class** option is enabled, including names above the plate.
- Respects **Colour Guild Members** on friendly **Name Only** plates: guildmates keep their guild-green names while still showing their RP names. Party and raid name colours also keep priority.

# FlareUI RP 0.2.0

- Party and raid frames can now show RP names and use profile colours in place of class colours. Each group has separate name and health-colour switches. To see RP health colours, select the Party or Raid frame in Edit Mode and enable **Look > Class Colours**.
- The FlareUI RP settings page in Total RP 3 is now grouped by Player & Target, Party Frames, Raid Frames, and Floating Nameplates. Each section explains which FlareUI settings affect what you see.
- Group frames now refresh only the affected members when a character’s profile changes. Colour updates wait when the game restricts the data needed to repaint safely.
