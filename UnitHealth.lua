local _, ns = ...
ns.directFrames = {
    player = "FlareUI_UF_Player", pet = "FlareUI_UF_Pet", target = "FlareUI_UF_Target", focus = "FlareUI_UF_Focus",
    targettarget = "FlareUI_UF_TargetOfTarget", focustarget = "FlareUI_UF_TargetOfFocus",
}
local states = {}
for unit in pairs(ns.directFrames) do states[unit] = {} end
ns.healthEnabled = {}

-- Only the host's live direct frames, never its samples or group tiles.
function ns.DirectUnit(frame)
    if not frame or (frame.IsForbidden and frame:IsForbidden()) then return end
    local unit = frame.fuiUnit
    if canaccessvalue(unit) and unit and ns.directFrames[unit] and frame == _G[ns.directFrames[unit]] then return unit end
end

function ns.DirectExists(unit)
    local exists = UnitExists(unit)
    return canaccessvalue(exists) and exists
end

-- Called on target/name/profile changes, not on every health tick.
function ns.ReadHealthColor(unit, state)
    local s = state or states[unit]
    local profile, nextID = ns.Profile(unit)
    local nr, ng, nb = ns.ProfileColor(profile)
    if nr ~= s.r or ng ~= s.g or nb ~= s.b then s.curve = nil end
    s.r, s.g, s.b, s.id = nr, ng, nb, nextID
    return profile
end

local function LowColor(tint, unit, s)
    if not s.curve then
        -- Keep one curve, rather than adding arbitrary profile RGBs to the
        -- host's permanent class-palette cache. Blizzard evaluates secret HP.
        local curve = C_CurveUtil.CreateColorCurve()
        curve:SetType(Enum.LuaCurveType.Step)
        curve:AddPoint(0, CreateColor(tint.RED[1], tint.RED[2], tint.RED[3], 1))
        curve:AddPoint(tint.AT, CreateColor(s.r, s.g, s.b, 1))
        s.curve = curve
    end
    return tint.CurveRGB(unit, s.curve)
end

function ns.PaintHealth(frame, unit)
    local s = states[unit]
    if not ns.healthEnabled[unit] and not s.applied then return end
    if not frame or (frame.IsForbidden and frame:IsForbidden()) or not frame.Health or not ns.DirectExists(unit) then return end
    local profile = FlareUI.db and FlareUI.db.profile
    local units = profile and profile.unitframes and profile.unitframes.units
    local db = units and units[unit]
    ns.ApplyHealth(frame, unit, db, s, ns.healthEnabled[unit])
end

-- Group tiles use the same palette and tints, but have their own settings and
-- colour state (a secure raid header can reassign its tile to another unit).
function ns.ApplyHealth(frame, unit, db, s, enabled)
    if not db or FlareUI.EditPreviewing() or (not s.applied and not (enabled and s.r)) then return end
    local uf = FlareUI.UnitFrames
    -- FlareUI's restore helper branches on these same flags. If restricted,
    -- leave the widget alone and keep s.applied for the next safe repaint.
    local player, connected, tapped = UnitIsPlayer(unit), UnitIsConnected(unit), UnitIsTapDenied(unit)
    if not canaccessallvalues(player, connected, tapped) then return end
    local mode = uf.HealthColorMode(db)
    if enabled and s.r and FlareUI.ClassColorsOn(db) and mode ~= "health" then
        if player and connected and not tapped
            and canaccessallvalues(UnitNameUnmodified(unit)) and TRP3_NameUtil.GetQualifiedName(unit) == s.id then
            if mode == "off" then
                frame.Health:SetStatusBarColor(s.r, s.g, s.b)
                s.applied = true
                return
            elseif mode == "low" and uf.HealthTint and C_CurveUtil and UnitHealthPercent then
                local ok, cr, cg, cb = pcall(LowColor, uf.HealthTint, unit, s)
                if ok then
                    frame.Health:SetStatusBarColor(cr, cg, cb)
                    s.applied = true
                    return
                end
            end
        end
    end
    if s.applied then
        frame.Health:SetStatusBarColor(uf.HealthBarColor(unit, FlareUI.ClassColorsOn(db), db))
        s.applied = nil
    end
end

function ns.StartUnitHealth()
    local uf = FlareUI.UnitFrames
    if not (uf.FillSlots and uf.HealthColorMode and uf.HealthBarColor and FlareUI.ClassColorsOn and FlareUI.EditPreviewing) then return end
    -- UpdateHealth finishes by filling the health text slots, after choosing
    -- its bar colour. Do not hook the bar setter or run a polling timer.
    hooksecurefunc(uf, "FillSlots", function(frame, bar)
        if bar ~= "health" then return end
        local unit = ns.DirectUnit(frame)
        if unit then ns.PaintHealth(frame, unit) end
    end)
    ns.unitHealthActive = true
end
