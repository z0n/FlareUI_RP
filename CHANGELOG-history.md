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
