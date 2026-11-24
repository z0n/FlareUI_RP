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
    if not db or not (p.nameOnly or db.nameClassColor) then return false end
    local member
    if IsInRaid() then
        local raid = db.raidColor
        if raid == nil then raid = db.groupColor end
        if raid then member = UnitInRaid(p.unit) end
    elseif db.groupColor then
        member = UnitInParty(p.unit)
    end
    if not canaccessvalue(member) or member then return false end
    if p.nameOnly and db.guildColor and p.kind == "friendlyPlayer" and UnitIsInMyGuild then
        local guild = UnitIsInMyGuild(p.unit)
        if not canaccessvalue(guild) or guild then return false end
    end
    local _, class = UnitClass(p.unit)
    return canaccessvalue(class) and class and C_ClassColor.GetClassColor(class)
end

local function SetName(label, name, prefix)
    if not name then return end
    if prefix then label:SetFormattedText("%s%s", prefix, name) else label:SetText(name) end
end

local function Paint(p)
    if not Live(p) then return end
    seen[p] = true
    if not (names or colours) then return end
    local above = p.aboveKind and p.aboveName and p.aboveName:IsShown()
    if not (above or p.nameSlot) then return end
    local textColour = colours and ClassName(p)
    if not (names or textColour) then return end
    local profile = ns.Profile(p.unit)
    if not profile then return end
    if names then
        local prefix = p.levelFollow and np.LevelPrefix(p.unit)
        if p.nameSlot then SetName(p.name, ns.ProfileName(profile, p.nameFull), prefix) end
        if above then SetName(p.aboveName, ns.ProfileName(profile, ns.NameFormat(p.aboveKind)), prefix) end
    end
    local color = textColour and profile:GetCustomColorForDisplay()
    if color then
        local r, g, b = color:GetRGB()
        if above then p.aboveName:SetTextColor(r, g, b) end
        if p.nameSlot then
            -- FlareUI saves the unlifted class colour only when it lightens
            -- the in-bar label. Follow that decision on this paint.
            local lift = p.aboveColor and np.C and np.C.NAME_LIFT
            if lift then
                if canaccessallvalues(r, g, b) then
                    r, g, b = r + (1 - r) * lift, g + (1 - g) * lift, b + (1 - b) * lift
                else
                    r, g, b = 1, 1, 1
                end
            end
            p.name:SetTextColor(r, g, b)
        end
    end
end

local function PaintBar(p)
    if not Live(p) then return end
    seen[p] = true
    if not colours or p.nameOnly or not p.tdb or p.tdb.healthColor ~= "class" or p.threatRGB then return end
    if not ReadableBar(p) then return end
    local tapped, connected = UnitIsTapDenied(p.unit), UnitIsConnected(p.unit)
    if not canaccessallvalues(tapped, connected) or tapped or not connected then return end
    if p.tdb.colorFocus and p.gamePlate == C_NamePlate.GetNamePlateForUnit("focus") then return end
    local r, g, b = ns.ProfileColor(ns.Profile(p.unit))
    if r then np.BarColor(p, r, g, b) end
end

local function NeedsRefresh(p, unit, ids)
    if not ids or deferred[p] then return true end
    -- Resolve at flush time: a plate may have changed units since the event.
    -- With no readable identity, let FlareUI restore its current display.
    local id = ns.CharacterID(unit)
    return not id or ids[id]
end

local function Refresh(refreshBars, ids)
    for p in pairs(seen) do
        local unit = Live(p)
        if not unit then
            seen[p] = nil
            deferred[p] = nil
        elseif NeedsRefresh(p, unit, ids) then
            np.UpdateName(p)
            if (refreshBars or deferred[p]) and np.UpdateColor and np.BarColor then
                if ReadableBar(p) then
                    deferred[p] = nil
                    np.UpdateColor(p)
                else
                    deferred[p] = true
                end
            end
        end
    end
end

local queued
local function Queue(id)
    if not (names or colours or next(deferred)) then return end
    local scheduled = queued ~= nil
    if not id then queued = true
    elseif queued ~= true then
        queued = queued or {}
        queued[id] = true
    end
    if scheduled then return end
    C_Timer.After(0, function()
        local batch = queued
        queued = nil
        if names or colours or next(deferred) then Refresh(colours, batch ~= true and batch or nil) end
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
    elements[#elements + 1] = { inherit = "TRP3_ConfigH1", title = "Floating Nameplates" }
    elements[#elements + 1] = { inherit = "TRP3_ConfigParagraph",
        title = "These are the names and bars above players in the world. To colour their bars, choose a player plate in FlareUI > Nameplates, then Style > Look > Colour By > Class & Reaction." }
    elements[#elements + 1] = { inherit = "TRP3_ConfigCheck", configKey = nameKey, title = "Show RP Names",
        help = "Show the RP name on or above the plate. FlareUI controls its position and name format." }
    elements[#elements + 1] = { inherit = "TRP3_ConfigCheck", configKey = colourKey, title = "Use RP Colours",
        help = "Use RP colours instead of class colours on health bars and names. For names on full plates, enable FlareUI's Colour Names by Class. Party, raid and guild name colours keep priority." }
    hooksecurefunc(np, "UpdateName", Paint)
    if np.UpdateColor and np.BarColor then hooksecurefunc(np, "UpdateColor", PaintBar) end
    TRP3_API.RegisterCallback(TRP3_Addon, "REGISTER_DATA_UPDATED", function(_, id)
        if canaccessvalue(id) and type(id) == "string" and id ~= "" then Queue(id) else Queue() end
    end)
    local function QueueAll() Queue() end
    for _, event in ipairs({ "REGISTER_PROFILES_LOADED", "REGISTER_PROFILE_DELETED" }) do
        TRP3_API.RegisterCallback(TRP3_Addon, event, QueueAll)
    end
    TRP3_API.RegisterCallback(TRP3_Addon, "CONFIGURATION_CHANGED", function(_, key)
        if colours and key == "color_contrast_level" then Queue() end
    end)
    TRP3_API.RegisterCallback(TRP3_API.GameEvents, "PLAYER_REGEN_ENABLED", QueueAll)
end
