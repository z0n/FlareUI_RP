local ns, callbacks, handlers, values, elements = {}, {}, {}, {}, {}
local queued, person, restricted = nil, "A", false
local plate = { unit = "nameplate1", gamePlate = { IsForbidden = function() return false end },
    nameSlot = "left", levelFollow = true, nameFull = false, nameOnly = true, tdb = { healthColor = "class" }, name = {
        SetFormattedText = function(self, fmt, ...) self.text = fmt:format(...) end,
        SetText = function(self, text) self.text = text end,
        SetTextColor = function(self, r) self.red = r end,
    } }
FlareUI = { Nameplates = { LevelPrefix = function() return "12 " end, UpdateName = function(p)
    p.name:SetText("12 " .. person); p.name:SetTextColor(0.5)
    if p.aboveName and p.aboveKind and p.aboveName:IsShown() then
        p.aboveName:SetText(person)
        p.aboveName:SetTextColor(p.name.red)
    end
end, BarColor = function(p, r) assert(canaccessallvalues(p.barR, p.barG, p.barB)); p.fill = r end,
UpdateColor = function(p) p.fill = 0.4 end } }
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
local records = { A = { "Aster", "Aster Moonfall", 0.8 } }
local secret = {}
function canaccessvalue(value) return value ~= secret end
function canaccessallvalues(...)
    for i = 1, select("#", ...) do if select(i, ...) == secret then return false end end
    return not restricted
end
function UnitIsPlayer() return person ~= "Spider" end
function UnitNameUnmodified() return person end
TRP3_NameUtil = { GetQualifiedName = function() assert(not restricted and person ~= "Spider"); return person end }
AddOn_TotalRP3 = { Player = { CreateFromCharacterID = function(id)
    local data = records[id] or {}
    return { GetFirstName = function() return data[1] end, GetFullName = function() return data[2] end,
        GetCustomColorForDisplay = function() if data[3] then return { GetRGB = function() return data[3], 0, 0 end } end end,
        GetCustomColor = function() if data[3] then return { GetRGB = function() return data[3] / 2, 0, 0 end } end end }
end } }
TRP3_Addon = {}
TRP3_API = { GameEvents = {}, RegisterCallback = function(_, key, fn) callbacks[key] = fn end }
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
plate.nameFull = true
paint(plate); check("12 Aster Moonfall", 0.8)
handlers.flareui_rp_plate_names(nil, false); check("12 A", 0.8)
handlers.flareui_rp_plate_colours(nil, false); check("12 A", 0.5)
handlers.flareui_rp_plate_names(nil, true); check("12 Aster Moonfall", 0.5)
handlers.flareui_rp_plate_colours(nil, true)
plate.nameOnly = false
plate.aboveName = { SetText = plate.name.SetText, SetTextColor = plate.name.SetTextColor, IsShown = function() return true end }
plate.aboveKind = "firstname"
paint(plate); assert(plate.aboveName.text == "Aster" and plate.name.text == "12 Aster Moonfall")
records.A[3] = 0.6
local bar = FlareUI.Nameplates.UpdateColor
paint(plate); bar(plate); check("12 Aster Moonfall", 0.5); assert(plate.fill == 0.3)
plate.tdb.nameClassColor = true
paint(plate); check("12 Aster Moonfall", 0.6); assert(plate.aboveName.red == 0.6)
handlers.flareui_rp_plate_names(nil, false); check("12 A", 0.6)
handlers.flareui_rp_plate_colours(nil, false); check("12 A", 0.5)
assert(plate.aboveName.red == 0.5)
handlers.flareui_rp_plate_names(nil, true)
handlers.flareui_rp_plate_colours(nil, true)
plate.tdb.groupColor = true
paint(plate); check("12 Aster Moonfall", 0.5); assert(plate.aboveName.red == 0.5) -- group colour wins
plate.tdb.groupColor, plate.tdb.nameClassColor = false, false
paint(plate); check("12 Aster Moonfall", 0.5) -- default full-plate text stays stock
plate.barG = secret
bar(plate); assert(plate.fill == 0.4) -- host repaint stands, no extra cache comparison
plate.barG = nil
bar(plate); assert(plate.fill == 0.3)
for _, mode in ipairs({ "reaction", "off" }) do
    plate.tdb.healthColor = mode; bar(plate); assert(plate.fill == 0.4)
end
plate.tdb.healthColor = "class"
plate.nameSlot = nil
plate.aboveKind = "fullname"
paint(plate); assert(plate.aboveName.text == "Aster Moonfall")
handlers.flareui_rp_plate_names(nil, false); assert(plate.aboveName.text == "A")
handlers.flareui_rp_plate_names(nil, true)
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
callbacks.REGISTER_DATA_UPDATED(); callbacks.REGISTER_PROFILES_LOADED()
local fn = queued; queued = nil; fn(); check("12 Birch Winter", 0)
restricted = true; paint(plate); check("12 B", 0.5)
restricted = false
records.B[3] = nil
paint(plate); check("12 Birch Winter", 0.5) -- name-only profile
records.B = nil
paint(plate); check("12 B", 0.5) -- profile removed on the same visible unit
plate.gamePlate, plate.unit = nil, nil
callbacks.REGISTER_PROFILE_DELETED(); queued()
print("PASS: player plate names, display colour, independent settings, prefix, recycled plates and late updates")
