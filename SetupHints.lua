local _, ns = ...
local labels = { player = "Player", target = "Target", focus = "Focus", targettarget = "Target of Target",
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
    if db.enabled == false then return label .. " frames are switched off in FlareUI.", "uf" end
    if unit == "party" then db = db[db.style == "raid" and "raid" or "classic"] end
    if not db then return end
    local classOff = not FlareUI.ClassColorsOn(db)
    local gradient = FlareUI.UnitFrames.HealthColorMode(db) == "health"
    if not (classOff or gradient) then return end
    local fix = classOff and "turn on Look > Class Colours" or ""
    if gradient then
        fix = fix .. (classOff and " and " or "") .. "change Tint Health from By Health to Off or On Low Health"
    end
    return "In Edit Mode, select " .. label .. " and " .. fix .. " to use RP health colours.", "edit", unit
end

local function PlateHint()
    local p, np = Profile(), FlareUI.Nameplates
    if not (p and p.nameplates and p.nameplates.enabled ~= false and np and np.TypeDB) or np.standDown then return end
    local blocked = {}
    for _, kind in ipairs({ "friendlyPlayer", "enemyPlayer" }) do
        local db = np.TypeDB(kind)
        if db and db.plate and db.plate ~= "name" and db.healthColor and db.healthColor ~= "class" then
            blocked[#blocked + 1] = kind == "friendlyPlayer" and "Friendly Player" or "Enemy Player"
        end
    end
    if #blocked > 0 then
        return "For RP health bars, select " .. table.concat(blocked, " and ") ..
            " in Plate Setup and choose Style > Look > Colour By > Class & Reaction.", "np", "style"
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
local note, noteText, owner
local watched = {}
local NOTE_WIDTH, NOTE_PAD, TEXT_TOP = 380, 18, 44
local function FitNote()
    note:SetHeight(TEXT_TOP + math.ceil(noteText:GetStringHeight()) + NOTE_PAD)
end

local function PinHint(message, destination)
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
        local title = note:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", NOTE_PAD, -14)
        title:SetText("|A:services-icon-warning:14:14|a FlareUI RP")
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
    noteText:SetText(message)
    note:Show()
    FitNote()
end

-- TRP3 builds the page once and anchors each row to its predecessor. Collapse
-- the unused row but keep its frame shown so OnShow can recheck it next visit.
local function Hint(elements, index, checks, diagnose, option)
    local row = { inherit = "TRP3_ConfigButton" }
    local function State()
        if not option or TRP3_API.configuration.getValue(option.configKey) then return diagnose() end
    end
    local lastMessage
    local function Refresh(checkOnly)
        local w = row.widget
        if not w or not w:IsVisible() then return end
        local message, action, target = State()
        if checkOnly == true and message == lastMessage then return end
        lastMessage = message
        if not message then
            w.Title:Hide()
            w.Button:Hide()
            w:SetHeight(1)
            return
        end
        local text, enabled = Destination(action, target)
        w.Title:SetText("|A:services-icon-warning:14:14|a " .. message)
        w.Title:Show()
        w.Button:SetText(text)
        w.Button:SetWidth(w.Button:GetTextWidth() + 28)
        w.Button:SetEnabled(not not enabled)
        w.Button:Show()
        w:SetHeight(w.Title:GetStringHeight() + 36)
    end
    row.OnClick = function()
        local message, action, target = State()
        if message then
            local _, enabled, open = Destination(action, target)
            if enabled and open() then
                TRP3_MainFrame:Hide()
                local destination
                if action == "edit" then destination = EditModeManagerFrame else destination = FlareUI_SettingsPanel end
                PinHint(message, destination)
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
    if option then option.OnClick = Refresh end
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
        end
    end
    Hint(elements, 2, checks, function() return ModuleHint("nameplates", "The Nameplates module") end)
    Hint(elements, 2, checks, function() return ModuleHint("unitframes", "The Unit Frames module") end)

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
