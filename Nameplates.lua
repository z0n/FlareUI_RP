local _, ns = ...
local np, names, colours
local seen = setmetatable({}, { __mode = "k" })
local deferred = setmetatable({}, { __mode = "k" })

local function ReadableBar(p)
    -- FlareUI compares its previous colour with the incoming one.
    return canaccessallvalues(p.barR, p.barG, p.barB)
end

-- Run after the host has restored this plate's current name and colour.
-- Track the widget, never profile data by reusable nameplate token.
local function Live(p)
    return p.gamePlate and not p.gamePlate:IsForbidden() and canaccessvalue(p.unit) and p.unit
end

-- Use the reason for FlareUI's colour, not its RGB: class and group palettes
-- can have identical values. An unset raid option inherits the party option.
local function ClassName(p)
    local db = p.tdb
    if not db then return false end
    local member
    if IsInRaid() then
        local raid = db.raidColor
        if raid == nil then raid = db.groupColor end
        if raid then member = UnitInRaid(p.unit) end
    elseif db.groupColor then
        member = UnitInParty(p.unit)
    end
    if not canaccessvalue(member) or member then return false end
    local _, class = UnitClass(p.unit)
    return canaccessvalue(class) and class and C_ClassColor.GetClassColor(class)
end

local function Paint(p)
    if not Live(p) then return end
    seen[p] = true
    local textColour = colours and p.nameOnly and ClassName(p)
    -- 7.0.4 can show a separate name even when no bar text slot contains one.
    local above = names and p.aboveKind and p.aboveName and p.aboveName:IsShown()
    if not above and not (p.nameSlot and (names or textColour)) then return end
    local profile = ns.Profile(p.unit)
    if not profile then return end
    if above then
        local name = ns.ProfileName(profile, p.aboveKind == "fullname")
        if name then p.aboveName:SetText(name) end
    end
    if not p.nameSlot then return end
    local name = names and ns.ProfileName(profile, p.nameFull)
    local color = textColour and profile:GetCustomColorForDisplay()
    if name then
        local prefix = p.levelFollow and np.LevelPrefix(p.unit)
        if prefix then p.name:SetFormattedText("%s%s", prefix, name) else p.name:SetText(name) end
    end
    if color then p.name:SetTextColor(color:GetRGB()) end
end

local function PaintBar(p)
    if not Live(p) then return end
    seen[p] = true
    if not colours or p.nameOnly or not p.tdb or p.tdb.healthColor ~= "class" or p.threatRGB then return end
    if not ReadableBar(p) then return end
    local tapped, connected = UnitIsTapDenied(p.unit), UnitIsConnected(p.unit)
    if not canaccessallvalues(tapped, connected) or tapped or not connected then return end
    if p.tdb.colorFocus and p.gamePlate == C_NamePlate.GetNamePlateForUnit("focus") then return end
    local r, g, b = ns.ProfileColor(p.unit)
    if r then np.BarColor(p, r, g, b) end
end

local function Refresh(refreshBars)
    for p in pairs(seen) do
        if Live(p) then
            np.UpdateName(p)
            if (refreshBars or deferred[p]) and np.UpdateColor and np.BarColor then
                if ReadableBar(p) then
                    deferred[p] = nil
                    np.UpdateColor(p)
                else
                    deferred[p] = true
                end
            end
        else
            seen[p] = nil
            deferred[p] = nil
        end
    end
end

local queued
local function Queue()
    if queued or not (names or colours or next(deferred)) then return end
    queued = true
    C_Timer.After(0, function()
        queued = nil
        if names or colours or next(deferred) then Refresh(colours) end
    end)
end

function ns.StartNameplates(config, elements)
    np = FlareUI.Nameplates
    if not (np and np.UpdateName and np.LevelPrefix) then return end
    local nameKey, colourKey = "flareui_rp_plate_names", "flareui_rp_plate_colours"
    config.registerConfigKey(nameKey, true)
    config.registerConfigKey(colourKey, true)
    names, colours = config.getValue(nameKey), config.getValue(colourKey)
    config.registerHandler(nameKey, function(_, on) names = on; Refresh(false) end)
    config.registerHandler(colourKey, function(_, on) colours = on; Refresh(true) end)
    elements[#elements + 1] = { inherit = "TRP3_ConfigCheck", configKey = nameKey, title = "RP Names on Nameplates",
        help = "Show RP names on floating player nameplates using FlareUI's name format." }
    elements[#elements + 1] = { inherit = "TRP3_ConfigCheck", configKey = colourKey, title = "RP Nameplate Colour",
        help = "Choose Class & Reaction in FlareUI to replace player bar class colours. On Name Only plates, RP colour replaces class-coloured text, not party or raid colours." }
    hooksecurefunc(np, "UpdateName", Paint)
    if np.UpdateColor and np.BarColor then hooksecurefunc(np, "UpdateColor", PaintBar) end
    for _, event in ipairs({ "REGISTER_DATA_UPDATED", "REGISTER_PROFILES_LOADED", "REGISTER_PROFILE_DELETED" }) do
        TRP3_API.RegisterCallback(TRP3_Addon, event, Queue)
    end
    TRP3_API.RegisterCallback(TRP3_Addon, "CONFIGURATION_CHANGED", function(_, key)
        if colours and key == "color_contrast_level" then Queue() end
    end)
    TRP3_API.RegisterCallback(TRP3_API.GameEvents, "PLAYER_REGEN_ENABLED", Queue)
end
