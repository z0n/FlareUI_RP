local _, ns = ...

local windowStyles = { Thick = 16, Thin = 8, Frames = 16 }
local trackerStyle = "Quest Tracker"
local trackerAtlas = "ui-questtracker-primary-objective-header"

-- Keep the end ornaments compact even when the toolbar wraps to one column.
-- Only the middle stretches. The foot uses the ruled lower band of the same atlas.
local function AddTrackerStrip(parts, frame, bounds, info, placement)
    if not (frame and frame.CreateTexture) then return end
    local rail = placement ~= "header"
    local bottom = placement == "bottom"
    local l, r, t, b = info.leftTexCoord, info.rightTexCoord, info.topTexCoord, info.bottomTexCoord
    if rail then t, b = t + (b - t) * 31/40, t + (b - t) * 38/40 end
    local height = rail and info.height * 7/40 or info.height * 25/30
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
    local y = bottom and 2.5 or rail and -2.5 or -13
    left:SetPoint("LEFT", bounds, bottom and "BOTTOMLEFT" or "TOPLEFT", -leftOut, y)
    right:SetPoint("RIGHT", bounds, bottom and "BOTTOMRIGHT" or "TOPRIGHT", rightOut, y)
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

-- Glance slots use a round icon mask and an unnamed minimap ring instead
-- of the named Border on TRP3's action buttons. Identify the art, not its index.
local function GlanceRing(slot)
    local path = "Interface\\MINIMAP\\MiniMap-TrackingBorder.blp"
    local id = GetFileIDFromPath and GetFileIDFromPath(path)
    for _, region in ipairs({ slot:GetRegions() }) do
        local tex = region.GetTexture and region:GetTexture()
        if (id and tex == id) or (type(tex) == "string" and tex:lower() == path:lower()) then return region end
    end
end

local function StartBar(config, elements, toolbar, target)
    local key = target and "flareui_rp_targetbar_skin" or "flareui_rp_toolbar_borders"
    local windowKey = target and "flareui_rp_targetbar_window_style" or "flareui_rp_toolbar_window_border"
    local label = target and "Target Bar & At First Glance" or "Toolbar"
    local media = LibStub and LibStub("LibSharedMedia-3.0", true)
    local file = media and media:Fetch("border", "FlareUI Frames", true)
    if not file then return end

    config.registerConfigKey(key, true)
    config.registerConfigKey(windowKey, target and "Frames" or trackerStyle)
    local enabled = config.getValue(key)
    local windowStyle = config.getValue(windowKey)
    local native, skins = {}, {}
    local function PaintButton(button, ring)
        local skin = skins[button]
        if not skin then
            skin = CreateFrame("Frame", nil, button, "BackdropTemplate")
            skin:EnableMouse(false)
            skin:SetAllPoints(button.Icon)
            skins[button] = skin
        end
        if skin.nativeAlpha == nil then
            skin.nativeBorder = ring or button.Border
            skin.nativeAlpha = skin.nativeBorder:GetAlpha()
            skin.nativeBorder:SetAlpha(0)
            if ring then
                button.Icon:RemoveMaskTexture(button.IconMask)
                skin.mask = button.IconMask
                local hover = button:GetHighlightTexture()
                if hover and hover:GetTexture() then
                    skin.hoverFile, skin.hoverAlpha = hover:GetTexture(), hover:GetAlpha()
                    hover:SetTexture("Interface\\Buttons\\WHITE8X8")
                    hover:SetAlpha(skin.hoverAlpha * 0.18)
                end
            end
        end
        local edge = 16 * math.min(button:GetWidth() / 45, 1)
        if skin.edge ~= edge then
            skin:SetBackdrop({ edgeFile = file, edgeSize = edge })
            skin:SetBackdropBorderColor(0.65, 0.49, 0.27, 1)
            skin.edge = edge
        end
        skin:Show()
    end
    local strips, surround, panelShown
    local function RefreshWindow()
        local tracker = windowStyle == trackerStyle
        local style = windowStyles[windowStyle] and windowStyle or "Thick"
        local edge = windowStyles[style]
        local border = enabled and media:Fetch("border", "FlareUI " .. style, true)
        local container = toolbar.Container
        local panel = target and toolbar or container and container.Backdrop
        local title = target and toolbar.Header or toolbar.TitleBar
        panelShown = target or container and container:IsShown()
        -- TRP3 hides the container when its last button is removed. The title
        -- still needs its own backdrop until there's a panel to frame again.
        local decorate = tracker and border and panelShown and panel and title and (target or toolbar.UpdateTitleBar)
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
                    if target then
                        surround:SetPoint("TOP", title, "TOP")
                        surround:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT")
                        surround:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT")
                    elseif title:IsShown() then
                        surround:SetPoint("TOPLEFT", toolbar, "TOPLEFT")
                        surround:SetPoint("TOPRIGHT", toolbar, "TOPRIGHT")
                        surround:SetPoint("BOTTOM", panel, "BOTTOM")
                    else
                        surround:SetAllPoints(panel)
                    end
                end
                if not target then hooksecurefunc(toolbar, "UpdateTitleBar", Fit) end
                Fit()
                strips = {}
                AddTrackerStrip(strips, title, surround, info, "header")
                AddTrackerStrip(strips, target and surround or panel, surround, info, "bottom")
                if target and TRP3_GlanceBar then
                    -- The glance row has no title: use the narrow ornament at
                    -- both edges, anchored to the row even when it is detached.
                    AddTrackerStrip(strips, TRP3_GlanceBar, TRP3_GlanceBar, info, "top")
                    AddTrackerStrip(strips, TRP3_GlanceBar, TRP3_GlanceBar, info, "bottom")
                end
            end
        end
        decorate = not not (decorate and surround)
        -- TRP3's target group box forwards border tint changes to its header.
        -- Save the header first when applying and restore it last when disabling.
        if target and border then PaintWindow(title, native, border, math.min(edge, 12), decorate) end
        PaintWindow(panel, native, border, edge, decorate)
        if not target or not border then PaintWindow(title, native, border, math.min(edge, 12), decorate) end
        if target and TRP3_GlanceBar then
            local bar = TRP3_GlanceBar
            PaintWindow(bar, native, border, edge)
            if enabled then
                for i = 1, 5 do
                    local slot = _G["TRP3_GlanceBarSlot" .. i]
                    if slot and slot:GetParent() == bar and slot.Icon and slot.IconMask then
                        local ring = skins[slot] and skins[slot].nativeBorder or GlanceRing(slot)
                        if ring then PaintButton(slot, ring) end
                    end
                end
            end
        end
        if surround then surround:SetShown(decorate) end
        if strips then
            for _, tex in ipairs(strips) do tex:SetShown(decorate) end
        end
    end
    local function Buttons()
        if not target then return toolbar.buttonPool:EnumerateActive() end
        -- TRP3 creates these lazily and reuses them, numbered from zero.
        local i = 0
        return function()
            while true do
                local button = _G["TRP3_TargetFrameButton" .. i]
                if not button or button:GetParent() ~= toolbar then return end
                i = i + 1
                if button:IsShown() then return button end
            end
        end
    end
    local function Refresh()
        if not enabled then return end
        if windowStyle == trackerStyle and toolbar.Container and toolbar.Container:IsShown() ~= panelShown then
            RefreshWindow()
        end
        for button in Buttons() do
            if button.Icon and button.Border then PaintButton(button) end
        end
    end
    if target then
        -- TRP3 shows the target bar before assigning buttons. Wait until that
        -- layout is complete, including target swaps with the same dimensions.
        local pending
        toolbar:HookScript("OnShow", function()
            if not enabled or pending then return end
            pending = true
            C_Timer.After(0, function()
                pending = nil
                if toolbar:IsShown() then Refresh() end
            end)
        end)
    else
        hooksecurefunc(toolbar, "UpdateButtons", Refresh)
    end
    config.registerHandler(key, function(_, on)
        enabled = on
        RefreshWindow()
        if on then Refresh(); return end
        -- Restore inactive pool members too, before TRP3 reuses them.
        for button, skin in pairs(skins) do
            if skin.nativeAlpha ~= nil then
                skin.nativeBorder:SetAlpha(skin.nativeAlpha)
                if skin.mask then button.Icon:AddMaskTexture(skin.mask); skin.mask = nil end
                if skin.hoverFile then
                    local hover = button:GetHighlightTexture()
                    if hover then
                        hover:SetTexture(skin.hoverFile)
                        hover:SetAlpha(skin.hoverAlpha)
                    end
                    skin.hoverFile, skin.hoverAlpha = nil, nil
                end
                skin.nativeAlpha = nil
            end
            skin:Hide()
        end
    end)
    config.registerHandler(windowKey, function(_, style)
        windowStyle = style
        RefreshWindow()
    end)
    elements[#elements + 1] = { inherit = "TRP3_ConfigH1", title = label }
    elements[#elements + 1] = { inherit = "TRP3_ConfigCheck", configKey = key, title = "Use FlareUI Styling",
        help = target and "Apply FlareUI borders to the target bar, its buttons and the At First Glance panel and slots. Turn off to restore TRP3's appearance."
            or "Apply FlareUI borders to the toolbar window and buttons. TRP3 still controls their size, layout and visibility." }
    elements[#elements + 1] = { inherit = "TRP3_ConfigDropDown", configKey = windowKey,
        widgetName = target and "FlareUI_RP_ConfigTargetBarWindowStyle" or "FlareUI_RP_ConfigToolbarWindowBorder", title = "Window Style",
        dependentOnOptions = { key },
        help = "Choose the window border. Quest Tracker adds a decorated header and footer. Buttons keep the same FlareUI border in every style.",
        listContent = { { "Thick", "Thick" }, { "Thin", "Thin" }, { "Frames", "Frames" }, { trackerStyle, trackerStyle } } }
    RefreshWindow()
    Refresh()
end

function ns.StartToolbar(config, elements)
    local toolbar = TRP3_ToolbarFrame
    if TRP3_API.toolbar and toolbar and toolbar.UpdateButtons
        and toolbar.buttonPool and toolbar.buttonPool.EnumerateActive then
        StartBar(config, elements, toolbar, false)
    end
    local target = TRP3_TargetFrame
    if TRP3_API.target and target and target.Header then
        StartBar(config, elements, target, true)
    end
end
