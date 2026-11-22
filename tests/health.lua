local id, rgb, db, tick = "Self", { 0.2, 0.4, 0.6 }, { healthColor = "off" }
local bar = { SetStatusBarColor = function(self, ...) self.color = { ... } end }
local frame = { Health = bar }
FlareUI_UF_Target = frame
local restricted, low, offline, tapped
function UnitExists() return true end
function UnitIsPlayer() return true end
function UnitIsConnected() return not offline end
function UnitIsTapDenied() return tapped end
function UnitNameUnmodified() return id end
function canaccessallvalues() return not restricted end
TRP3_NameUtil = { GetQualifiedName = function(unit) assert(not restricted); return unit == "player" and "Me" or id end }
local ns = { ProfileColor = function(unit)
    if unit == "player" then return 0.75, 0, 1, "Me" end
    if rgb then return rgb[1], rgb[2], rgb[3], id end
end }
function CreateColor(...) return {...} end
Enum = { LuaCurveType = { Step = 1 } }
C_CurveUtil = { CreateColorCurve = function()
    return { SetType = function() end, AddPoint = function(self, at, color) self[at] = color end }
end }
function UnitHealthPercent() error("use the host evaluator") end
local uf = { FillSlots = function() end, HealthColorMode = function(d) return d.healthColor end,
    HealthBarColor = function() return 0.5, 0.5, 0.5 end,
    HealthTint = { RED = { 1, 0, 0 }, AT = 0.3, CurveRGB = function(_, curve)
        return unpack(curve[low and 0 or 0.3])
    end } }
FlareUI = { UnitFrames = uf, EditPreviewing = function() return false end, ClassColorsOn = function() return true end,
    db = { profile = { unitframes = { units = { target = db } } } } }
function hooksecurefunc(obj, method, fn) assert(obj == uf and method == "FillSlots"); tick = fn end
assert(loadfile("UnitHealth.lua"))("FlareUI_RP", ns)
ns.StartUnitHealth()
ns.healthEnabled.target = true
ns.ReadHealthColor("target")
local function check(expected) tick(frame, "health"); assert(bar.color[1] == expected) end
check(0.2)
ns.healthEnabled.target = false
check(0.5)
bar:SetStatusBarColor(0.9); check(0.9)
ns.healthEnabled.target = true
check(0.2)
db.healthColor = "low"
check(0.2)
low = true
check(1)
db.healthColor = "health"
check(0.5)
bar:SetStatusBarColor(0.7); check(0.7) -- gradient remains owned by FlareUI
db.healthColor = "off"
check(0.2)
id = "Other"; check(0.5) -- a health tick before the target's name update
rgb = { 0, 1, 0 }; ns.ReadHealthColor("target"); check(0)
FlareUI_UF_Player = { Health = { SetStatusBarColor = bar.SetStatusBarColor } }
FlareUI.db.profile.unitframes.units.player = { healthColor = "low" }
ns.healthEnabled.player = true
ns.ReadHealthColor("player")
local function playerCheck(expected)
    tick(FlareUI_UF_Player, "health")
    assert(FlareUI_UF_Player.Health.color[1] == expected)
end
playerCheck(1); check(0)
low = false; playerCheck(0.75)
ns.healthEnabled.player = false; playerCheck(0.5); check(0)
offline = true; check(0.5)
offline = false; check(0)
tapped = true; check(0.5)
tapped = false; check(0)
restricted = true; check(0.5)
restricted = false; check(0)
rgb = nil; ns.ReadHealthColor("target"); check(0.5)
print("PASS: target profile colour, low warning, gradient and host fallback")
