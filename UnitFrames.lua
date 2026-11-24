local _, ns = ...

local function DisplayName(unit, full, profile)
    local name = ns.ProfileName(profile, full)
    if name then return name end
    -- Pass the host's fallback through without comparing secret name strings.
    return FlareUI.UnitDisplayName(unit, nil, full)
end

local function Paint(frame, restoreNames)
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
    local profile = FlareUI.db and FlareUI.db.profile
    local units = profile and profile.unitframes and profile.unitframes.units
    local settings = units and units[unit]
    local slot, kind = FlareUI.NameAbove.Get(settings)
    if not slot then return end
    local aboveFull = ns.NameFormat(kind)
    if aboveFull ~= full then name = DisplayName(unit, aboveFull, rp) end
    local levels = settings.showLevel and not (FlareUI.UFRing and FlareUI.UFRing.Applies(frame)) and settings
    ns.SetAboveName(above, name, unit, levels, true)
end

local queued
local function PaintAll(restoreNames)
    for _, frameName in pairs(ns.directFrames) do Paint(_G[frameName], restoreNames) end
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
    if not (FlareUI.NameAbove and FlareUI.UnitFrames and FlareUI.UnitFrames.SetNameAbove
        and FlareUI.UnitFrames.ShowsFullName and FlareUI.UnitDisplayName) then return end
    -- UpdateName calls this even when the optional above-frame label doesn't exist.
    hooksecurefunc(FlareUI.UnitFrames, "SetNameAbove", function(frame, sample)
        if not sample then Paint(frame) end
    end)
    ns.StartUnitHealth()
    local namesKey = "flareui_rp_unit_names"
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
    elements[#elements + 1] = { inherit = "TRP3_ConfigCheck", configKey = namesKey, title = "Use RP Names",
        help = "Use RP names on Player, Target, Focus, Target of Target and Target of Focus. FlareUI still controls which names appear and their format." }
    if ns.unitHealthActive then
        elements[#elements + 1] = { inherit = "TRP3_ConfigH1", title = "RP Health Bar Colours" }
        local labels = { player = "Player", target = "Target", focus = "Focus", targettarget = "Target of Target", focustarget = "Target of Focus" }
        for _, unit in ipairs({ "player", "target", "focus", "targettarget", "focustarget" }) do
            local key = "flareui_rp_" .. unit .. "_health"
            HealthSetting(key, unit)
            elements[#elements + 1] = { inherit = "TRP3_ConfigCheck", configKey = key, title = labels[unit],
                help = "On the " .. labels[unit] .. " frame, use the player's profile colour when the health bar would show their class colour. Low-health warnings and gradients keep priority." }
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

-- TRP3 builds the controls once. Only the section headings need a new top
-- anchor when a section closes; controls retain their native row spacing.
local function SettingsSections(config, elements)
    local sections = {}
    local function Layout()
        local previous, section
        for _, row in ipairs(elements) do
            local widget = row.widget
            if sections[row] then
                section = sections[row]
                widget:SetPoint("TOP", previous, "BOTTOM")
                section.chevron:SetRotation(section.open and 0 or math.pi / 2)
                previous = widget
            elseif section then
                widget:SetShown(section.open)
                if section.open then previous = widget end
            else
                previous = widget
            end
        end
    end
    local function Add(title, start)
        local rows = {}
        start(config, rows)
        if #rows == 0 then return end
        local section = { open = false }
        local header = { inherit = "TRP3_ConfigH1", frameType = "Button", title = title }
        header.elementData = true
        header.elementInitializer = function(button)
            if not section.chevron then
                local arrow = button:CreateTexture(nil, "OVERLAY")
                arrow:SetTexture("Interface\\AddOns\\FlareUI\\Media\\Panel\\Chevron.tga")
                arrow:SetSize(14, 14)
                arrow:SetPoint("LEFT", button, "LEFT")
                arrow:SetVertexColor(1, 0.82, 0)
                button.Title:SetPoint("LEFT", arrow, "RIGHT", 5, 0)
                section.chevron = arrow
            end
            -- ConfigH1's title handles mouse events for its truncation tooltip.
            -- Let the full-width button receive clicks and hover over the text too.
            button.Title:EnableMouse(false)
            button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
            button:SetScript("OnClick", function()
                section.open = not section.open
                Layout()
            end)
        end
        sections[header] = section
        elements[#elements + 1] = header
        for _, row in ipairs(rows) do
            -- Start the content beneath the title, past the 14-unit chevron and its gap.
            row.marginLeft = 5 + 14 + 5
            elements[#elements + 1] = row
        end
    end
    Add("Player, Target & Focus", StartUnitFrames)
    Add("Party & Raid", ns.StartGroupFrames)
    Add("Player Nameplates", ns.StartNameplates)
    Add("TRP3 Bar Appearance", ns.StartToolbar)
    Add("TRP3 Main Window", ns.StartMainWindow)
    local watchHints = ns.AddSetupHints(elements)
    return function(frame)
        Layout()
        watchHints(frame)
    end
end

TRP3_API.RegisterCallback(TRP3_Addon, "WORKFLOW_ON_LOADED", function()
    local config = TRP3_API.configuration
    local elements = {}
    local attach = SettingsSections(config, elements)
    -- TRP3 orders settings by menu ID, not by the displayed (localized) label.
    local page = { id = "main_config_flareui_rp", menuText = "FlareUI RP", pageText = "FlareUI RP", elements = elements }
    config.registerConfigurationPage(page)
    if page.frame then attach(page.frame) end
end)
