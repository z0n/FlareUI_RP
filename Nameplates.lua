local _, ns = ...
local np, names, colours, guilds, guildColours, titles
local seen = setmetatable({}, { __mode = "k" })

-- Run after the host has restored this plate's current name and colour.
-- Track the widget, never profile data by reusable nameplate token.
local function Live(p)
    return p.gamePlate and not p.gamePlate:IsForbidden() and canaccessvalue(p.unit) and p.unit
end

-- Use the reason for FlareUI's colour, not its RGB: class and group palettes
-- can have identical values. An unset raid option inherits the party option.
local function CanRecolourName(p)
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
    return true
end

local function SetName(label, name, prefix)
    if not name then return end
    if prefix then label:SetFormattedText("%s%s", prefix, name) else label:SetText(name) end
end

local function Paint(p)
    if not Live(p) then return end
    seen[p] = true
    if not (names or colours or guildColours) then return end
    local above = p.aboveKind and p.aboveName and p.aboveName:IsShown()
    if not (above or p.nameSlot) then return end
    local checkGuild = guildColours and p.kind == "friendlyPlayer" and p.nameOnly and p.tdb and p.tdb.guildColor and UnitIsInMyGuild
    local canColour = (colours or checkGuild) and CanRecolourName(p)
    if not (names or canColour) then return end
    local profile = ns.Profile(p.unit)
    if not profile then return end
    if names then
        local prefix = p.levelFollow and np.LevelPrefix(p.unit)
        if p.nameSlot then SetName(p.name, ns.ProfileName(profile, p.nameFull), prefix) end
        if above then SetName(p.aboveName, ns.ProfileName(profile, ns.NameFormat(p.aboveKind)), prefix) end
    end
    if not canColour then return end
    if checkGuild and ns.SharesProfileGuild(profile) then
        local g = ChatTypeInfo and ChatTypeInfo.GUILD
        local r, green, b = g and g.r or 0.25, g and g.g or 1, g and g.b or 0.25
        if p.nameSlot then p.name:SetTextColor(r, green, b) end
        if above then p.aboveName:SetTextColor(r, green, b) end
        return
    end
    if not colours then return end
    local _, class = UnitClass(p.unit)
    if not (canaccessvalue(class) and class and C_ClassColor.GetClassColor(class)) then return end
    local color = profile:GetCustomColorForDisplay()
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
    -- UpdateColor has just painted this unit. Leave a restricted host colour alone.
    if not p.barKnown then return end
    local tapped, connected = UnitIsTapDenied(p.unit), UnitIsConnected(p.unit)
    if not canaccessallvalues(tapped, connected) or tapped or not connected then return end
    if p.tdb.colorFocus and p.gamePlate == C_NamePlate.GetNamePlateForUnit("focus") then return end
    local r, g, b = ns.ProfileColor(ns.Profile(p.unit))
    if r then np.BarColor(p, r, g, b) end
end

local function PaintTitle(p)
    if not Live(p) then return end
    seen[p] = true
    local label = p.npcTitle
    if not (titles and label and p.nameOnly and p.tdb and p.tdb.showTitles) then return end
    if p.kind ~= "friendlyPlayer" and p.kind ~= "enemyPlayer" then return end
    if not label:IsShown() and UnitPVPName and not canaccessvalue((UnitPVPName(p.unit))) then return end
    local title = ns.ProfileTitle(ns.Profile(p.unit))
    if not title then return end
    label:SetText(title)
    if not label:IsShown() then
        local c = FlareUI.PALETTE.bronze5
        label:SetTextColor(c[1], c[2], c[3], 1)
        label:Show()
    end
end

local function PaintGuild(p)
    if not Live(p) then return end
    seen[p] = true
    local label = p.guildName
    if not (guilds and label and p.nameOnly and p.tdb and p.tdb.showGuild) then return end
    if p.kind ~= "friendlyPlayer" and p.kind ~= "enemyPlayer" then return end
    -- Stock hides both absent and restricted guilds. Only fill the former.
    if not label:IsShown() and not canaccessvalue((GetGuildInfo(p.unit))) then return end
    local guild = ns.ProfileGuild(ns.Profile(p.unit))
    if not guild then return end
    label:SetText("<" .. guild .. ">")
    if not label:IsShown() then
        local c = FlareUI.PALETTE.bronze5
        label:SetTextColor(c[1], c[2], c[3], 1)
        label:ClearAllPoints()
        label:SetPoint("TOP", (p.npcTitle and p.npcTitle:IsShown()) and p.npcTitle or p.name, "BOTTOM", 0, -1)
        label:Show()
    end
end

local function NeedsRefresh(unit, ids)
    if not ids then return true end
    -- Resolve at flush time: a plate may have changed units since the event.
    -- With no readable identity, let FlareUI restore its current display.
    local id = ns.CharacterID(unit)
    return not id or ids[id]
end

local function Refresh(refreshBars, ids, restoreTitles)
    for p in pairs(seen) do
        local unit = Live(p)
        if not unit then
            seen[p] = nil
        elseif NeedsRefresh(unit, ids) then
            np.UpdateName(p)
            if titles or restoreTitles then np.UpdateTitle(p)
            elseif np.UpdateGuild then np.UpdateGuild(p) end
            if refreshBars and np.UpdateColor and np.BarColor then np.UpdateColor(p) end
        end
    end
end

local queued
local function Queue(id)
    if not (names or colours or guilds or guildColours or titles) then return end
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
        if names or colours or guilds or guildColours or titles then Refresh(colours, batch ~= true and batch or nil) end
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
    elements[#elements + 1] = { inherit = "TRP3_ConfigCheck", configKey = nameKey, title = "Use RP Names",
        help = "Use a player's RP name where FlareUI shows their name on or above the plate. Each label keeps its own name format." }
    elements[#elements + 1] = { inherit = "TRP3_ConfigCheck", configKey = colourKey, title = "Use RP Name and Bar Colours",
        help = "Replace player class colours with profile colours. For health bars, choose Class & Reaction in FlareUI. For names, use Name Only or enable Colour Names by Class on full plates. Party, raid and guild name colours keep priority." }
    hooksecurefunc(np, "UpdateName", Paint)
    if np.UpdateTitleLine and np.UpdateTitle then
        local key = "flareui_rp_plate_titles"
        config.registerConfigKey(key, false)
        titles = config.getValue(key)
        config.registerHandler(key, function(_, on) titles = on; Refresh(false, nil, true) end)
        elements[#elements + 1] = { inherit = "TRP3_ConfigCheck", configKey = key, title = "Use RP Titles",
            help = "Use the profile's Full title on Name Only player plates with Show Titles enabled. An empty Full title keeps FlareUI's normal title." }
        -- The host anchors the guild immediately after painting this title line.
        hooksecurefunc(np, "UpdateTitleLine", PaintTitle)
    end
    if np.UpdateGuild then
        local guildKey = "flareui_rp_plate_guilds"
        config.registerConfigKey(guildKey, false)
        guilds = config.getValue(guildKey)
        config.registerHandler(guildKey, function(_, on) guilds = on; Refresh(false) end)
        elements[#elements + 1] = { inherit = "TRP3_ConfigCheck", configKey = guildKey, title = "Use RP Guild Names",
            help = "Show the profile's Guild name on Name Only player plates when Show Guild Name is enabled in FlareUI. Without an RP guild, keep the normal guild line." }
        hooksecurefunc(np, "UpdateGuild", PaintGuild)
    end
    if np.UpdateColor and np.BarColor then hooksecurefunc(np, "UpdateColor", PaintBar) end
    local memberKey = "flareui_rp_plate_guild_colours"
    config.registerConfigKey(memberKey, false)
    guildColours = config.getValue(memberKey)
    config.registerHandler(memberKey, function(_, on) guildColours = on; Refresh(false) end)
    elements[#elements + 1] = { inherit = "TRP3_ConfigCheck", configKey = memberKey, title = "Colour RP Guild Members",
        help = "Extend FlareUI's Colour Guild Members to friendly players whose RP guild matches yours. Party and raid colours keep priority." }
    TRP3_API.RegisterCallback(TRP3_Addon, "REGISTER_DATA_UPDATED", function(_, id)
        if not canaccessvalue(id) or type(id) ~= "string" or id == "" then Queue()
        elseif guildColours and TRP3_API.globals and id == TRP3_API.globals.player_id then Queue()
        else Queue(id) end
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
