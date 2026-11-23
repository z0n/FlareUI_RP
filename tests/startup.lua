-- Missing host helpers on one surface must not hide the other surface's settings.
local function run(hasNames, hasPlates)
    local ns, events, page, hooks = {}, {}, nil, {}
    FlareUI = { UnitFrames = {}, NameAbove = {} }
    local function noop() end
    if hasNames then
        FlareUI.UnitFrames.ShowsFullName, FlareUI.NameAbove.SetName, FlareUI.UnitDisplayName = noop, noop, noop
    end
    if hasPlates then FlareUI.Nameplates = { UpdateName = noop, LevelPrefix = noop } end
    TRP3_Addon = {}
    TRP3_API = { GameEvents = {}, RegisterCallback = function(_, k, f) events[k] = f end,
        configuration = { registerConfigKey = noop, getValue = function() return true end,
            registerHandler = noop, registerConfigurationPage = function(p) page = p end } }
    C_Timer = { After = noop }
    function hooksecurefunc(_, key) hooks[key] = true end
    for _, file in ipairs({ "UnitHealth.lua", "Nameplates.lua", "GroupFrames.lua", "UnitFrames.lua" }) do
        assert(loadfile(file))("FlareUI_RP", ns)
    end
    events.WORKFLOW_ON_LOADED()
    assert(page and page.id == "main_config_flareui_rp")
    assert(not not hooks.SetName == hasNames and not not hooks.UpdateName == hasPlates)
    local section, controls = nil, {}
    for _, element in ipairs(page.elements) do
        if element.inherit == "TRP3_ConfigH1" then section = element.title
        elseif element.configKey then controls[element.configKey] = assert(section) end
    end
    assert(controls.flareui_rp_unit_names == (hasNames and "Unit Frames" or nil))
    assert(controls.flareui_rp_plate_names == (hasPlates and "Floating Nameplates" or nil))
    assert(not controls.flareui_rp_player_health, "unsupported health controls must stay hidden")
end
run(false, true)
run(true, false)
run(true, true)
print("PASS: independent adapter startup and settings when host helpers are unavailable")
