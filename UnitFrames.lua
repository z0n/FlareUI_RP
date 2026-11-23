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
    if not frame or not frame.Name then return end
    local unit
    if frame == _G.FlareUI_UF_Player then unit = "player"
    elseif frame == _G.FlareUI_UF_Target then unit = "target"
    else return end
    if not UnitExists(unit) then return end
    if ns.unitHealthActive and ns.healthEnabled[unit] then
        ns.ReadHealthColor(unit)
        ns.PaintHealth(frame, unit)
    end
    if not ns.namesEnabled and not restoreNames then return end
    local full = FlareUI.UnitFrames.ShowsFullName(frame)
    local rp = ns.namesEnabled and ns.Profile(unit)
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
    local aboveFull = kind == "fullname"
    if aboveFull ~= full then name = DisplayName(unit, aboveFull, rp) end
    above:SetText(name)
end

local queued
local function Refresh()
    if queued or not (ns.namesEnabled or ns.healthEnabled.target or ns.healthEnabled.player) then return end
    queued = true
    C_Timer.After(0, function()
        queued = nil
        Paint(_G.FlareUI_UF_Player)
        Paint(_G.FlareUI_UF_Target)
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
        Paint(_G.FlareUI_UF_Player, nil, not on)
        Paint(_G.FlareUI_UF_Target, nil, not on)
    end)
    local function HealthSetting(key, unit, frameName)
        config.registerConfigKey(key, true)
        ns.healthEnabled[unit] = config.getValue(key)
        config.registerHandler(key, function(_, on)
            ns.healthEnabled[unit] = on
            if not ns.unitHealthActive then return end
            if on then ns.ReadHealthColor(unit) end
            ns.PaintHealth(_G[frameName], unit)
        end)
    end
    local playerKey = "flareui_rp_player_health"
    elements[#elements + 1] = { inherit = "TRP3_ConfigH1", title = "Player & Target" }
    elements[#elements + 1] = { inherit = "TRP3_ConfigCheck", configKey = namesKey, title = "Show RP Names",
        help = "Use profile names on your frame and your target's frame." }
    if ns.unitHealthActive then
        HealthSetting(playerKey, "player", "FlareUI_UF_Player")
        HealthSetting(healthKey, "target", "FlareUI_UF_Target")
        elements[#elements + 1] = { inherit = "TRP3_ConfigCheck", configKey = playerKey, title = "Colour My Health Bar",
            help = "Use your profile colour on your own health bar. Low-health warnings and health gradients keep priority." }
        elements[#elements + 1] = { inherit = "TRP3_ConfigCheck", configKey = healthKey, title = "Colour My Target's Health Bar",
            help = "Use the targeted player's profile colour. NPC health bars keep their normal colours." }
    end
    for _, event in ipairs({ "REGISTER_DATA_UPDATED", "REGISTER_PROFILES_LOADED", "REGISTER_PROFILE_DELETED" }) do
        TRP3_API.RegisterCallback(TRP3_Addon, event, Refresh)
    end
    TRP3_API.RegisterCallback(TRP3_API.GameEvents, "PLAYER_REGEN_ENABLED", function()
        -- A switch turned off in combat can still have a pending restore.
        if ns.unitHealthActive then
            if not ns.healthEnabled.player then ns.PaintHealth(_G.FlareUI_UF_Player, "player") end
            if not ns.healthEnabled.target then ns.PaintHealth(_G.FlareUI_UF_Target, "target") end
        end
        Refresh()
    end)
    Refresh()
end

TRP3_API.RegisterCallback(TRP3_Addon, "WORKFLOW_ON_LOADED", function()
    local config = TRP3_API.configuration
    local elements = { { inherit = "TRP3_ConfigParagraph",
        title = "Enable Unit Frames or Nameplates in FlareUI first. RP names follow your First Name or Full Name setting. If a profile has no name or colour to use, FlareUI keeps its usual one.|n|nFor RP health bars, open Edit Mode, select the frame, and turn on Look > Class Colours. Names work even when Class Colours is off." } }
    StartUnitFrames(config, elements)
    ns.StartGroupFrames(config, elements)
    ns.StartNameplates(config, elements)
    -- TRP3 orders settings by menu ID, not by the displayed (localized) label.
    config.registerConfigurationPage({ id = "main_config_flareui_rp", menuText = "FlareUI RP", pageText = "FlareUI RP", elements = elements })
end)
