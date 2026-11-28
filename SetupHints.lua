local _, ns = ...
local labels = { player = "Player", pet = "Pet", target = "Target", focus = "Focus", targettarget = "Target of Target",
    focustarget = "Target of Focus", party = "Party", raid = "Raid" }
local groupFrames = { party = "FlareUI_Party", raid = "FlareUI_Raid" }

local function Profile()
    return FlareUI.db and FlareUI.db.profile
end

local function ModuleHint(module, label)
    local p = Profile()
    if p and p[module] and p[module].enabled == false then
        return label .. " is switched off in FlareUI. Enable it to use RP names and colours there.",
            module == "nameplates" and "np" or "uf"
    end
end

local function FrameHint(unit)
    local p = Profile()
    local uf = p and p.unitframes
    if not uf or uf.enabled == false then return end
    local db = groupFrames[unit] and uf[unit] or (uf.units and uf.units[unit])
    if not db then return end
    local label = labels[unit]
    if db.enabled == false then return label .. " frames are switched off in FlareUI.", "uf", "settings" end
    if unit == "party" then db = db[db.style == "raid" and "raid" or "classic"] end
    if unit == "raid" then
        -- The same effective settings that raid tiles read, including size overrides.
        local ctx = FlareUI.RaidFrames and FlareUI.RaidFrames.PreviewCtx
        db = ctx and ctx.TextDb and ctx.TextDb()
    end
    if not db then return end
    local classOff = unit ~= "pet" and not FlareUI.ClassColorsOn(db)
    local gradient = FlareUI.UnitFrames.HealthColorMode(db) == "health"
    if not (classOff or gradient) then return end
    local fix = classOff and "turn on Look > Class Colours" or ""
    if gradient then
        fix = fix .. (classOff and " and " or "") .. "change Tint Health from By Health to Off or On Low Health"
    end
    return "For RP health colours, select " .. label .. " in Edit Mode and " .. fix .. ".", "edit", unit, "info"
end

local function ActiveNameplates()
    local p, np = Profile(), FlareUI.Nameplates
    if p and p.nameplates and p.nameplates.enabled ~= false and np and np.TypeDB and not np.standDown then return np end
end

-- Use the configured visibility, not the temporary out-of-combat CVars.
local function FriendlyPicks(np)
    return (np.FriendlyHeld and np.FriendlyHeld()) or (np.FriendlyPicks and np.FriendlyPicks())
end

local function VisibilityHint(np, kind)
    if kind == "friendlyPlayer" then
        local picks = FriendlyPicks(np)
        if picks and picks:sub(1, 1) ~= "1" then
            return "In Visibility, enable Players under Friendly Types."
        end
    else
        local db = Profile().nameplates
        if not db.enemyInCombat and GetCVarBool and not GetCVarBool("nameplateShowEnemies") then
            return "In Visibility, set Show Enemy Plates to Always or Only in Combat."
        elseif db.enemyPlayers == false then
            return "In Visibility, enable Players under Enemy Types."
        end
    end
end

local function LabelHint(key, feature, setting)
    local np = ActiveNameplates()
    if not np then return end
    local companionTitles = key == "showTitles"
    local visibility
    for _, kind in ipairs({ "friendlyPlayer", "enemyPlayer" }) do
        local db = np.TypeDB(kind)
        if db and db.plate == "name" and db[key] then
            local hint = VisibilityHint(np, kind)
            if not hint then return end
            visibility = visibility or hint
        end
    end
    if companionTitles then
        local minor = np.TypeDB("minor")
        if minor and minor.plate == "name" and minor.showTitles then
            local picks = FriendlyPicks(np)
            if picks and picks:sub(3, 3) == "1" then return end
            if GetCVarBool and GetCVarBool("nameplateShowEnemyMinions")
                and (Profile().nameplates.enemyInCombat or GetCVarBool("nameplateShowEnemies")) then return end
            visibility = visibility or "In Visibility, enable Minions under Friendly Types."
        end
    end
    if visibility then return "For " .. feature .. ": " .. visibility, "np", "visibility" end
    local types = companionTitles and "Friendly Player, Enemy Player or Minor (companions)" or "Friendly Player or Enemy Player"
    return "For " .. feature .. ", select " .. types .. " in Plate Setup. Enable Plate > Name Only Mode, then select Under the Name > " .. setting .. ".", "np", "style"
end

local function GuildColourHint()
    local np = ActiveNameplates()
    local db = np and np.TypeDB("friendlyPlayer")
    if not db then return end
    if db.plate ~= "name" or not db.guildColor then
        return "For RP guildmate colours, select Friendly Player in Plate Setup. Enable Plate > Name Only Mode and turn on Colour Guild Members there.", "np", "style"
    end
    local hint = VisibilityHint(np, "friendlyPlayer")
    if hint then return "For RP guildmate colours: " .. hint, "np", "visibility" end
end

local plateLabels = { friendlyPlayer = "Friendly Player", enemyPlayer = "Enemy Player", minor = "Minor" }

local function HasFullPlateName(np, db)
    if np.NameAbovePick(db) then return true end
    for _, fields in pairs(np.TextSlots(db)) do
        if FlareUI.BarText.NameOf(fields) then return true end
    end
    return false
end

local function PlateHint()
    local np = ActiveNameplates()
    if not np then return end
    -- Read both lists from the selected profile, even while live plates await combat end.
    local combat, fighting = np.CombatList(true), np.FightList(true)
    local bars, names = {}, {}
    for _, kind in ipairs({ "friendlyPlayer", "enemyPlayer", "minor" }) do
        local db = np.TypeDB(kind)
        if db and db.plate and db.plate ~= "hidden" and (db.plate ~= "name" or db.nameOnlyTarget or combat[kind] or fighting[kind]) then
            if db.healthColor and db.healthColor ~= "class" then bars[#bars + 1] = plateLabels[kind] end
            if not db.nameClassColor and HasFullPlateName(np, db) then names[#names + 1] = plateLabels[kind] end
        end
    end
    local tips = {}
    if #bars > 0 then
        tips[#tips + 1] = "For RP health bars (" .. table.concat(bars, ", ") .. "): Plate > Look > Colour By > Class & Reaction."
    end
    if #names > 0 then
        tips[#tips + 1] = "For full-plate RP names (" .. table.concat(names, ", ") .. "): Plate > Text > Colour Names by Class."
    end
    if #tips > 0 then
        return "Select the listed type in Plate Setup.\n" .. table.concat(tips, "\n"), "np", "style", "info"
    end
end

local function Destination(action, target)
    if action == "edit" then
        local s = FlareUI.Settings
        local frame = _G[groupFrames[target] or ns.directFrames[target]]
        return "Edit " .. labels[target] .. " Frame", frame and s and s.EditFrame and s.CanEditFrames and s:CanEditFrames(),
            function() return s:EditFrame(frame, "uf") end
    end
    local panel = FlareUI.SettingsPanel
    return action == "np" and "Open Nameplate Settings" or "Open Unit Frame Settings", panel and panel.Open,
        function() panel:Open(action, target); return true end
end

-- A reminder of the clicked instruction, independent of the hidden TRP3 page.
local note, noteTitle, noteText, owner
local function HintText(text, tone)
    return tone == "info" and text or "|A:services-icon-warning:14:14|a " .. text
end
local watched = {}
local NOTE_WIDTH, NOTE_PAD, TEXT_TOP = 380, 18, 44
local function FitNote()
    note:SetHeight(TEXT_TOP + math.ceil(noteText:GetStringHeight()) + NOTE_PAD)
end

local function PinHint(message, destination, tone)
    if not note then
        note = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        note:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 24, -64)
        note:SetFrameStrata("FULLSCREEN_DIALOG")
        note:SetWidth(NOTE_WIDTH)
        note:SetClampedToScreen(true)
        -- Use the window palette with a compact border. The full-size panel
        -- skin's fixed-height glow and shade would extend past a short note.
        local style = FlareUI.WINDOW_STYLE
        note:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16 })
        note:SetBackdropBorderColor(unpack(style.border))
        local bg = note:CreateTexture(nil, "BACKGROUND")
        bg:SetPoint("TOPLEFT", 4, -4)
        bg:SetPoint("BOTTOMRIGHT", -4, 4)
        bg:SetColorTexture(1, 1, 1)
        bg:SetGradient("VERTICAL", CreateColor(unpack(style.bottom)), CreateColor(unpack(style.top)))
        note:SetMovable(true)
        note:EnableMouse(true)
        note:RegisterForDrag("LeftButton")
        note:SetScript("OnDragStart", note.StartMoving)
        note:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); FitNote() end)
        note:SetScript("OnHide", function(self) self:StopMovingOrSizing(); owner = nil end)
        noteTitle = note:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noteTitle:SetPoint("TOPLEFT", NOTE_PAD, -14)
        local close = CreateFrame("Button", nil, note, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -4, -4)
        close:SetScript("OnClick", function() note:Hide() end)
        noteText = note:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        noteText:SetPoint("TOPLEFT", NOTE_PAD, -TEXT_TOP)
        -- Give the font string its wrap width before measuring, even when
        -- the frame was hidden or its drag anchors haven't resolved yet.
        noteText:SetWidth(NOTE_WIDTH - 2 * NOTE_PAD)
        noteText:SetWordWrap(true)
        noteText:SetSpacing(2)
        noteText:SetJustifyH("LEFT")
    end
    owner = destination
    if owner and not watched[owner] then
        watched[owner] = true
        owner:HookScript("OnHide", function(self) if owner == self then note:Hide() end end)
    end
    noteTitle:SetText(HintText("FlareUI RP", tone))
    noteText:SetText(message)
    note:Show()
    FitNote()
end

-- TRP3 builds the page once and anchors each row to its predecessor. Collapse
-- the unused row but keep its frame shown so OnShow can recheck it next visit.
local function Hint(elements, index, checks, diagnose, option)
    local row = { inherit = "TRP3_ConfigButton", marginLeft = option and option.marginLeft }
    local function State()
        if not option then return diagnose() end
        local value = TRP3_API.configuration.getValue(option.configKey)
        if value and value ~= "none" then return diagnose() end
    end
    local lastMessage
    local function Refresh(checkOnly)
        local w = row.widget
        if not w or not w:IsVisible() then return end
        local message, action, target, tone = State()
        if checkOnly == true and message == lastMessage then return end
        lastMessage = message
        if not message then
            w.Title:Hide()
            w.Button:Hide()
            w:SetHeight(1)
            return
        end
        w.Title:SetText(HintText(message, tone))
        w.Title:Show()
        local text, enabled = Destination(action, target)
        w.Button:SetText(text)
        w.Button:SetWidth(w.Button:GetTextWidth() + 28)
        w.Button:SetEnabled(not not enabled)
        w.Button:Show()
        w:SetHeight(w.Title:GetStringHeight() + 36)
    end
    row.OnClick = function()
        local message, action, target, tone = State()
        if action then
            local _, enabled, open = Destination(action, target)
            if enabled and open() then
                TRP3_MainFrame:Hide()
                PinHint(message, action == "edit" and EditModeManagerFrame or FlareUI_SettingsPanel, tone)
                return
            end
        end
        Refresh()
    end
    row.elementData = true
    row.elementInitializer = function(w)
        if w.setupHintReady then Refresh(); return end
        w.setupHintReady = true
        w.Title:ClearAllPoints()
        w.Title:SetPoint("TOPLEFT", 25, -2)
        w.Title:SetPoint("TOPRIGHT", -10, -2)
        w.Title:SetWordWrap(true)
        w.Button:ClearAllPoints()
        w.Button:SetPoint("TOPLEFT", w.Title, "BOTTOMLEFT", 0, -4)
        w:HookScript("OnShow", Refresh)
        local width
        w:HookScript("OnSizeChanged", function(_, newWidth)
            if width ~= newWidth then width = newWidth; Refresh() end
        end)
        w:RegisterEvent("PLAYER_REGEN_DISABLED")
        w:RegisterEvent("PLAYER_REGEN_ENABLED")
        w:SetScript("OnEvent", Refresh)
        Refresh()
    end
    if option and option.inherit == "TRP3_ConfigDropDown" then
        TRP3_API.configuration.registerHandler(option.configKey, function() Refresh() end)
    elseif option then option.OnClick = Refresh end
    checks[#checks + 1] = function() Refresh(true) end
    table.insert(elements, index, row)
end

function ns.AddSetupHints(elements)
    local checks = {}
    for i = #elements, 1, -1 do
        local opt = elements[i]
        local unit = opt.configKey and opt.configKey:match("^flareui_rp_(%w+)_health$")
        if labels[unit] then
            Hint(elements, i + 1, checks, function() return FrameHint(unit) end, opt)
        elseif opt.configKey == "flareui_rp_plate_colours" then
            Hint(elements, i + 1, checks, PlateHint, opt)
        elseif opt.configKey == "flareui_rp_plate_guilds" then
            Hint(elements, i + 1, checks, function() return LabelHint("showGuild", "RP guild names", "Guild") end, opt)
        elseif opt.configKey == "flareui_rp_plate_titles" then
            Hint(elements, i + 1, checks, function() return LabelHint("showTitles", "RP titles", "Title") end, opt)
        elseif opt.configKey == "flareui_rp_plate_guild_colours" then
            Hint(elements, i + 1, checks, GuildColourHint, opt)
        end
    end
    Hint(elements, 1, checks, function() return ModuleHint("nameplates", "The Nameplates module") end)
    Hint(elements, 1, checks, function() return ModuleHint("unitframes", "The Unit Frames module") end)

    -- FlareUI's panel and Edit Mode don't share a setting-change callback.
    -- Use one slow ticker for the open page; unchanged hints need no layout.
    return function(frame)
        local ticker
        local function Stop()
            if ticker then ticker:Cancel(); ticker = nil end
        end
        local function Start()
            if ticker then return end
            ticker = C_Timer.NewTicker(1, function()
                -- Even if the page misses OnHide, stop before checking any settings.
                if not frame:IsVisible() then Stop(); return end
                for _, check in ipairs(checks) do check() end
            end)
        end
        frame:HookScript("OnShow", Start)
        frame:HookScript("OnHide", Stop)
        if frame:IsVisible() then Start() end
    end
end
