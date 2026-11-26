local ns, values, handlers, events, records, units = {}, {}, {}, {}, {}, {}
local editing, queued, lookups = false, nil, 0
function hooksecurefunc(owner, key, fn)
    local original = assert(owner[key])
    owner[key] = function(...) local result = original(...); fn(...); return result end
end
function securecallfunction(fn, ...) return fn(...) end
local secret = {}
function canaccessvalue(value) return value ~= secret end
function canaccessallvalues() return true end
function UnitExists(u) return units[u] == secret and secret or units[u] ~= nil end
function UnitIsPlayer() return true end
function UnitIsConnected() return true end
function UnitIsTapDenied() return false end
function UnitNameUnmodified(u) return units[u] end
TRP3_NameUtil = { GetQualifiedName = UnitNameUnmodified }
AddOn_TotalRP3 = { Player = { CreateFromCharacterID = function(id)
    lookups = lookups + 1
    local r = records[id] or {}
    return { GetFirstName = function() return r.first end, GetFullName = function() return r.full end,
        GetLastName = function() return r.last end,
        GetCharacteristics = function() return r end }
end } }
TRP3_Addon = {}
TRP3_API = { GameEvents = {}, RegisterCallback = function(_, k, fn) events[k] = fn end }
function strtrim(s) return s:match("^%s*(.-)%s*$") end
function TRP3_API.ParseColorFromHexString(s)
    return { GetRGB = function() return tonumber(s:sub(1, 2), 16) / 255, 0, 0 end }
end
C_Timer = { After = function(_, fn) assert(not queued); queued = fn end }
local function flush() local fn = queued; queued = nil; fn() end
local function Label()
    return { IsShown = function() return true end,
        SetText = function(self, name) self.text = name end,
        SetFormattedText = function(self, fmt, ...) self.text = fmt:format(...) end }
end
local function Tile(unit)
    return { fuiUnit = unit, Name = Label(), NameAboveText = Label(), IsVisible = function() return true end,
        Health = { SetStatusBarColor = function(self, r) self.red = r end }, db = { classColor = true } }
end
local party, raid, boss = Tile("party1"), Tile("raid1"), Tile("boss1")
party.index, party.btFullName, FlareUI_Party1 = 1, false, party
raid.flareTile, raid.ctx = true, { fontKey = "raid" }
boss.ctx = { fontKey = "boss" }
local pf = { SlotOn = function(f) return f.index ~= nil end, NameAboveDb = function(f) return f.db end }
function pf.SlotStyle(f) return f.style or "plain" end
FlareUI = { PartyFrames = pf, NameAbove = { SetName = function(f) f.NameAboveText:SetText(units[f.fuiUnit]) end,
        Get = function() return "middle", "fullname" end }, UnitDisplayName = UnitNameUnmodified,
    EditPreviewing = function() return editing end, ClassColorsOn = function(db) return db.classColor end,
    UnitFrames = { HealthColorMode = function() return "off" end, HealthBarColor = function() return 0.5, 0, 0 end },
    db = { profile = { unitframes = { fullNames = true } } } }
assert(loadfile("Profile.lua"))("FlareUI_RP", ns)
assert(loadfile("UnitHealth.lua"))("FlareUI_RP", ns)
assert(loadfile("GroupFrames.lua"))("FlareUI_RP", ns)
units.party1, units.raid1, units.boss1 = "A", "B", "A"
records.A = { first = "Aster", full = "Aster Moonfall", CH = "cc0000" }
ns.StartGroupFrames({ registerConfigKey = function(k, v) values[k] = v end, getValue = function(k) return values[k] end,
    registerHandler = function(k, fn) handlers[k] = fn end }, {})
local function draw(f)
    pf.SlotOn(f)
    f.Name:SetText(units[f.fuiUnit])
    FlareUI.NameAbove.SetName(f)
    f.Health:SetStatusBarColor(0.5, 0, 0)
end
flush(); draw(party); draw(raid); draw(boss)
assert(party.Name.text == "Aster" and party.NameAboveText.text == "Aster Moonfall" and party.Health.red == 0.8)
local beforePaint = lookups
events.REGISTER_DATA_UPDATED(nil, "A"); flush()
assert(lookups == beforePaint + 1, "one profile supplies both names and health on a callback refresh")
party.NameAboveText.IsShown = function() return false end
beforePaint = lookups
draw(party)
assert(lookups == beforePaint + 1, "a hidden above-name must not add a profile lookup")
party.NameAboveText.IsShown = function() return true end
party.NameAboveText.text = "previous above"
party.Name:SetText("stock member")
assert(party.NameAboveText.text == "previous above", "member hook must not paint the above-name")
beforePaint = lookups
party.Name.text = "previous member"
FlareUI.NameAbove.SetName(party)
assert(lookups == beforePaint + 1 and party.Name.text == "previous member" and party.NameAboveText.text == "Aster Moonfall")
assert(raid.Name.text == "B" and raid.Health.red == 0.5 and boss.Name.text == "A" and boss.Health.red == 0.5)
party.style, party.btFullName = "partytile", true
FlareUI.db.profile.unitframes.fullNames = false
draw(party); assert(party.Name.text == "Aster")
FlareUI.db.profile.unitframes.fullNames = true
draw(party); assert(party.Name.text == "Aster Moonfall")
units.party1 = secret
local beforeRestricted = lookups
draw(party); assert(lookups == beforeRestricted and party.Name.text == secret)
units.party1 = "A"
records.B = { first = "Birch", full = "Birch Winter", CH = "330000" }
local tank = Tile("raid1")
tank.flareTile, tank.ctx = true, raid.ctx
draw(tank)
local before = lookups
events.REGISTER_DATA_UPDATED(nil, "Stranger"); flush()
assert(lookups == before, "an unrelated update must not fetch any group profiles")
records.B.full = "Birch Frost"
events.REGISTER_DATA_UPDATED(nil, "B"); events.REGISTER_DATA_UPDATED(nil, "B"); flush()
assert(raid.Name.text == "Birch Frost" and tank.Name.text == "Birch Frost")
records.B.full = "Birch Winter"
events.REGISTER_DATA_UPDATED(nil, "A"); events.GROUP_ROSTER_UPDATE(); flush()
assert(raid.Name.text == "Birch Winter" and raid.Health.red == 0.2)
raid.fuiUnit, units.raid2 = "raid2", "Unknown"
draw(raid)
assert(raid.Name.text == "Unknown" and raid.Health.red == 0.5)
units.raid2 = "B"; raid.db.classColor = false
draw(raid)
assert(raid.Name.text == "Birch Winter" and raid.Health.red == 0.5)
-- Released per-layout helper overrides the global full-name setting.
function pf.NameFull(f) return f.format end
FlareUI.NameAbove.Get = function(db) return "middle", db.above or "fullname" end
party.format, raid.format, raid.db.above = "lastname", false, "lastname"
records.A.last, records.B.last = "Moonfall", "Winter"
draw(party); draw(raid)
assert(party.Name.text == "Moonfall" and party.NameAboveText.text == "Aster Moonfall")
assert(raid.Name.text == "Birch" and raid.NameAboveText.text == "Winter")
raid.format = nil
events.GROUP_ROSTER_UPDATE(); flush()
assert(raid.Name.text == "Birch Winter" and raid.NameAboveText.text == "Winter")
handlers.flareui_rp_party_names(nil, false); handlers.flareui_rp_party_health(nil, false)
assert(party.Name.text == "A" and party.NameAboveText.text == "A" and party.Health.red == 0.5)
assert(raid.Name.text == "Birch Winter")
FlareUI.NameAbove.LevelText = function() return "42 " end
FlareUI.UnitShownLevel = function() return 42 end
FlareUI.UnitLevelColor = function() return {} end
local levels = { showLevel = true }
raid.ctx.Settings = function() return levels end
FlareUI.NameAbove.SetName(raid, raid.db, raid.fuiUnit, levels)
assert(raid.NameAboveText.text == "42 Winter")
handlers.flareui_rp_raid_names(nil, false)
assert(raid.NameAboveText.text == "42 B")
raid.ringKind = "forever"
handlers.flareui_rp_raid_names(nil, true)
assert(raid.NameAboveText.text == "Winter")
editing = true
raid.Name:SetText("Sample")
events.GROUP_ROSTER_UPDATE(); flush()
assert(raid.Name.text == "Sample")
print("PASS: independent group settings, first/full names, recycled raid tiles, host colours and Edit Mode")
