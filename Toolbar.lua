local _, ns = ...

local key = "flareui_rp_toolbar_borders"
local windowKey = "flareui_rp_toolbar_window_border"
local windowStyles = { Thick = 16, Thin = 8, Frames = 16 }
local trackerStyle = "Quest Tracker"
local trackerAtlas = "ui-questtracker-primary-objective-header"

-- Keep the end ornaments compact even when the toolbar wraps to one column.
-- Only the middle stretches. The foot uses the ruled lower band of the same atlas.
local function AddTrackerStrip(parts, frame, bounds, info, footer)
    if not (frame and frame.CreateTexture) then return end
    local l, r, t, b = info.leftTexCoord, info.rightTexCoord, info.topTexCoord, info.bottomTexCoord
    if footer then t, b = t + (b - t) * 31/40, t + (b - t) * 38/40 end
    local height = footer and info.height * 7/40 or info.height * 25/30
    local function Slice()
        local tex = frame:CreateTexture(nil, "ARTWORK")
        tex:SetTexture(info.file)
        tex:SetHeight(height)
        tex:SetSnapToPixelGrid(false)
        tex:SetTexelSnappingBias(0)
        parts[#parts + 1] = tex
        return tex
    end
    -- Match the tracker's asymmetric atlas placement, including its transparent
    -- margins. Cropping at the window edges cuts through the right-hand knobs.
    local width = info.width
    local reach = math.max(0, (width - 260) / 2)
    -- FlareUI insets its header by 8, then extends it by reach-1 / reach+5.
    local leftOut, rightOut = reach - 9, reach - 3
    local left, right, mid = Slice(), Slice(), Slice()
    local y = footer and 2.5 or -13
    left:SetPoint("LEFT", bounds, footer and "BOTTOMLEFT" or "TOPLEFT", -leftOut, y)
    right:SetPoint("RIGHT", bounds, footer and "BOTTOMRIGHT" or "TOPRIGHT", rightOut, y)
    mid:SetPoint("LEFT", left, "RIGHT")
    mid:SetPoint("RIGHT", right, "LEFT")
    mid:SetTexCoord(l + 0.495 * (r-l), l + 0.505 * (r-l), t, b)
    local cap = math.floor(width * 0.3 + 0.5)
    local function FitCaps(_, boxWidth)
        -- At narrow strides trim only the *inside* of each cap. Keep its
        -- outside texels at native width, with room between caps for the middle.
        local half = (boxWidth - 1) / 2
        local a = math.max(1, math.min(cap, half + leftOut))
        local z = math.max(1, math.min(cap, half + rightOut))
        left:SetWidth(a)
        right:SetWidth(z)
        left:SetTexCoord(l, l + a/width * (r-l), t, b)
        right:SetTexCoord(r - z/width * (r-l), r, t, b)
    end
    bounds:HookScript("OnSizeChanged", FitCaps)
    FitCaps(bounds, bounds:GetWidth())
end

local function PaintWindow(frame, native, file, edge, clear)
    if not (frame and frame.GetBackdrop and frame.SetBackdrop
        and frame.GetBackdropColor and frame.GetBackdropBorderColor
        and frame.SetBackdropColor and frame.SetBackdropBorderColor) then return end
    local original = native[frame]
    if file then
        if not original then
            native[frame] = { backdrop = frame:GetBackdrop(), fill = { frame:GetBackdropColor() },
                border = { frame:GetBackdropBorderColor() } }
        end
        if clear then frame:SetBackdrop(nil); return end
        frame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = file, edgeSize = edge, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
        frame:SetBackdropColor(1, 1, 1, 0.85)
        frame:SetBackdropBorderColor(0.65, 0.49, 0.27, 1)
    elseif original then
        frame:SetBackdrop(original.backdrop)
        if original.backdrop then
            frame:SetBackdropColor(unpack(original.fill))
            frame:SetBackdropBorderColor(unpack(original.border))
        end
        native[frame] = nil
    end
end

function ns.StartToolbar(config, elements)
    local toolbar = TRP3_ToolbarFrame
    if not (TRP3_API.toolbar and toolbar and toolbar.UpdateButtons
        and toolbar.buttonPool and toolbar.buttonPool.EnumerateActive) then return end
    local media = LibStub and LibStub("LibSharedMedia-3.0", true)
    local file = media and media:Fetch("border", "FlareUI Frames", true)
    if not file then return end

    config.registerConfigKey(key, true)
    config.registerConfigKey(windowKey, trackerStyle)
    local enabled = config.getValue(key)
    local windowStyle = config.getValue(windowKey)
    local native = {}
    local strips, surround, panelShown
    local function RefreshWindow()
        local tracker = windowStyle == trackerStyle
        local style = windowStyles[windowStyle] and windowStyle or "Thick"
        local edge = windowStyles[style]
        local border = enabled and media:Fetch("border", "FlareUI " .. style, true)
        local container = toolbar.Container
        local panel = container and container.Backdrop
        local title = toolbar.TitleBar
        panelShown = container and container:IsShown()
        -- TRP3 hides the container when its last button is removed. The title
        -- still needs its own backdrop until there's a panel to frame again.
        local decorate = tracker and border and panelShown and panel and title and toolbar.UpdateTitleBar
        if decorate and not strips then
            local info = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(trackerAtlas)
            if info and info.file and info.width and info.width > 0 and info.height and info.height > 0 then
                surround = CreateFrame("Frame", nil, panel, "BackdropTemplate")
                surround:EnableMouse(false)
                surround:SetFrameLevel(toolbar:GetFrameLevel())
                local bg = media:Fetch("background", "Blizzard Dialog Background Dark")
                surround:SetBackdrop({ bgFile = bg or "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
                    edgeFile = border, edgeSize = 16, tile = false, tileSize = 0,
                    insets = { left = 3, right = 3, top = 3, bottom = 3 } })
                surround:SetBackdropColor(1, 1, 1, 0.75)
                surround:SetBackdropBorderColor(0.65, 0.49, 0.27, 1)
                local function Fit()
                    surround:ClearAllPoints()
                    if title:IsShown() then
                        surround:SetPoint("TOPLEFT", toolbar, "TOPLEFT")
                        surround:SetPoint("TOPRIGHT", toolbar, "TOPRIGHT")
                        surround:SetPoint("BOTTOM", panel, "BOTTOM")
                    else
                        surround:SetAllPoints(panel)
                    end
                end
                hooksecurefunc(toolbar, "UpdateTitleBar", Fit)
                Fit()
                strips = {}
                AddTrackerStrip(strips, title, surround, info, false)
                AddTrackerStrip(strips, panel, surround, info, true)
            end
        end
        decorate = not not (decorate and surround)
        PaintWindow(panel, native, border, edge, decorate)
        PaintWindow(title, native, border, math.min(edge, 12), decorate)
        if surround then surround:SetShown(decorate) end
        if strips then
            for _, tex in ipairs(strips) do tex:SetShown(decorate) end
        end
    end
    local skins = {}
    local function Refresh()
        if not enabled then return end
        if windowStyle == trackerStyle and toolbar.Container and toolbar.Container:IsShown() ~= panelShown then
            RefreshWindow()
        end
        for button in toolbar.buttonPool:EnumerateActive() do
            if button.Icon and button.Border then
                local skin = skins[button]
                if not skin then
                    skin = CreateFrame("Frame", nil, button, "BackdropTemplate")
                    skin:EnableMouse(false)
                    skin:SetAllPoints(button.Icon)
                    skins[button] = skin
                end
                if skin.nativeAlpha == nil then
                    skin.nativeAlpha = button.Border:GetAlpha()
                    button.Border:SetAlpha(0)
                end
                -- Scale the action-bar edge down for TRP3's smaller icons.
                local edge = 16 * math.min(button:GetWidth() / 45, 1)
                if skin.edge ~= edge then
                    skin:SetBackdrop({ edgeFile = file, edgeSize = edge })
                    skin:SetBackdropBorderColor(0.65, 0.49, 0.27, 1)
                    skin.edge = edge
                end
                skin:Show()
            end
        end
    end
    -- UpdateButtons is also used as a one-shot OnUpdate. Hook the instance
    -- before TRP3's WORKFLOW_ON_FINISH builds its first toolbar.
    hooksecurefunc(toolbar, "UpdateButtons", Refresh)
    config.registerHandler(key, function(_, on)
        enabled = on
        RefreshWindow()
        if on then Refresh(); return end
        -- Restore inactive pool members too, before TRP3 reuses them.
        for button, skin in pairs(skins) do
            if skin.nativeAlpha ~= nil then
                button.Border:SetAlpha(skin.nativeAlpha)
                skin.nativeAlpha = nil
            end
            skin:Hide()
        end
    end)
    config.registerHandler(windowKey, function(_, style)
        windowStyle = style
        RefreshWindow()
    end)
    elements[#elements + 1] = { inherit = "TRP3_ConfigH1", title = "Total RP 3 Toolbar" }
    elements[#elements + 1] = { inherit = "TRP3_ConfigCheck", configKey = key, title = "Skin Total RP 3 Toolbar",
        help = "Use FlareUI borders on the toolbar window, title and buttons." }
    elements[#elements + 1] = { inherit = "TRP3_ConfigDropDown", configKey = windowKey,
        widgetName = "FlareUI_RP_ConfigToolbarWindowBorder", title = "Window Style",
        help = "Choose a border or use the Quest Tracker's decorated title and footer. Buttons keep the action-bar border.",
        listContent = { { "Thick", "Thick" }, { "Thin", "Thin" }, { "Frames", "Frames" }, { trackerStyle, trackerStyle } } }
    RefreshWindow()
    Refresh()
end
