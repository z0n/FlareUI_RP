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
            registerHandler = noop, registerConfigurationPage = function(p)
                page = p
                p.frame = { HookScript = noop, IsVisible = function() return false end }
                for _, row in ipairs(p.elements) do
                    row.widget = { Title = { SetPoint = noop,
                        EnableMouse = function(t, on) t.mouseEnabled = on end }, SetHighlightTexture = noop,
                        CreateTexture = function(w)
                            w.arrow = { SetTexture = noop, SetSize = noop, SetPoint = noop, SetVertexColor = noop,
                                SetRotation = function(a, angle) a.angle = angle end }
                            return w.arrow
                        end,
                        SetScript = function(w, event, fn) w[event] = fn end,
                        SetShown = function(w, on) w.shown = on end,
                        SetPoint = function(w, _, anchor) w.anchor = anchor end }
                    if row.frameType == "Button" then row.elementInitializer(row.widget) end
                end
            end } }
    C_Timer = { After = noop }
    function hooksecurefunc(_, key) hooks[key] = true end
    for _, file in ipairs({ "UnitHealth.lua", "Nameplates.lua", "GroupFrames.lua", "SetupHints.lua", "Toolbar.lua", "MainWindow.lua", "UnitFrames.lua" }) do
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
    assert(controls.flareui_rp_unit_names == (hasNames and "Player, Target & Focus" or nil))
    assert(controls.flareui_rp_plate_names == (hasPlates and "Player Nameplates" or nil))
    assert(not controls.flareui_rp_player_health, "unsupported health controls must stay hidden")
    local widgets = {}
    for _, row in ipairs(page.elements) do
        if row.frameType == "Button" or row.configKey then widgets[row.configKey or row.title] = row.widget end
        if row.configKey then assert(row.widget.shown == false, "all sections start collapsed") end
    end
    if hasPlates then
        if hasNames then
            local plates = widgets["Player Nameplates"]
            assert(plates.Title.mouseEnabled == false, "heading text must pass input to the row")
            assert(plates.arrow.angle == math.pi / 2)
            plates.OnClick()
            assert(plates.arrow.angle == 0)
            assert(not widgets.flareui_rp_unit_names.shown)
            widgets["Player, Target & Focus"].OnClick()
            assert(widgets.flareui_rp_plate_names.shown and widgets.flareui_rp_unit_names.shown)
            widgets["Player, Target & Focus"].OnClick()
            assert(not widgets.flareui_rp_unit_names.shown and widgets.flareui_rp_plate_names.shown)
            assert(plates.anchor == widgets["Player, Target & Focus"])
        end
    end
end
run(false, true)
run(true, false)
run(true, true)
print("PASS: independent adapter startup and settings when host helpers are unavailable")
