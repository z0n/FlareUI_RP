local ns, values, handlers, events, records, units = {}, {}, {}, {}, {}, {}
local editing, queued = false
function hooksecurefunc(owner, key, fn)
    local original = assert(owner[key])
    owner[key] = function(...) local result = original(...); fn(...); return result end
end
function securecallfunction(fn, ...) return fn(...) end
function canaccessvalue() return true end
function canaccessallvalues() return true end
function UnitExists(u) return units[u] ~= nil end
function UnitIsPlayer() return true end
function UnitIsConnected() return true end
function UnitIsTapDenied() return false end
function UnitNameUnmodified(u) return units[u] end
TRP3_NameUtil = { GetQualifiedName = UnitNameUnmodified }
AddOn_TotalRP3 = { Player = { CreateFromCharacterID = function(id)
    local r = records[id] or {}
    return { GetFirstName = function() return r.first end, GetFullName = function() return r.full end,
        GetCustomColor = function() if r.rgb then return { GetRGB = function() return r.rgb, 0, 0 end } end end }
end } }
TRP3_Addon = {}
TRP3_API = { GameEvents = {}, RegisterCallback = function(_, k, fn) events[k] = fn end }
C_Timer = { After = function(_, fn) assert(not queued); queued = fn end }
local function flush() local fn = queued; queued = nil; fn() end
local function Label()
    return { IsShown = function() return true end,
        SetText = function(self, name) self.text = name end,
        SetFormattedText = function(self, fmt, name) self.text = fmt:format(name) end }
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
FlareUI = { PartyFrames = pf, NameAbove = { SetName = function(f) f.NameAboveText:SetText(units[f.fuiUnit]) end,
        Get = function() return "middle", "fullname" end }, UnitDisplayName = UnitNameUnmodified,
    EditPreviewing = function() return editing end, ClassColorsOn = function(db) return db.classColor end,
    UnitFrames = { HealthColorMode = function() return "off" end, HealthBarColor = function() return 0.5, 0, 0 end },
    db = { profile = { unitframes = { fullNames = true } } } }
assert(loadfile("Profile.lua"))("FlareUI_RP", ns)
assert(loadfile("UnitHealth.lua"))("FlareUI_RP", ns)
assert(loadfile("GroupFrames.lua"))("FlareUI_RP", ns)
units.party1, units.raid1, units.boss1 = "A", "B", "A"
records.A = { first = "Aster", full = "Aster Moonfall", rgb = 0.8 }
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
assert(raid.Name.text == "B" and raid.Health.red == 0.5 and boss.Name.text == "A" and boss.Health.red == 0.5)
records.B = { first = "Birch", full = "Birch Winter", rgb = 0.2 }
events.REGISTER_DATA_UPDATED(); flush()
assert(raid.Name.text == "Birch Winter" and raid.Health.red == 0.2)
raid.fuiUnit, units.raid2 = "raid2", "Unknown"
draw(raid)
assert(raid.Name.text == "Unknown" and raid.Health.red == 0.5)
units.raid2 = "B"; raid.db.classColor = false
draw(raid)
assert(raid.Name.text == "Birch Winter" and raid.Health.red == 0.5)
handlers.flareui_rp_party_names(nil, false); handlers.flareui_rp_party_health(nil, false)
assert(party.Name.text == "A" and party.NameAboveText.text == "A" and party.Health.red == 0.5)
assert(raid.Name.text == "Birch Winter")
editing = true
raid.Name:SetText("Sample")
events.GROUP_ROSTER_UPDATE(); flush()
assert(raid.Name.text == "Sample")
print("PASS: independent group settings, first/full names, recycled raid tiles, host colours and Edit Mode")
