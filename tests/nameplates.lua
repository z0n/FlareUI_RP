local ns, callbacks, handlers, values, elements = {}, {}, {}, {}, {}
local queued, person, restricted = nil, "A", false
local namesPainted, barsPainted = 0, 0
local stockRed = 0.4
local plate = { unit = "nameplate1", gamePlate = { IsForbidden = function() return false end },
    nameSlot = "left", levelFollow = true, nameFull = false, nameOnly = true, tdb = { healthColor = "class" }, name = {
        SetFormattedText = function(self, fmt, ...) self.text = fmt:format(...) end,
        SetText = function(self, text) self.text = text end,
        SetTextColor = function(self, r, g, b) self.red, self.green, self.blue = r, g, b end,
    } }
FlareUI = { Nameplates = { C = { NAME_LIFT = 0.6 }, LevelPrefix = function() return "12 " end, UpdateName = function(p)
    namesPainted = namesPainted + 1
    local stock = (p.levelFollow and "12 " or "") .. person
    if p.nameSlot then p.name:SetText(stock) end
    p.name:SetTextColor(0.5)
    if p.aboveName and p.aboveKind and p.aboveName:IsShown() then
        p.aboveName:SetText(stock)
        p.aboveName:SetTextColor(p.name.red)
    end
end, BarColor = function(p, r, g, b)
    p.fill, p.barR, p.barG, p.barB = r, r, g, b
    p.barKnown = canaccessvalue(r) and canaccessvalue(g) and canaccessvalue(b)
end, UpdateColor = function(p)
    barsPainted = barsPainted + 1
    FlareUI.Nameplates.BarColor(p, stockRed, 0, 0)
end } }
local tapped
local raid, guild
function UnitIsInMyGuild() return guild end
function IsInRaid() return raid end
function UnitInRaid() return 1 end
function UnitInParty() return true end
function UnitIsConnected() return true end
function UnitClass() return "Priest", "PRIEST" end
C_ClassColor = { GetClassColor = function() return {} end }
function UnitIsTapDenied() return tapped end
function hooksecurefunc(t, key, fn)
    local original = t[key]
    t[key] = function(p) original(p); fn(p) end
end
local records = { A = { "Aster", "Aster Moonfall", 0.8 }, Me = { guild = " NIGHT WATCH " } }
local secret = {}
local gameGuild
local gameTitle
function UnitPVPName() return gameTitle end
function FlareUI.Nameplates.UpdateTitleLine(p)
    if not p.npcTitle then return end
    p.npcTitle.shown = p.nameOnly and p.tdb.showTitles and gameTitle and canaccessvalue(gameTitle)
    if p.npcTitle.shown then p.npcTitle:SetText(gameTitle) end
end
function FlareUI.Nameplates.UpdateTitle(p)
    FlareUI.Nameplates.UpdateTitleLine(p)
    FlareUI.Nameplates.UpdateGuild(p)
end
function GetGuildInfo() return gameGuild end
FlareUI.PALETTE = { bronze5 = { 0.85, 0.68, 0.47 } }
FlareUI.Nameplates.UpdateGuild = function(p)
    if not p.guildName then return end
    p.guildName.shown = p.nameOnly and p.tdb.showGuild and
        (p.kind == "friendlyPlayer" or p.kind == "enemyPlayer") and gameGuild and canaccessvalue(gameGuild)
    if p.guildName.shown then p.guildName:SetText("<" .. gameGuild .. ">") end
end
function canaccessvalue(value) return value ~= secret end
function canaccessallvalues(...)
    for i = 1, select("#", ...) do if select(i, ...) == secret then return false end end
    return true
end
function UnitIsPlayer() return person ~= "Spider" end
function UnitNameUnmodified() return restricted and secret or person end
TRP3_NameUtil = { GetQualifiedName = function() assert(not restricted and person ~= "Spider"); return person end }
AddOn_TotalRP3 = { Player = { CreateFromCharacterID = function(id)
    local data = records[id] or {}
    return { GetFirstName = function() return data[1] end, GetFullName = function() return data[2] end,
        GetLastName = function() return data[4] end,
        GetCustomGuildMembership = function() return { name = data.guild } end,
        GetFullTitle = function() return data.title end,
        GetTitle = function() return data.shortTitle end,
        GetCustomColorForDisplay = function() if data[3] then return { GetRGB = function() return data[3], 0, 0 end } end end,
        GetCustomColor = function() if data[3] then return { GetRGB = function() return data[3] / 2, 0, 0 end } end end }
end } }
AddOn_TotalRP3.Player.GetCurrentUser = function() return AddOn_TotalRP3.Player.CreateFromCharacterID("Me") end
function strcmputf8i(a, b) return a:lower() == b:lower() and 0 or 1 end
function strtrim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
TRP3_Addon = {}
TRP3_API = { globals = { player_id = "Me" }, GameEvents = {}, RegisterCallback = function(_, key, fn) callbacks[key] = fn end }
C_Timer = { After = function(_, fn) assert(not queued); queued = fn end }
assert(loadfile("Profile.lua"))("FlareUI_RP", ns)
assert(loadfile("Nameplates.lua"))("FlareUI_RP", ns)
ns.StartNameplates({ registerConfigKey = function(k, v) values[k] = v end,
    getValue = function(k) return values[k] end, registerHandler = function(k, f) handlers[k] = f end }, elements)
local function check(text, red) assert(plate.name.text == text and plate.name.red == red) end
local paint = FlareUI.Nameplates.UpdateName
paint(plate); check("12 Aster", 0.8)
plate.tdb.groupColor = true; paint(plate); check("12 Aster", 0.5)
raid = true; paint(plate); check("12 Aster", 0.5)
plate.tdb.raidColor = false; paint(plate); check("12 Aster", 0.8)
raid, plate.tdb.groupColor = false, false
plate.kind, plate.tdb.guildColor, guild = "friendlyPlayer", true, true
paint(plate); check("12 Aster", 0.5) -- guild colour wins over RP colour
guild = secret
paint(plate); check("12 Aster", 0.5) -- restricted membership is not a class-colour decision
guild = false
paint(plate); check("12 Aster", 0.8)
guild, plate.kind = true, "enemyPlayer"
paint(plate); check("12 Aster", 0.8) -- guild setting applies only to friendly players
guild, plate.tdb.guildColor = false, false
records.A[4], plate.nameFull = "Moonfall", "lastname"
paint(plate); check("12 Moonfall", 0.8)
plate.nameFull = true
paint(plate); check("12 Aster Moonfall", 0.8)
handlers.flareui_rp_plate_names(nil, false); check("12 A", 0.8)
handlers.flareui_rp_plate_colours(nil, false); check("12 A", 0.5)
handlers.flareui_rp_plate_names(nil, true); check("12 Aster Moonfall", 0.5)
handlers.flareui_rp_plate_colours(nil, true)
plate.nameOnly = false
plate.aboveName = { SetText = plate.name.SetText, SetFormattedText = plate.name.SetFormattedText,
    SetTextColor = plate.name.SetTextColor, IsShown = function() return true end }
plate.aboveKind = "lastname"
paint(plate); assert(plate.aboveName.text == "12 Moonfall" and plate.name.text == "12 Aster Moonfall")
plate.aboveKind = "firstname"
paint(plate); assert(plate.aboveName.text == "12 Aster" and plate.name.text == "12 Aster Moonfall")
records.A[3] = 0.6
local bar = FlareUI.Nameplates.UpdateColor
paint(plate); bar(plate); check("12 Aster Moonfall", 0.5); assert(plate.fill == 0.3)
plate.tdb.nameClassColor = true
-- No lift from the host (including older releases): keep the display colour.
paint(plate); check("12 Aster Moonfall", 0.6); assert(plate.aboveName.red == 0.6)
plate.aboveColor = {} -- stock UpdateBarName chose its in-bar contrast treatment
paint(plate); bar(plate)
check("12 Aster Moonfall", 0.84)
assert(plate.name.green == 0.6 and plate.name.blue == 0.6)
assert(plate.aboveName.red == 0.6 and plate.aboveName.green == 0 and plate.fill == 0.3)
handlers.flareui_rp_plate_names(nil, false); check("12 A", 0.84)
plate.aboveColor = nil
handlers.flareui_rp_plate_colours(nil, false); check("12 A", 0.5)
assert(plate.aboveName.red == 0.5)
handlers.flareui_rp_plate_names(nil, true)
handlers.flareui_rp_plate_colours(nil, true)
plate.tdb.groupColor = true
paint(plate); check("12 Aster Moonfall", 0.5); assert(plate.aboveName.red == 0.5) -- group colour wins
plate.tdb.groupColor, plate.tdb.nameClassColor = false, false
paint(plate); check("12 Aster Moonfall", 0.5) -- default full-plate text stays stock
local function flush() local fn = assert(queued); queued = nil; fn() end
stockRed = secret
bar(plate); assert(plate.fill == secret, "a currently restricted host colour must stand")
stockRed = 0.4
callbacks.REGISTER_DATA_UPDATED(nil, "A"); flush()
assert(plate.fill == 0.3, "a previously restricted colour must not delay an RP update")
restricted = true
callbacks.REGISTER_DATA_UPDATED(nil, "A"); flush()
assert(plate.fill == 0.4, "an unreadable identity must restore the host colour")
restricted = false
for _, mode in ipairs({ "reaction", "off" }) do
    plate.tdb.healthColor = mode; bar(plate); assert(plate.fill == 0.4)
end
plate.tdb.healthColor = "class"
plate.nameSlot = nil
plate.aboveKind = "fullname"
paint(plate); assert(plate.aboveName.text == "12 Aster Moonfall" and plate.aboveName.red == 0.5)
plate.levelFollow, plate.tdb.nameClassColor = false, true
handlers.flareui_rp_plate_names(nil, false); assert(plate.aboveName.text == "A" and plate.aboveName.red == 0.6)
person = "B"; paint(plate); assert(plate.aboveName.text == "B" and plate.aboveName.red == 0.5)
person = "A"
handlers.flareui_rp_plate_names(nil, true)
assert(plate.aboveName.text == "Aster Moonfall" and plate.aboveName.red == 0.6)
plate.levelFollow = true
bar(plate); assert(plate.fill == 0.3)
handlers.flareui_rp_plate_colours(nil, false); assert(plate.fill == 0.4)
handlers.flareui_rp_plate_colours(nil, true); assert(plate.fill == 0.3)
plate.threatRGB = {}; bar(plate); assert(plate.fill == 0.4)
plate.threatRGB = nil; plate.tdb.healthColor = "health"; bar(plate); assert(plate.fill == 0.4)
plate.tdb.healthColor = "class"; tapped = true; bar(plate); assert(plate.fill == 0.4)
tapped = false; plate.nameOnly = true; plate.nameSlot = "left"; plate.aboveKind = nil
paint(plate); bar(plate); check("12 Aster Moonfall", 0.6); assert(plate.fill == 0.4)
person = "Spider"; paint(plate); check("12 Spider", 0.5)
person = "B"; paint(plate); check("12 B", 0.5)
records.B = { "Birch", "Birch Winter", 0 }
local n, b = namesPainted, barsPainted
callbacks.REGISTER_DATA_UPDATED(nil, "A"); flush()
assert(namesPainted == n and barsPainted == b, "unrelated character must not repaint the plate")
callbacks.REGISTER_DATA_UPDATED(nil, "B")
callbacks.REGISTER_DATA_UPDATED(nil, "A"); flush()
check("12 Birch Winter", 0)
assert(namesPainted == n + 1 and barsPainted == b + 1, "batched character updates repaint once")
callbacks.REGISTER_DATA_UPDATED(nil, "B")
person = "A"; flush()
assert(namesPainted == n + 1, "recycled plate must be matched using its current identity")
person = "B"
callbacks.REGISTER_DATA_UPDATED(nil, "A"); callbacks.REGISTER_PROFILES_LOADED()
local fn = queued; queued = nil; fn(); check("12 Birch Winter", 0)
assert(namesPainted == n + 2, "broad event must supersede queued IDs")
restricted = true; paint(plate); check("12 B", 0.5)
restricted = false
records.B[3] = nil
paint(plate); check("12 Birch Winter", 0.5) -- name-only profile
records.B = nil
paint(plate); check("12 B", 0.5) -- profile removed on the same visible unit
local label = { SetText = plate.name.SetText, SetTextColor = plate.name.SetTextColor,
    IsShown = function(self) return self.shown end, Show = function(self) self.shown = true end,
    ClearAllPoints = function(self) self.anchor = nil end, SetPoint = function(self, _, anchor) self.anchor = anchor end }
plate.guildName, plate.tdb.showGuild = label, true
local paintGuild = FlareUI.Nameplates.UpdateGuild
handlers.flareui_rp_plate_names(nil, false)
handlers.flareui_rp_plate_colours(nil, false)
records.B = { guild = "  Night Watch  " }
paintGuild(plate); assert(not label.shown, "RP guild names are opt-in")
handlers.flareui_rp_plate_guilds(nil, true)
callbacks.REGISTER_DATA_UPDATED(nil, "B"); flush()
assert(label.shown and label.text == "<Night Watch>" and label.anchor == plate.name)
plate.npcTitle = { IsShown = function() return true end }
plate.kind = "friendlyPlayer"; paintGuild(plate)
assert(label.anchor == plate.npcTitle and label.red == 0.85)
gameGuild = "Stock"; paintGuild(plate); assert(label.text == "<Night Watch>")
handlers.flareui_rp_plate_guilds(nil, false); assert(label.text == "<Stock>")
handlers.flareui_rp_plate_guilds(nil, true)
records.B.guild = string.rep(" ", 8000); paintGuild(plate); assert(label.text == "<Stock>")
records.B.guild = "Night Watch"
restricted = true; paintGuild(plate); assert(label.text == "<Stock>")
restricted = false
person = "A"; paintGuild(plate); assert(label.text == "<Stock>")
person = "B"; gameGuild = secret; paintGuild(plate); assert(not label.shown)
gameGuild = nil; plate.tdb.showGuild = false; paintGuild(plate); assert(not label.shown)
plate.tdb.showGuild = true; plate.nameOnly = false; paintGuild(plate); assert(not label.shown)
plate.nameOnly = true; plate.kind = "friendlyNpc"; paintGuild(plate); assert(not label.shown)
handlers.flareui_rp_plate_guilds(nil, false)
plate.kind, plate.tdb.guildColor, plate.tdb.groupColor, plate.tdb.showGuild = "friendlyPlayer", true, false, false
ChatTypeInfo = { GUILD = { r = 0.1, g = 0.9, b = 0.2 } }
paint(plate); assert(plate.name.red == 0.5, "RP guildmate colour is opt-in")
handlers.flareui_rp_plate_guild_colours(nil, true)
paint(plate); assert(plate.name.red == 0.1 and plate.name.green == 0.9 and not label.shown)
records.Me.guild = "Other"; callbacks.REGISTER_DATA_UPDATED(nil, "Me"); flush()
assert(plate.name.red == 0.5, "changing own guild restores other plates")
records.Me.guild = "Night Watch"; callbacks.REGISTER_DATA_UPDATED(nil, "Me"); flush()
assert(plate.name.red == 0.1)
guild = secret; paint(plate); assert(plate.name.red == 0.5)
guild = false; plate.tdb.groupColor = true; paint(plate); assert(plate.name.red == 0.5)
plate.tdb.groupColor = false; plate.kind = "enemyPlayer"; paint(plate); assert(plate.name.red == 0.5)
plate.kind = "friendlyPlayer"; plate.nameOnly = false; paint(plate); assert(plate.name.red == 0.5)
plate.nameOnly = true; plate.tdb.guildColor = false; paint(plate); assert(plate.name.red == 0.5)
plate.tdb.guildColor = true
handlers.flareui_rp_plate_guild_colours(nil, false); assert(plate.name.red == 0.5)
handlers.flareui_rp_plate_guild_colours(nil, true)
plate.npcTitle = { SetText = label.SetText, IsShown = label.IsShown, Show = label.Show, SetTextColor = label.SetTextColor }
function plate.npcTitle:SetWordWrap(on) self.wrap = on end
function plate.npcTitle:GetStringHeight() return 32 end
plate.box = {}
function plate.name:SetPoint(point, box, relative, x, y)
    assert(point == "CENTER" and box == plate.box and relative == "CENTER" and x == 0)
    self.lift = y
end
plate.tdb.showTitles, plate.tdb.showGuild = true, true
records.B.title = "  Keeper of the Watch  "
handlers.flareui_rp_plate_guilds(nil, true)
local updateTitle = FlareUI.Nameplates.UpdateTitle
updateTitle(plate); assert(not plate.npcTitle.shown and label.anchor == plate.name)
handlers.flareui_rp_plate_titles(nil, "full")
assert(plate.npcTitle.text == "Keeper of the Watch" and label.anchor == plate.npcTitle)
records.B.title = "Knight of the Silver Hand || Veteran of the Third War"
updateTitle(plate)
assert(plate.npcTitle.wrap and plate.npcTitle.text == "Knight of the Silver Hand\nVeteran of the Third War")
assert(plate.name.lift == 33 and label.anchor == plate.npcTitle)
handlers.flareui_rp_plate_titles(nil, "none")
assert(plate.npcTitle.wrap == false and not plate.npcTitle.shown and label.anchor == plate.name)
assert(plate.name.lift == 0)
handlers.flareui_rp_plate_titles(nil, "full")
records.B.title = " | Keeper || |   |cffff0000Warden|r|Herald | "
updateTitle(plate)
assert(plate.npcTitle.text == "Keeper\n|cffff0000Warden|r\nHerald" and label.anchor == plate.npcTitle)
records.B.title = " || | "
updateTitle(plate); assert(not plate.npcTitle.shown and label.anchor == plate.name)
local invisible = "|cffff0000 \194\160\226\128\139|r" -- NBSP and zero-width space
records.B.title = invisible
updateTitle(plate); assert(not plate.npcTitle.shown and label.anchor == plate.name)
records.B.title = "Étoile\194\160du Nord | " .. invisible .. " | Warden"
updateTitle(plate); assert(plate.npcTitle.text == "Étoile\194\160du Nord\nWarden")
records.B.title = "Wanderer - Alchemist | Half-Elf - Explorer- Keeper -Warden"
updateTitle(plate)
assert(plate.npcTitle.text == "Wanderer\nAlchemist\nHalf-Elf\nExplorer- Keeper -Warden")
records.B.title = "< Explorer >   < Paladin >< Blacksmith >"
updateTitle(plate); assert(plate.npcTitle.text == "< Explorer >\n< Paladin >\n< Blacksmith >")
for _, framed in ipairs({ "< • [ Tanner - Tea Lover - Scavenger ] • >", "• [Tanner - Tea Lover - Scavenger] •" }) do
    records.B.title = framed
    updateTitle(plate); assert(plate.npcTitle.text == "Tanner\nTea Lover\nScavenger")
end
records.B.title = "< • [ Tea Lover ] • >"
updateTitle(plate); assert(plate.npcTitle.text == records.B.title)
records.B.title = "• [Tanner] • - • [Scavenger] •"
updateTitle(plate); assert(plate.npcTitle.text == "• [Tanner] •\n• [Scavenger] •")
records.B.title = "« ✦✦ {Éclaireur │ 茶師} ✦✦ »"
updateTitle(plate); assert(plate.npcTitle.text == "Éclaireur\n茶師")
records.B.title = "★ Keeper - Seeker ☆"
updateTitle(plate); assert(plate.npcTitle.text == "★ Keeper\nSeeker ☆")
records.B.title = "Érudite - Été"
updateTitle(plate); assert(plate.npcTitle.text == "Érudite\nÉté")
for _, case in ipairs({
    { "◆ | Tanner | Scavenger | ◆", "Tanner\nScavenger" },
    { "« | Tanner | ★ | Scavenger | »", "Tanner\n★\nScavenger" },
    { "~~ | Tanner | Scavenger | ~~", "Tanner\nScavenger" },
    { "• | Tanner | •", "•\nTanner\n•" },
    { "◆ | Tanner | Scavenger", "◆\nTanner\nScavenger" },
    { "~~ | Tanner | Scavenger | ~", "~~\nTanner\nScavenger\n~" },
    { "Guard | Tanner | Scavenger | Guard", "Guard\nTanner\nScavenger\nGuard" },
}) do
    records.B.title = case[1]
    updateTitle(plate); assert(plate.npcTitle.text == case[2], case[1])
end
records.B.title = "Knight of the Silver Hand │ Veteran of the Third War｜Explorer"
updateTitle(plate); assert(plate.npcTitle.text == "Knight of the Silver Hand\nVeteran of the Third War\nExplorer")
records.B.title = "|Hitem:1|h<First><Second>|h │ Keeper’s Oath > All"
updateTitle(plate); assert(plate.npcTitle.text == "|Hitem:1|h<First><Second>|h\nKeeper’s Oath > All")
gameTitle = secret; updateTitle(plate); assert(not plate.npcTitle.shown and label.anchor == plate.name)
gameTitle = "Corporal"; records.B.title = " "
callbacks.REGISTER_DATA_UPDATED(nil, "B"); flush(); assert(plate.npcTitle.text == "Corporal")
records.B.title = "Keeper"; plate.tdb.showTitles = false; updateTitle(plate); assert(not plate.npcTitle.shown)
plate.tdb.showTitles = true; updateTitle(plate); assert(plate.npcTitle.text == "Keeper")
handlers.flareui_rp_plate_titles(nil, "short"); assert(plate.npcTitle.text == "Corporal")
records.B.shortTitle = invisible; updateTitle(plate); assert(plate.npcTitle.text == "Corporal")
records.B.shortTitle = "Dame | Keeper - Warden"; callbacks.REGISTER_DATA_UPDATED(nil, "B"); flush()
assert(plate.npcTitle.text == records.B.shortTitle)
handlers.flareui_rp_plate_titles(nil, "full"); assert(plate.npcTitle.text == "Keeper")
for _, empty in ipairs({ invisible, " || | ", "" }) do
    records.B.title = empty
    updateTitle(plate)
    assert(plate.npcTitle.text == records.B.shortTitle and not plate.npcTitle.wrap)
end
handlers.flareui_rp_plate_titles(nil, "none"); assert(plate.npcTitle.text == "Corporal")
local owner, linked = "Other-Realm", nil
function UnitOwnerGUID() return owner end
TRP3_API.ui = { misc = { getTargetType = function() return "pet" end,
    isTargetTypeACompanion = function(k) return k == "pet" end,
    getCompanionFullID = function(unit)
        if unit == "nameplate2" then return "Second-Realm_Spider", "Second-Realm" end
        return owner .. "_Spider", owner
    end } }
local secondLookups = 0
TRP3_API.companions = { register = { getCompanionProfile = function(id)
    if id == "Second-Realm_Spider" then secondLookups = secondLookups + 1; return { data = { NA = "Web" } } end
    assert(id == "Other-Realm_Spider"); return linked
end } }
TRP3_API.Colors = { Black = {} }
TRP3_API.CreateColorFromHexString = function(hex) assert(hex == "ff0000"); return { GetRGB = function() return 1, 0, 0 end } end
TRP3_API.GenerateReadableColor = function(c) return c end
person, plate.kind, gameTitle = "Spider", "minor", "Other's Pet"
handlers.flareui_rp_plate_names(nil, true)
handlers.flareui_rp_plate_titles(nil, "short")
handlers.flareui_rp_plate_companion_colours(nil, true)
local second = { unit = "nameplate2", gamePlate = plate.gamePlate, kind = "minor", nameOnly = true,
    nameSlot = "left", tdb = {}, name = { SetText = plate.name.SetText, SetTextColor = plate.name.SetTextColor } }
paint(second); assert(second.name.text == "Web")
linked = { data = { NA = "Silk", TI = "The Weaver", NH = "ff0000" } }
local beforeUpdate = namesPainted
callbacks.REGISTER_DATA_UPDATED(nil, "Other-Realm_Spider"); flush()
assert(namesPainted == beforeUpdate + 1 and secondLookups == 1, "same pet name, different owner must not repaint")
assert(plate.name.text:match("Silk$") and plate.name.red == 0.5 and plate.npcTitle.text == "The Weaver")
plate.nameOnly = false
linked.data.NA = nil
paint(plate); assert(plate.name.text:match("Spider$") and plate.name.red == 1)
FlareUI.Nameplates.UpdateColor(plate); assert(plate.fill == stockRed)
callbacks.REGISTER_DATA_UPDATED(nil, "Other-Realm_Spider")
owner = secret
flush(); assert(plate.name.red == 0.5, "restricted identity at flush must restore the host colour")
owner, plate.nameOnly = "Different-Realm", true
TRP3_API.companions.register.getCompanionProfile = function(id) assert(id == "Different-Realm_Spider") end
updateTitle(plate); assert(plate.npcTitle.text == gameTitle)
plate.gamePlate, plate.unit, second.gamePlate = nil, nil, nil
callbacks.REGISTER_PROFILE_DELETED(); queued()
print("PASS: player plate names, display colour, independent settings, prefix, recycled plates and late updates")
