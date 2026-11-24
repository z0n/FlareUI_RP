# Forever dependency baseline

- FlareUI: [7.0.13](https://github.com/malkkav/FlareUI/releases/tag/7.0.13)
- Total RP 3: [3.5.5](https://github.com/Total-RP/Total-RP-3/releases/tag/3.5.5)
- Total RP 3: Extended (optional): [2.3.7](https://github.com/Total-RP/Total-RP-3-Extended/releases/tag/2.3.7)

Verification for the 7.0.13 adoption:

- Source: tagged `NP.UpdateColor` and `NP.BarColor` handle restricted cached colours. The adapter now requests the host repaint immediately and checks `barKnown` after the repaint.
- Automated: `./tools/check` passed, including profile refresh after a restricted bar colour and host fallback for a restricted colour or identity.
- In game: not verified.

Custom guild label verification:

- FlareUI `Modules/Nameplates.lua`: `NP.UpdateGuild` owns the friendly/enemy Name Only guild label. `Modules/Tooltips.lua` separately hides Blizzard’s guild line or adds its rank. TRP3 already has custom guild and rank controls for its tooltip.
- TRP3 `Core/Player.lua`: `Player:GetCustomGuildMembership().name` reads the Characteristics guild-name field independently of in-game membership.
- Automated: `tests/nameplates.lua` covers guild-only profile updates, title placement, stock fallback, restricted data, plate reuse and visibility settings.
- Guildmate colour: checked FlareUI’s tagged `NP.UpdateBarName` priority and per-type Style settings, and TRP3’s `Player.GetCurrentUser()` and local profile-change notifications. `./tools/check` passed, including own-guild changes, group priority, friendly Name Only gating and independent settings hints.
- Visibility hints follow FlareUI’s tagged Visibility settings: saved friendly type picks take precedence over live CVars, and enemy players require both enemy visibility and the Players type. Mock checks cover combat-only choices, disabled types, the Visibility shortcut and stock guild fallback for a long whitespace-only field.
- In game: not verified.
