local ns, events, queued, afterName = {}, {}
local target = { Name = { SetText = function(self, name) self.text = name end } }
FlareUI_UF_Target = target
local playerFrame = { Name = { SetText = target.Name.SetText } }
FlareUI_UF_Player = playerFrame
target.fuiUnit, playerFrame.fuiUnit = "target", "player"
local function aboveLabel()
    return { SetText = target.Name.SetText, shown = true, IsShown = function(self) return self.shown end }
end
target.NameAboveText, playerFrame.NameAboveText = aboveLabel(), aboveLabel()
local layouts = { player = { kind = "firstname" }, target = { kind = "fullname" } }
local id, full, restricted, npc = "A", false, false, false
local records = { A = { "Lady Aster", "Lady Aster Moonfall" }, Self = { "Robin", "Robin Hill" } }
function UnitExists(unit) return unit == "player" or id ~= nil end
function UnitIsPlayer(unit) return unit == "player" or not npc end
function UnitNameUnmodified(unit) return unit == "player" and "Self" or id end
function canaccessvalue() return true end
function canaccessallvalues() return not restricted end
TRP3_NameUtil = { GetQualifiedName = function(unit) assert(not restricted and UnitIsPlayer(unit)); return UnitNameUnmodified(unit) end }
AddOn_TotalRP3 = { Player = { CreateFromCharacterID = function(key)
    local p = records[key] or {}
    return { GetFirstName = function() return p[1] end, GetFullName = function() return p[2] end,
        GetLastName = function() return p[3] end, GetCustomColor = function() return nil end }
end } }
FlareUI = { db = { profile = { unitframes = { units = layouts } } },
    NameAbove = { SetName = function() end, Get = function(db) if db and db.kind then return "middle", db.kind end end },
    UnitFrames = { SetNameAbove = function() end, ShowsFullName = function(f) return f == playerFrame or full end },
    UnitDisplayName = UnitNameUnmodified, ClassColorsOn = function() return true end, EditPreviewing = function() return false end }
FlareUI.UnitFrames.FillSlots = function() end
FlareUI.UnitFrames.HealthColorMode = function() return "off" end
FlareUI.UnitFrames.HealthBarColor = function() return 1, 1, 1 end
function hooksecurefunc(t, key, fn)
    if t == FlareUI.UnitFrames and key == "FillSlots" then return end
    assert(t == FlareUI.UnitFrames and key == "SetNameAbove"); afterName = fn
end
TRP3_Addon = {}
TRP3_API = { GameEvents = {}, RegisterCallback = function(_, key, fn) events[key] = fn end }
local values, handlers = {}, {}
TRP3_API.configuration = {
    registerConfigKey = function(k, v) values[k] = v end,
    getValue = function(k) return values[k] end,
    registerHandler = function(k, fn) handlers[k] = fn end,
    registerConfigurationPage = function(page)
        local count = 0
        for _, element in ipairs(page.elements) do if element.configKey then count = count + 1 end end
        assert(count == 6)
    end,
}
C_Timer = { After = function(_, fn) assert(not queued); queued = fn end }
local function flush() local fn = assert(queued); queued = nil; fn() end
assert(loadfile("Profile.lua"))("FlareUI_RP", ns)
assert(loadfile("UnitHealth.lua"))("FlareUI_RP", ns)
assert(loadfile("Nameplates.lua"))("FlareUI_RP", ns)
assert(loadfile("GroupFrames.lua"))("FlareUI_RP", ns)
assert(loadfile("SetupHints.lua"))("FlareUI_RP", ns)
assert(loadfile("Toolbar.lua"))("FlareUI_RP", ns)
assert(loadfile("MainWindow.lua"))("FlareUI_RP", ns)
assert(loadfile("UnitFrames.lua"))("FlareUI_RP", ns)
events.WORKFLOW_ON_LOADED()
flush()
assert(target.Name.text == "Lady Aster")
assert(playerFrame.Name.text == "Robin Hill")
assert(playerFrame.NameAboveText.text == "Robin" and target.NameAboveText.text == "Lady Aster Moonfall")
handlers.flareui_rp_unit_names(nil, false)
assert(ns.healthEnabled.player and ns.healthEnabled.target and playerFrame.Name.text == "Self" and target.NameAboveText.text == "A")
target.Name.text = "host text"
afterName(target)
assert(target.Name.text == "host text")
handlers.flareui_rp_target_health(nil, false)
handlers.flareui_rp_unit_names(nil, true)
assert(not ns.healthEnabled.target and ns.healthEnabled.player and target.Name.text == "Lady Aster")
full = true
afterName(target)
assert(target.Name.text == "Lady Aster Moonfall")
layouts.target.kind = "firstname"
afterName(target)
assert(target.NameAboveText.text == "Lady Aster")
layouts.target.kind = "fullname"
full, records.A[3] = "lastname", "Moonfall"
afterName(target)
assert(target.Name.text == "Moonfall" and target.NameAboveText.text == "Lady Aster Moonfall")
full = true
layouts.target.kind = "lastname"
afterName(target)
assert(target.Name.text == "Lady Aster Moonfall" and target.NameAboveText.text == "Moonfall")
records.A[3] = ""
afterName(target)
assert(target.NameAboveText.text == "Lady Aster")
target.NameAboveText.shown = false
target.NameAboveText.text = "untouched"
afterName(target)
assert(target.NameAboveText.text == "untouched")
target.NameAboveText.shown = true
layouts.target.kind = nil
afterName(target)
assert(target.NameAboveText.text == "untouched")
layouts.target.kind = "fullname"
id, npc = "Forest Spider", true
afterName(target)
assert(target.Name.text == "Forest Spider")
assert(target.NameAboveText.text == "Forest Spider")
records.Self = { "Rowan", "Rowan Hill" }
events.REGISTER_DATA_UPDATED()
flush()
assert(playerFrame.Name.text == "Rowan Hill" and target.Name.text == "Forest Spider")
assert(playerFrame.NameAboveText.text == "Rowan")
id = nil
records.Self = nil
events.REGISTER_PROFILES_LOADED()
flush()
assert(playerFrame.Name.text == "Self", "player must refresh even when there is no target")
id, npc = "B", false
afterName(target)
assert(target.Name.text == "B")
records.B = { "Birch", "Birch Winter" }
events.REGISTER_DATA_UPDATED()
events.REGISTER_PROFILES_LOADED()
flush()
assert(target.Name.text == "Birch Winter")
assert(target.NameAboveText.text == "Birch Winter")
records.B = nil
events.REGISTER_PROFILE_DELETED()
flush()
assert(target.Name.text == "B")
id, restricted = "A", true
afterName(target)
assert(target.Name.text == "A")
local other = { Name = { SetText = function() error("not the target frame") end } }
afterName(other)
restricted, npc, full = false, false, false
for unit, key in pairs({ focus = "Focus", targettarget = "TargetOfTarget", focustarget = "TargetOfFocus" }) do
    local f = { fuiUnit = unit, Name = aboveLabel(), NameAboveText = aboveLabel() }
    _G["FlareUI_UF_" .. key] = f
    layouts[unit] = { kind = "fullname" }
    id = "A"
    afterName(f)
    assert(f.Name.text == "Lady Aster" and f.NameAboveText.text == "Lady Aster Moonfall")
    id, npc = "Spider", true
    afterName(f)
    assert(f.Name.text == "Spider" and f.NameAboveText.text == "Spider")
    id, npc = "A", false
    f.IsForbidden = function() return true end
    afterName(f)
    assert(f.Name.text == "Spider")
    f.IsForbidden = nil
    handlers.flareui_rp_unit_names(nil, false)
    assert(f.Name.text == "A")
    handlers.flareui_rp_unit_names(nil, true)
    assert(f.Name.text == "Lady Aster")
end
id, npc = "A", false
layouts.target.showLevel = true
local label = target.NameAboveText
function label:SetFormattedText(fmt, ...) self.text = fmt:format(...) end
FlareUI.UnitShownLevel = function() return 60 end
FlareUI.UnitLevelColor = function() return "difficulty" end
function UnitClassification() return "rare" end
FlareUI.NameAbove.LevelText = function(level, color, _, mark)
    assert(color == "difficulty")
    return level .. mark .. " "
end
afterName(target)
assert(label.text == "60R Lady Aster Moonfall")
handlers.flareui_rp_unit_names(nil, false)
assert(label.text == "60R A")
FlareUI.UFRing = { Applies = function(f) return f == target end }
handlers.flareui_rp_unit_names(nil, true)
assert(label.text == "Lady Aster Moonfall")
local secret = {}
FlareUI.UFRing = nil
id = "Unknown"
FlareUI.UnitDisplayName = function() return nil end
afterName(target)
assert(label.text == "60R ", "an unresolved game name leaves only the level prefix")
FlareUI.UnitDisplayName = UnitNameUnmodified
id = "A"
FlareUI.UnitShownLevel = function() return secret end
function canaccessvalue(value) return value ~= secret end
function label:SetFormattedText(fmt, level, name)
    assert(fmt == "%s %s" and level == secret and name == "Lady Aster Moonfall")
    self.text = "passed through"
end
afterName(target)
assert(label.text == "passed through")
target.NameAboveText = nil
id = "B"
records.B = { "Birch", "Birch Winter" }
target.Name:SetText(id)
afterName(target)
assert(target.Name.text == "Birch", "a target swap updates the in-frame name with Name Above Frames off")
target.Name:SetText("Sample")
afterName(target, true)
assert(target.Name.text == "Sample")
print("PASS: direct frame names, level prefixes, NPC and restricted fallback, late and deleted profiles")
