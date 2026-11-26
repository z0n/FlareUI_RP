-- Exercise the settings page lifecycle with the same registered rows TRP3 uses.
local ns = { directFrames = { target = "FlareUI_UF_Target", pet = "FlareUI_UF_Pet" } }
local values, combat, opened, hidden = {}, false
local target = { classColor = false, healthColor = "health" }
local party = { style = "raid", raid = { classColor = true }, classic = { classColor = false } }
local plates = { friendlyPlayer = { plate = "name", healthColor = "reaction" },
    enemyPlayer = { plate = "full", healthColor = "health", nameClassColor = true } }
local combatTypes = {}
local pet = { classColor = false }
local profile = { unitframes = { units = { target = target, pet = pet }, party = party }, nameplates = {} }
FlareUI_UF_Target, FlareUI_UF_Pet, FlareUI_Party = {}, {}, {}
FlareUI = { db = { profile = profile }, ClassColorsOn = function(db) return db.classColor ~= false end,
    UnitFrames = { HealthColorMode = function(db) return db.healthColor end },
    BarText = { NameOf = function(fields) return fields.firstname end },
    Nameplates = { TypeDB = function(kind) return plates[kind] end,
        CombatList = function(preview) return preview and combatTypes or {} end,
        TextSlots = function(db) return db.slots or { left = { firstname = 1 } } end,
        NameAbovePick = function(db) return db.nameAbove end },
    Settings = { CanEditFrames = function() return not combat end,
        EditFrame = function(_, frame, module) opened = { frame, module }; return true end },
    SettingsPanel = { Open = function(_, key, tab) opened = { key, tab } end } }
TRP3_MainFrame = { Hide = function() hidden = true end }
TRP3_API = { configuration = { getValue = function(key) return values[key] end } }
local function checkbox(key)
    key = "flareui_rp_" .. key
    values[key] = true
    return { configKey = key }
end
local t, g, n = checkbox("target_health"), checkbox("party_health"), checkbox("plate_colours")
local gl, gc = checkbox("plate_guilds"), checkbox("plate_guild_colours")
local titles = checkbox("plate_titles")
titles.inherit = "TRP3_ConfigDropDown"
local onTitleChange
TRP3_API.configuration.registerHandler = function(key, fn) assert(key == titles.configKey); onTitleChange = fn end
values[titles.configKey], values[gl.configKey], values[gc.configKey] = "none", false, false
local petOption = checkbox("pet_health")
local elements = { t, g, n, gl, gc, titles, petOption }
assert(loadfile("SetupHints.lua"))("FlareUI_RP", ns)
local watchHints = ns.AddSetupHints(elements)
local function noop() end
local function widget()
    return { ClearAllPoints = noop, SetPoint = noop, SetWordWrap = noop, SetWidth = noop,
        SetText = function(self, text) self.text = text end, SetHeight = function(self, h) self.height = h end,
        SetEnabled = function(self, enable) self.enabled = enable end,
        Show = function(self) self.shown = true end, Hide = function(self) self.shown = false end,
        IsVisible = function() return true end, GetStringHeight = function() return 20 end,
        GetTextWidth = function() return 60 end, RegisterEvent = noop,
        SetScript = function(self, key, fn) self[key] = fn end, HookScript = function(self, key, fn) self[key] = fn end }
end
local hints = {}
for i, row in ipairs(elements) do
    if row.elementInitializer then
        local w = widget()
        w.Title, w.Button, row.widget = widget(), widget(), w
        row.elementInitializer(w)
        local option = elements[i-1]
        if option and option.configKey then hints[option] = row end
    end
end
local row, w = hints[t], hints[t].widget
local note, body, close
FlareUI.WINDOW_STYLE = { border = { 1, 1, 1 }, top = { 1, 1, 1, 1 }, bottom = { 0, 0, 0, 1 } }
CreateColor = noop
EditModeManagerFrame, FlareUI_SettingsPanel = widget(), widget()
function CreateFrame(kind)
    local f = widget()
    if kind == "Button" then close = f; return f end
    assert(not note, "reuse the pinned note")
    note = f
    for _, key in ipairs({ "SetFrameStrata", "SetClampedToScreen", "SetBackdrop", "SetBackdropBorderColor",
        "SetMovable", "EnableMouse", "RegisterForDrag", "StartMoving", "StopMovingOrSizing" }) do f[key] = noop end
    f.CreateTexture = function() return { SetPoint = noop, SetColorTexture = noop, SetGradient = noop } end
    f.CreateFontString = function()
        body = widget()
        body.SetJustifyH, body.SetSpacing = noop, noop
        body.SetWidth = function(self, width) self.wrapWidth = width end
        body.GetStringHeight = function(self)
            assert(self.wrapWidth and f.shown, "measure visible text at its actual wrap width")
            return math.ceil(#self.text * 9 / self.wrapWidth) * 18
        end
        return body
    end
    return f
end
local page, tick = widget(), nil
C_Timer = { NewTicker = function(_, fn)
    assert(not tick)
    tick = fn
    return { Cancel = function() tick = nil end }
end }
watchHints(page)
assert(w.Title.text:find("Class Colours") and w.Title.text:find("Tint Health"))
assert(not w.Title.text:find("warning") and w.Button.shown and w.Button.text == "Edit Target Frame")
combat = true; w.OnEvent()
row.OnClick()
assert(not w.Button.enabled and not opened and not hidden and not note)
combat = false; w.OnEvent(); row.OnClick()
assert(opened[1] == FlareUI_UF_Target and opened[2] == "uf" and note.shown)
EditModeManagerFrame:OnHide(); assert(not note.shown)
assert(not hints[petOption].widget.Button.shown, "the Pet frame has no Class Colours setting")
pet.healthColor = "health"
hints[petOption].widget.OnShow()
assert(hints[petOption].widget.Title.text:find("Tint Health") and not hints[petOption].widget.Title.text:find("Class Colours"))
hints[petOption].OnClick(); assert(opened[1] == FlareUI_UF_Pet and opened[2] == "uf")
pet.enabled = false
hints[petOption].OnClick(); assert(opened[1] == "uf" and opened[2] == "settings")
target.classColor, target.healthColor = true, "low"
tick()
assert(not w.Button.shown and w.height == 1)
target.classColor = false
tick()
assert(w.Title.shown and w.Title.text:find("Class Colours") and w.Button.shown)
page.OnHide()
assert(not tick)
page.OnShow()
assert(tick)
-- The parent was hidden without the usual page hide callback.
page.IsVisible = function() return false end
target.classColor = true
tick()
assert(not tick and w.Title.shown, "hidden page must cancel before refreshing hints")
assert(not hints[g].widget.Button.shown)
party.style = "classic"
hints[g].widget.OnShow()
assert(hints[g].widget.Button.shown and hints[g].widget.Button.text == "Edit Party Frame")
values[g.configKey] = false
g.OnClick()
assert(not hints[g].widget.Title.shown)
local plate = hints[n]
assert(plate.widget.Title.text:find("Enemy Player") and not plate.widget.Title.text:find("Friendly Player"))
assert(not plate.widget.Title.text:find("warning") and plate.widget.Button.text == "Open Nameplate Settings")
plate.OnClick(); assert(opened[1] == "np" and opened[2] == "style" and note.shown)
FlareUI_SettingsPanel:OnHide(); assert(not note.shown)
plates.enemyPlayer.healthColor = "class"
plate.widget.OnShow()
assert(not plate.widget.Button.shown)
plates.friendlyPlayer.nameOnlyTarget = true
plate.widget.OnShow()
assert(plate.widget.Button.shown and plate.widget.Title.text:find("Friendly Player") and plate.widget.Title.text:find("Class & Reaction"))
plates.friendlyPlayer.nameOnlyTarget = false
plate.widget.OnShow()
assert(not plate.widget.Button.shown)
plates.minor = { plate = "name", healthColor = "class" }
combatTypes.minor = true
plate.widget.OnShow()
assert(plate.widget.Title.text:find("Minor") and plate.widget.Title.text:find("Style > Bar Text > Colour Names by Class"))
plate.OnClick(); assert(opened[1] == "np" and opened[2] == "style")
plates.minor.slots = { middle = { percent = 1 } }
plate.widget.OnShow(); assert(not plate.widget.Button.shown, "a health-only layout has no name to colour")
plates.minor.nameAbove = "left:firstname"
plate.widget.OnShow(); assert(plate.widget.Button.shown and plate.widget.Title.text:find("Colour Names by Class"))
plates.minor.nameClassColor = true
plate.widget.OnShow(); assert(not plate.widget.Button.shown)
plates.minor.healthColor = "reaction"
plate.widget.OnShow(); assert(plate.widget.Button.shown and plate.widget.Title.text:find("Minor"))
combatTypes.minor = nil
plate.widget.OnShow(); assert(not plate.widget.Button.shown)
local labelHint, colourHint = hints[gl].widget, hints[gc].widget
assert(not labelHint.Title.shown and not colourHint.Title.shown)
values[gl.configKey], values[gc.configKey] = true, true
gl.OnClick(); gc.OnClick()
hints[gl].OnClick()
assert(opened[1] == "np" and opened[2] == "style" and hidden and body.text:find("Show Guild Name"))
local taller = note.height + 40
body.GetStringHeight = function() return taller end
note:OnDragStop()
assert(note.height > taller, "after dragging, the frame must contain the wrapped body plus padding")
FlareUI_SettingsPanel:OnHide(); assert(not note.shown)
hints[gl].OnClick(); close:OnClick(); assert(not note.shown)
local titleHint = hints[titles].widget
assert(not titleHint.Title.shown)
values[titles.configKey] = "short"; onTitleChange()
assert(titleHint.Title.shown and titleHint.Title.text:find("Show Titles"))
plates.friendlyPlayer.showTitles = true; titleHint.OnShow(); assert(not titleHint.Title.shown)
assert(labelHint.Title.text:find("Show Guild Name") and colourHint.Title.text:find("Colour Guild Members"))
plates.enemyPlayer.plate, plates.enemyPlayer.showGuild = "name", true
labelHint.OnShow(); assert(not labelHint.Button.shown and colourHint.Button.shown)
plates.friendlyPlayer.guildColor = true
colourHint.OnShow(); assert(not colourHint.Button.shown)
local held, picks, enemies = nil, "010", false
FlareUI.Nameplates.FriendlyHeld = function() return held end
FlareUI.Nameplates.FriendlyPicks = function() return picks end
local enemyMinions = false
function GetCVarBool(key)
    if key == "nameplateShowEnemyMinions" then return enemyMinions end
    assert(key == "nameplateShowEnemies"); return enemies
end
plates.minor = { plate = "name", showTitles = true }
titleHint.OnShow(); assert(titleHint.Title.shown and titleHint.Title.text:find("Players under Friendly Types"))
plates.friendlyPlayer.showTitles = false
titleHint.OnShow(); assert(titleHint.Title.shown and titleHint.Title.text:find("Minions under Friendly Types"))
held = "001"
titleHint.OnShow(); assert(not titleHint.Title.shown)
held, enemyMinions = nil, true
titleHint.OnShow(); assert(titleHint.Title.shown, "enemy minions need enemy plates")
profile.nameplates.enemyInCombat = true
titleHint.OnShow(); assert(not titleHint.Title.shown)
profile.nameplates.enemyInCombat = false
plates.friendlyPlayer.showGuild = true
labelHint.OnShow(); colourHint.OnShow()
assert(labelHint.Title.shown and colourHint.Title.shown and colourHint.Title.text:find("Friendly Types"))
hints[gc].OnClick(); assert(opened[1] == "np" and opened[2] == "visibility")
picks, held = "000", "100"
labelHint.OnShow(); colourHint.OnShow()
assert(not labelHint.Button.shown and not colourHint.Button.shown)
held = "010"
profile.nameplates.enemyInCombat = true
labelHint.OnShow(); colourHint.OnShow()
assert(not labelHint.Button.shown and colourHint.Button.shown)
profile.nameplates.enemyPlayers = false
plates.friendlyPlayer.showGuild = false
labelHint.OnShow(); assert(labelHint.Title.shown and labelHint.Title.text:find("Enemy Types"))
profile.nameplates.enemyInCombat, profile.nameplates.enemyPlayers = false, true
labelHint.OnShow(); assert(labelHint.Title.shown and labelHint.Title.text:find("Show Enemy Plates"))
enemies = true
labelHint.OnShow(); assert(not labelHint.Button.shown)
plates.friendlyPlayer.plate = "bar"
colourHint.OnShow(); assert(colourHint.Button.shown)
values[gc.configKey] = false; gc.OnClick(); assert(not colourHint.Button.shown)
profile.nameplates.enabled = false
local module = elements[2]
module.widget.OnShow()
assert(module.widget.Title.shown and not elements[1].widget.Title.shown)
FlareUI.SettingsPanel = nil
module.widget.OnShow()
assert(not module.widget.Button.enabled)
print("PASS: inline colour help, opt-in setup hints, targeted shortcuts and rechecks")
