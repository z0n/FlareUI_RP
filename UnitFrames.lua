local _, ns = ...

-- Stock FlareUI calls NameAbove.SetName immediately after writing the in-frame
-- label. Hook the helper, not SetText: no recursive writes or frame layout changes.
local function DisplayName(unit, full, profile)
    local name = ns.ProfileName(profile, full)
    if name then return name end
    -- Pass the host's fallback through without comparing secret name strings.
    return FlareUI.UnitDisplayName(unit, nil, full)
end

local function Paint(frame, settings, restoreNames)
    local unit = ns.DirectUnit(frame)
    if not unit or not frame.Name or not ns.DirectExists(unit) or (FlareUI.EditPreviewing and FlareUI.EditPreviewing()) then return end
    local rp
    if ns.unitHealthActive and ns.healthEnabled[unit] then
        rp = ns.ReadHealthColor(unit)
        ns.PaintHealth(frame, unit)
    elseif ns.namesEnabled then
        rp = ns.Profile(unit)
    end
    if not ns.namesEnabled and not restoreNames then return end
    local full = FlareUI.UnitFrames.ShowsFullName(frame)
    if not ns.namesEnabled then rp = nil end
    local name = DisplayName(unit, full, rp)
    frame.Name:SetText(name)

    local above = frame.NameAboveText
    if not above or not above:IsShown() or not FlareUI.NameAbove.Get then return end
    -- The post-hook receives the layout's settings. On a TRP3-only refresh,
    -- read the current profile, even if no layout update happened since login.
    if not settings then
        local profile = FlareUI.db and FlareUI.db.profile
        local units = profile and profile.unitframes and profile.unitframes.units
        settings = units and units[unit]
    end
    local slot, kind = FlareUI.NameAbove.Get(settings)
    if not slot then return end
    local aboveFull = ns.NameFormat(kind)
    if aboveFull ~= full then name = DisplayName(unit, aboveFull, rp) end
    above:SetText(name)
end

local queued
local function PaintAll(restoreNames)
    for _, frameName in pairs(ns.directFrames) do Paint(_G[frameName], nil, restoreNames) end
end
local function Refresh()
    if queued then return end
    queued = true
    C_Timer.After(0, function()
        queued = nil
        PaintAll()
    end)
end

local function StartUnitFrames(config, elements)
    if not (FlareUI.NameAbove and FlareUI.NameAbove.SetName and FlareUI.UnitFrames
        and FlareUI.UnitFrames.ShowsFullName and FlareUI.UnitDisplayName) then return end
    hooksecurefunc(FlareUI.NameAbove, "SetName", function(frame, settings) Paint(frame, settings) end)
    ns.StartUnitHealth()
    local namesKey, healthKey = "flareui_rp_unit_names", "flareui_rp_target_health"
    -- Preserve the standalone addon's previous behaviour on first install/update.
    config.registerConfigKey(namesKey, true)
    ns.namesEnabled = config.getValue(namesKey)
    config.registerHandler(namesKey, function(_, on)
        ns.namesEnabled = on
        PaintAll(not on)
    end)
    local function HealthSetting(key, unit)
        config.registerConfigKey(key, true)
        ns.healthEnabled[unit] = config.getValue(key)
        config.registerHandler(key, function(_, on)
            ns.healthEnabled[unit] = on
            if not ns.unitHealthActive then return end
            local frame = _G[ns.directFrames[unit]]
            if ns.DirectUnit(frame) ~= unit or not ns.DirectExists(unit) then return end
            if on then ns.ReadHealthColor(unit) end
            ns.PaintHealth(frame, unit)
        end)
    end
    local playerKey = "flareui_rp_player_health"
    elements[#elements + 1] = { inherit = "TRP3_ConfigH1", title = "Unit Frames" }
    elements[#elements + 1] = { inherit = "TRP3_ConfigCheck", configKey = namesKey, title = "Show RP Names",
        help = "Use profile names on Player, Target, Focus, Target of Target and Target of Focus." }
    if ns.unitHealthActive then
        HealthSetting(playerKey, "player")
        HealthSetting(healthKey, "target")
        elements[#elements + 1] = { inherit = "TRP3_ConfigCheck", configKey = playerKey, title = "Colour My Health Bar",
            help = "Use your profile colour on your own health bar. Low-health warnings and health gradients keep priority." }
        elements[#elements + 1] = { inherit = "TRP3_ConfigCheck", configKey = healthKey, title = "Colour My Target's Health Bar",
            help = "Use the targeted player's profile colour. NPC health bars keep their normal colours." }
        local labels = { focus = "Focus", targettarget = "Target of Target", focustarget = "Target of Focus" }
        for _, unit in ipairs({ "focus", "targettarget", "focustarget" }) do
            local key = "flareui_rp_" .. unit .. "_health"
            HealthSetting(key, unit)
            elements[#elements + 1] = { inherit = "TRP3_ConfigCheck", configKey = key, title = "Colour " .. labels[unit] .. " Health Bar",
                help = "Replace this frame's class colour when the player has a profile colour." }
        end
    end
    for _, event in ipairs({ "REGISTER_DATA_UPDATED", "REGISTER_PROFILES_LOADED", "REGISTER_PROFILE_DELETED" }) do
        TRP3_API.RegisterCallback(TRP3_Addon, event, Refresh)
    end
    TRP3_API.RegisterCallback(TRP3_API.GameEvents, "PLAYER_REGEN_ENABLED", function()
        -- A switch turned off in combat can still have a pending restore.
        if ns.unitHealthActive then
            for unit, frameName in pairs(ns.directFrames) do
                if not ns.healthEnabled[unit] then ns.PaintHealth(_G[frameName], unit) end
            end
        end
        Refresh()
    end)
    Refresh()
end

TRP3_API.RegisterCallback(TRP3_Addon, "WORKFLOW_ON_LOADED", function()
    local config = TRP3_API.configuration
    local elements = { { inherit = "TRP3_ConfigParagraph",
        title = "RP names follow FlareUI's First Name, Last Name or Full Name setting. RP colours replace class colours where FlareUI uses them. If a profile has no name or colour to use, FlareUI keeps its usual one." } }
    StartUnitFrames(config, elements)
    ns.StartGroupFrames(config, elements)
    ns.StartNameplates(config, elements)
    local watchHints = ns.AddSetupHints(elements)
    -- TRP3 orders settings by menu ID, not by the displayed (localized) label.
    local page = { id = "main_config_flareui_rp", menuText = "FlareUI RP", pageText = "FlareUI RP", elements = elements }
    config.registerConfigurationPage(page)
    if page.frame then watchHints(page.frame) end
end)
