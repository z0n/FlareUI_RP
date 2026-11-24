local _, ns = ...

local key = "flareui_rp_main_window_skin"
local roundRect = "Interface\\AddOns\\FlareUI\\Media\\Panel\\RoundRect.tga"
local chevron = "Interface\\AddOns\\FlareUI\\Media\\Panel\\Chevron.tga"
local plateAtlas = "common-dropdown-c-button"
local function HasMethod(frame, mixin, key)
    return mixin and type(mixin[key]) == "function" and frame[key] == mixin[key]
end

local function IsUtilityPage(frame)
    if frame == TRP3_ConfigurationModule or frame == TRP3_AutomationSettingsFrame
        or frame == TRP3_CharacterImporter or frame == TRP3_CompanionImporter then return true end
    if HasMethod(frame, TRP3_RelationsListMixin, "GetTargetNameForRelation")
        or HasMethod(frame, TRP3_ProfileManagerListMixin, "SetElementInitializer") then return true end
    local name = frame:GetName()
    return name and name:match("^TRP3_ConfigurationPage%d+$")
end
local rimPieces = { "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner",
    "TopEdge", "BottomEdge", "LeftEdge", "RightEdge" }
-- These sections have permanent children. Other sections (e.g. Directory)
-- can acquire temporary profile pages; detect their open state from the rows.
local sectionChildren = { "main_11_profiles", "main_41_customization_relations", "main_91_config_main_config_0_general" }
local tabArt = { "Left", "Middle", "Right", "LeftActive", "MiddleActive", "RightActive",
    "LeftHighlight", "MiddleHighlight", "RightHighlight" }
local categoryArt = { "EdgeLeft", "Center", "EdgeRight", "BorderEdgeLeft", "BorderCenter", "BorderEdgeRight",
    "HighlightEdgeLeft", "HighlightCenter", "HighlightEdgeRight",
    "HighlightBorderEdgeLeft", "HighlightBorderCenter", "HighlightBorderEdgeRight" }

local function Rounded(texture)
    texture:SetTexture(roundRect)
    if texture.SetTextureSliceMargins then
        texture:SetTextureSliceMargins(8, 8, 8, 8)
        if Enum.UITextureSliceMode then texture:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched) end
    end
end

local function SavePoints(region)
    local points = {}
    for i = 1, region:GetNumPoints() do points[i] = { region:GetPoint(i) } end
    return points
end

local function RestorePoints(region, points)
    region:ClearAllPoints()
    for _, point in ipairs(points) do region:SetPoint(unpack(point)) end
end

-- Preserve only the offsets we change: SetIcon can still move the label horizontally.
local function TabOffsets(tab, offsets, restore)
    local function Move(region, point, index)
        local anchor, relative, relativePoint, x, y = region:GetPointByName(point)
        if not anchor then return end
        if not restore then offsets[index] = y end
        if offsets[index] then region:SetPoint(point, relative, relativePoint, x, restore and offsets[index] or 0) end
    end
    Move(tab.Text, "LEFT", 1)
    Move(tab.Text, "RIGHT", 2)
    Move(tab.Icon, "LEFT", 3)
end

local function RestoreTexture(button, state, styled, original)
    if button["Get" .. state .. "Texture"](button) ~= styled then return end
    if original then button["Set" .. state .. "Texture"](button, original)
    else button["Clear" .. state .. "Texture"](button) end
end

function ns.StartMainWindow(config, elements)
    local window, menu, pages = TRP3_MainFrame, TRP3_MainFrameMenuScroll, TRP3_MainFramePageContainer
    local media = LibStub and LibStub("LibSharedMedia-3.0", true)
    local file = media and media:Fetch("border", "FlareUI Frames", true)
    if not (window and window.Backdrop and menu and pages and file) then return end
    local thin = media:Fetch("border", "FlareUI Thin", true)
    local thick = media:Fetch("border", "FlareUI Thick", true)

    config.registerConfigKey(key, true)
    local enabled = config.getValue(key)
    local edges, fills, native = {}, {}, {}
    local controls = {}
    local plates = {}
    local titleColors = {}
    local scrollScales = {}
    local hasPlates = C_Texture and C_Texture.GetAtlasInfo(plateAtlas)
    local hasBronze = C_Texture and C_Texture.GetAtlasInfo("heavybronze-frame-basic")

    -- The border overlay never receives mouse input.
    local function Edge(frame, size, border)
        if not edges[frame] then
            local edge = CreateFrame("Frame", nil, frame, "BackdropTemplate")
            edge:EnableMouse(false)
            edge:SetAllPoints()
            edge:SetBackdrop({ edgeFile = border or file, edgeSize = size })
            edge:SetBackdropBorderColor(0.65, 0.49, 0.27, 1)
            edges[frame] = edge
        end
        edges[frame]:Show()
        return edges[frame]
    end

    local function Mute(region)
        if region and native[region] == nil then
            native[region] = region:GetAlpha()
            region:SetAlpha(0)
        end
    end

    local function PanelRim(frame)
        for _, piece in ipairs(rimPieces) do Mute(frame[piece]) end
        Edge(frame, 8, thin)
    end

    local function Fill(frame, original, stone, opacity)
        if not original then return end
        if not fills[frame] then
            local fill = frame:CreateTexture(nil, "BACKGROUND")
            if stone then
                -- FlareUI insets the stone 12 horizontally and 7 vertically
                -- from the bronze atlas, leaving its cut corners transparent.
                local x, y = hasBronze and 12 or 3, hasBronze and 7 or 3
                fill:SetPoint("TOPLEFT", x, -y)
                fill:SetPoint("BOTTOMRIGHT", -x, y)
                fill:SetTexture("Interface\\FrameGeneral\\UI-Background-Rock", "REPEAT", "REPEAT")
                fill:SetHorizTile(true)
                fill:SetVertTile(true)
            else
                fill:SetPoint("TOPLEFT", 4, -4)
                fill:SetPoint("BOTTOMRIGHT", -4, 4)
                fill:SetColorTexture(0, 0, 0, opacity)
            end
            fills[frame] = fill
        end
        Mute(original)
        fills[frame]:Show()
    end

    -- The dashboard parchment is a child frame, so a texture on the window
    -- itself cannot draw over it, even in the OVERLAY draw layer.
    local bronze
    local buttonLevels = {}
    local function KeepAbove(button, overlay)
        if button and button:GetFrameLevel() <= overlay:GetFrameLevel() then
            buttonLevels[button] = buttonLevels[button] or button:GetFrameLevel()
            button:SetFrameLevel(overlay:GetFrameLevel() + 1)
        end
    end
    local function WindowBorder()
        if not hasBronze then
            return Edge(window, 16, thick)
        end
        if not bronze then
            bronze = CreateFrame("Frame", nil, window)
            bronze:SetAllPoints(window)
            bronze:EnableMouse(false)
            local rim = bronze:CreateTexture(nil, "BORDER")
            rim:SetAllPoints()
            rim:SetAtlas("heavybronze-frame-basic")
            for suffix, point in pairs({ TL = "TOPLEFT", BR = "BOTTOMRIGHT" }) do
                local bracket = bronze:CreateTexture(nil, "ARTWORK")
                bracket:SetAtlas("heavybronze-horz-cornerbracket-" .. suffix, true)
                bracket:SetPoint(point, rim, point)
            end
        end
        local level = window:GetFrameLevel() + 30
        bronze:SetFrameLevel(level)
        bronze:Show()
        return bronze
    end

    local function StylePlate(button, kind)
        if not hasPlates then return end
        local dropdown, tab = kind == "dropdown", kind == "tab"
        local plate = plates[button]
        if not plate then
            local face = button:CreateTexture(nil, "BACKGROUND", nil, 2)
            face:SetPoint("TOPLEFT", -7, 7)
            face:SetPoint("BOTTOMRIGHT", 7, -7)
            plate = { face = face, kind = kind }
            plates[button] = plate
            local function Paint()
                if not enabled or not face:IsShown() then return end
                local over = button:IsMouseOver()
                local down = dropdown and button:IsDown() or not dropdown and button:GetButtonState() == "PUSHED"
                -- TRP3 stops mouse input on the active tab. Use its selected
                -- font for emphasis and release the face even before mouse-up.
                local activeTab = tab and button.MiddleActive:IsShown()
                local suffix = not button:IsEnabled() and "-disabled" or activeTab and ""
                    or down and over and "-pressedhover-1" or down and "-pressed-1"
                    or dropdown and button:IsMenuOpen() and "-open" or over and "-hover-1" or ""
                face:SetAtlas(plateAtlas .. suffix)
                if plate.arrow then
                    if button:IsEnabled() then button.Text:SetTextColor(1, 0.82, 0)
                    else button.Text:SetTextColor(0.5, 0.5, 0.5) end
                    if not button:IsEnabled() then plate.arrow:SetVertexColor(0.45, 0.42, 0.36)
                    elseif over then plate.arrow:SetVertexColor(1, 1, 1)
                    else plate.arrow:SetVertexColor(1, 0.82, 0) end
                end
            end
            plate.paint = Paint
            if dropdown then
                plate.arrow = button:CreateTexture(nil, "OVERLAY")
                plate.arrow:SetTexture(chevron)
                plate.arrow:SetSize(12, 12)
                plate.arrow:SetPoint("RIGHT", -10, 0)
                hooksecurefunc(button, "OnButtonStateChanged", Paint)
                for _, method in ipairs({ "OnMenuOpened", "OnMenuClosed" }) do
                    if type(button[method]) == "function" then hooksecurefunc(button, method, Paint) end
                end
            else
                for _, event in ipairs({ "OnEnter", "OnLeave", "OnMouseDown", "OnMouseUp", "OnEnable", "OnDisable" }) do
                    button:HookScript(event, Paint)
                end
                if tab then
                    hooksecurefunc(button, "SetTabState", function()
                        if enabled and plate.offsets then TabOffsets(button, plate.offsets); Paint() end
                    end)
                end
            end
            button:HookScript("OnShow", Paint)
        end
        if dropdown then
            Mute(button.Background)
            Mute(button.Arrow)
            if not plate.points then
                local text = button.Text
                plate.points, plate.justify = SavePoints(text), text:GetJustifyH()
                text:ClearAllPoints()
                text:SetPoint("LEFT", 26, 0)
                text:SetPoint("RIGHT", -26, 0)
                text:SetJustifyH("CENTER")
            end
            plate.arrow:Show()
        elseif tab then
            for _, name in ipairs(tabArt) do Mute(button[name]) end
            -- ButtonText also has a pressed offset independent of its anchors.
            if plate.pushX == nil then
                plate.pushX, plate.pushY = button:GetPushedTextOffset()
                button:SetPushedTextOffset(0, 0)
                plate.offsets = {}
                TabOffsets(button, plate.offsets)
            end
        else
            Mute(button.Left or button.EdgeLeft)
            Mute(button.Middle or button.Center)
            Mute(button.Right or button.EdgeRight)
            Mute(button:GetHighlightTexture())
            Mute(button.NineSlice)
            local font = button:GetHeight() <= 22.5 and "FlareUI_PanelButtonSmall" or "FlareUI_PanelButton"
            if _G[font] and _G[font .. "Hover"] and _G[font .. "Off"] then
                if not plate.fonts then
                    plate.fonts = { button:GetNormalFontObject(), button:GetHighlightFontObject(), button:GetDisabledFontObject() }
                end
                button:SetNormalFontObject(_G[font])
                button:SetHighlightFontObject(_G[font .. "Hover"])
                button:SetDisabledFontObject(_G[font .. "Off"])
            end
        end
        plate.face:Show()
        plate.paint()
    end

    local function RestorePlate(button, plate)
        plate.face:Hide()
        if plate.arrow then
            plate.arrow:Hide()
            if plate.points then
                RestorePoints(button.Text, plate.points)
                button.Text:SetJustifyH(plate.justify)
                button:OnButtonStateChanged()
                plate.points = nil
            end
        elseif plate.offsets then
            button:SetPushedTextOffset(plate.pushX, plate.pushY)
            TabOffsets(button, plate.offsets, true)
            plate.pushX, plate.pushY, plate.offsets = nil, nil, nil
        elseif plate.fonts then
            button:SetNormalFontObject(plate.fonts[1])
            button:SetHighlightFontObject(plate.fonts[2])
            button:SetDisabledFontObject(plate.fonts[3])
            plate.fonts = nil
        end
    end

    local function StyleCategory(frame)
        local control = controls[frame]
        if not control then
            local fill = frame:CreateTexture(nil, "BACKGROUND")
            local hover = frame:CreateTexture(nil, "HIGHLIGHT")
            local edge = Edge(frame, 8, thin)
            fill:SetPoint("TOPLEFT", 4, -4)
            fill:SetPoint("BOTTOMRIGHT", -4, 4)
            Rounded(fill)
            fill:SetGradient("HORIZONTAL", CreateColor(0.80, 0.60, 0.34, 0.75), CreateColor(0.32, 0.24, 0.13, 0.40))
            local bar = frame:CreateTexture(nil, "ARTWORK")
            bar:SetColorTexture(1, 0.84, 0.50)
            bar:SetPoint("TOPLEFT", 0, -5)
            bar:SetPoint("BOTTOMLEFT", 0, 5)
            bar:SetWidth(3)
            Rounded(hover)
            hover:SetAllPoints(fill)
            hover:SetVertexColor(1, 0.84, 0.50, 0.22)
            local function Paint()
                if not enabled then return end
                -- TRP3 disables the selected sidebar row (including pooled rows).
                local selected = not frame:IsEnabled()
                fill:SetShown(selected)
                bar:SetShown(selected)
                edge:SetShown(selected)
                if control and control.sidebar then
                    local r, g, b = 0.85, 0.80, 0.70
                    if selected then r, g, b = 1, 0.84, 0.50
                    elseif control.section then r, g, b = 0.66, 0.55, 0.36 end
                    frame.Text:SetTextColor(r, g, b)
                    if control.section and control.arrow then control.arrow:SetVertexColor(r, g, b) end
                end
            end
            hooksecurefunc(frame, "SetVisualState", Paint)
            control = { fill = fill, hover = hover, bar = bar, paint = Paint }
            controls[frame] = control
        end
        for _, name in ipairs(categoryArt) do Mute(frame[name]) end
        control.paint()
        control.hover:Show()
    end

    local dashboardAnchors
    local function FitDashboard(bg)
        if dashboardAnchors or not (bg and fills[window]) then return end
        dashboardAnchors = SavePoints(bg)
        -- Enlarge the clipping frame, not the illustration. TRP3's Fill
        -- layout then crops the parchment at its original aspect ratio.
        bg:ClearAllPoints()
        bg:SetPoint("TOPRIGHT", fills[window], "TOPRIGHT")
        bg:SetPoint("BOTTOMRIGHT", fills[window], "BOTTOMRIGHT")
        bg:SetPoint("LEFT", menu.ScrollBar or menu, "RIGHT")
    end

    -- Extended calls this after painting the current item's quality border.
    -- Reuse that colour rather than interpreting Extended item classes ourselves.
    local slotStyles = {}
    local function PaintSlotBorder(slot)
        if not enabled then return end
        local profile = FlareUI and FlareUI.db and FlareUI.db.profile
        local db = profile and profile.tweaks
        local style, original = slotStyles[slot], slot.IconBorder
        local heavy = db and db.bagThickBorders or false
        local border = heavy and thick or thin
        local edge = edges[slot]
        if not border or (db and db.bagSkinSlots == false) then
            if edge and edge:IsShown() then edge:Hide() end
            if original and native[original] ~= nil then
                original:SetAlpha(native[original])
                native[original] = nil
            end
            return
        end
        if style.heavy ~= heavy then
            local size, outset = heavy and 16 or 8, heavy and 2 or 3
            if edge then edge:SetBackdrop({ edgeFile = border, edgeSize = size })
            else edge = Edge(slot, size, border) end
            edge:ClearAllPoints()
            edge:SetPoint("TOPLEFT", slot.bkg, "TOPLEFT", -outset, outset)
            edge:SetPoint("BOTTOMRIGHT", slot.bkg, "BOTTOMRIGHT", outset, -outset)
            style.heavy, style.r = heavy, nil
        end
        local r, g, b = 0.65, 0.49, 0.27
        if original then
            if (not db or db.bagRarity ~= false) and original:IsShown() then r, g, b = original:GetVertexColor() end
            Mute(original)
        end
        if style.r ~= r or style.g ~= g or style.b ~= b then
            edge:SetBackdropBorderColor(r, g, b, 1)
            style.r, style.g, style.b = r, g, b
        end
        if not edge:IsShown() then edge:Show() end
    end

    local inventoryFill, inventoryFillPoints
    local function StyleInventoryPage(page)
        local panel = page.Main
        if not panel or panel:IsForbidden() then return end
        if panel.Model and panel.InsetBorderLeft then
            -- TRP3_InnerFrame gives its top and bottom textures the same key.
            -- Both are on BORDER/-5; the dark fill is on BACKGROUND.
            for _, region in ipairs({ panel:GetRegions() }) do
                local layer, sublevel = region:GetDrawLayer()
                if layer == "BORDER" and sublevel == -5 then
                    Mute(region)
                elseif layer == "BACKGROUND" and not inventoryFill and region:IsObjectType("Texture") then
                    -- FlareUI's 8-unit Thin edge leaves the outer corners clear.
                    inventoryFill, inventoryFillPoints = region, SavePoints(region)
                    region:ClearAllPoints()
                    region:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -4)
                    region:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -4, 4)
                end
            end
            Edge(panel, 8, thin)
        end
        local slots = panel.slots
        if type(slots) ~= "table" then return end
        local hasSlotArt = C_Texture and C_Texture.GetAtlasInfo("bags-item-slot64")
        for _, slot in ipairs(slots) do
            local bg = slot.bkg
            if bg and not slot:IsForbidden() and not bg:IsForbidden() then
                if hasSlotArt then
                    if not fills[slot] then
                        local fill = slot:CreateTexture(nil, "BACKGROUND", nil, -1)
                        fill:SetAtlas("bags-item-slot64")
                        fill:SetAllPoints(bg)
                        fills[slot] = fill
                    end
                    Mute(bg)
                    fills[slot]:Show()
                end
                -- Only replace Extended's border if we can follow item swaps.
                if not slotStyles[slot] and type(slot.additionalOnUpdateHandler) == "function" then
                    hooksecurefunc(slot, "additionalOnUpdateHandler", PaintSlotBorder)
                    slotStyles[slot] = {}
                end
                if slotStyles[slot] then PaintSlotBorder(slot) end
            end
        end
    end

    -- TRP3_ActionButton has no mixin. Match the released template's owners
    -- rather than the red texture sheet, which also contains the edit pencil.
    local menuFaces, watchedLists = {}, {}
    local menuAtlas = "common-dropdown-a-button"
    local menuStates = { Normal = "", Highlight = "-hover", Pushed = "-pressed", Disabled = "-disabled" }
    local hasMenuFace = C_Texture and C_Texture.GetAtlasInfo(menuAtlas)
    local function StyleAction(owner)
        if not enabled or not hasMenuFace then return end
        local b
        if HasMethod(owner, TRP3_ProfileManagerListElementMixin, "SetMenuButtonCallback") then
            b = owner.MenuButton
        elseif owner.Actions and (owner.Actions == TRP3_RegisterListHeaderActions or
            HasMethod(owner.Actions, TRP3_RelationsListActionButtonMixin, "OnMouseDown")) then
            b = owner.Actions
        elseif HasMethod(owner, TRP3_ModuleManagerListElementMixin, "Init") then
            b = owner.Action
        elseif TRP3_QuestLogPage and owner == TRP3_QuestLogPage.navBar then
            b = owner.action
        elseif TRP3_RegisterCharact_Edit_CharactPanel_Container and owner:GetParent() == TRP3_RegisterCharact_Edit_CharactPanel_Container then
            b = owner.Action or owner.ActionButton
        end
        if not b or b:IsForbidden() then return end
        -- TRP3 opens the menu on mouse-down. The menu can receive mouse-up,
        -- so let the native button switch textures rather than latching an atlas.
        local skin = menuFaces[b]
        if not skin then
            skin = { original = {} }
            menuFaces[b] = skin
            for state, suffix in pairs(menuStates) do
                local tex = b:CreateTexture(nil, state == "Highlight" and "HIGHLIGHT" or "ARTWORK")
                tex:SetAtlas(menuAtlas .. suffix)
                tex:SetAllPoints(b)
                skin[state] = tex
            end
        end
        for state in pairs(menuStates) do
            local current = b["Get" .. state .. "Texture"](b)
            if current ~= skin[state] then
                skin.original[state] = current
                b["Set" .. state .. "Texture"](b, skin[state])
            end
        end
    end

    local function Visit(frame)
        StyleAction(frame)
        local list = frame.ScrollBox
        if list and list.ForEachFrame and not watchedLists[list] and ScrollUtil and ScrollUtil.AddInitializedFrameCallback then
            watchedLists[list] = true
            ScrollUtil.AddInitializedFrameCallback(list, function(_, row)
                if not enabled or row:IsForbidden() then return end
                StyleAction(row)
                if HasMethod(row, TRP3_ProfileManagerListElementMixin, "SetMenuButtonCallback")
                    and row.BindButton and not row.BindButton:IsForbidden() then Visit(row.BindButton) end
            end, window)
        end
        -- The editor creates extra-information and trait rows after opening.
        if frame == TRP3_RegisterCharact_Edit_CharactPanel_Scroll and not watchedLists[frame] then
            watchedLists[frame] = true
            local function PaintEditRows()
                if enabled and TRP3_RegisterCharact_Edit_CharactPanel_Container then
                    for _, row in ipairs({ TRP3_RegisterCharact_Edit_CharactPanel_Container:GetChildren() }) do StyleAction(row) end
                end
            end
            frame:HookScript("OnScrollRangeChanged", PaintEditRows)
            frame:HookScript("OnShow", function() C_Timer.After(0, PaintEditRows) end)
        elseif frame == TRP3_RegisterAbout_AboutPanel_Edit and not watchedLists[frame] then
            -- TRP3 re-shows the inner editor after creating Template 2 sections.
            watchedLists[frame] = true
            frame:HookScript("OnShow", function()
                local container = TRP3_RegisterAbout_Edit_Template2_Container
                if enabled and container and not container:IsForbidden() then Visit(container) end
            end)
        end
        -- Reveal the window's continuous stone. The page owns a dedicated illustration frame; its
        -- texture need not be loaded or report a file path when PAGE_OPENED fires.
        local bg = frame.Background
        if bg and bg.GetResizeRegions and not bg:IsForbidden() and IsUtilityPage(frame) then
            Mute(bg)
        end
        if frame.scrollBarTemplate == "MinimalScrollBar" and frame:IsObjectType("ScrollFrame") then
            local bar = frame.ScrollBar
            if bar and not bar:IsForbidden() and not scrollScales[bar] then
                scrollScales[bar] = bar:GetScale()
                bar:SetScale(0.7)
            end
        elseif frame == TRP3_Dashboard then
            FitDashboard(frame.Background)
        elseif frame == TRP3_InventoryPage then
            StyleInventoryPage(frame)
        elseif frame == TRP3_QuestLogPage then
            PanelRim(frame)
        elseif frame == TRP3_RegisterCharact then
            PanelRim(frame)
        elseif HasMethod(frame, TRP3_GroupBoxMixin, "GetTitleWidth") and frame.Header and frame.Header.Text then
            PanelRim(frame)
            PanelRim(frame.Header)
            Fill(frame.Header, frame.Header.Center, false, 0.94)
            local title = frame.Header.Text
            if not titleColors[title] then titleColors[title] = { title:GetTextColor() } end
            title:SetTextColor(1, 0.82, 0)
            -- Only the fixed name boxes get a body fill. Other centers may be
            -- repainted from the viewed profile while the skin is enabled.
            if frame == TRP3_RegisterCharact_NamePanel or frame == TRP3_RegisterCharact_Edit_NamePanel then
                Fill(frame, frame.Center, false, 0.40)
            end
        elseif HasMethod(frame, TRP3_DropdownButtonMixin, "SetupMenu") and frame.Button then
            local b = frame.Button
            if not b:IsForbidden() and b.Background and b.Arrow and b.Text and b.OnButtonStateChanged and b.IsMenuOpen and b.IsDown then
                StylePlate(b, "dropdown")
            end
            return -- the inner button is already handled by the wrapper
        elseif ((plates[frame] and plates[frame].kind == "tab") or HasMethod(frame, TRP3_TabButtonMixin, "SetTabState"))
            and frame.Text and frame.Icon and frame.MiddleActive then
            StylePlate(frame, "tab")
        elseif controls[frame] or (frame:IsObjectType("Button") and HasMethod(frame, TRP3_CategoryButtonArtMixin, "SetVisualState")) then
            StyleCategory(frame)
        elseif frame:IsObjectType("Button") and (
            HasMethod(frame, TRP3_RedButtonMixin, "UpdateVisualState") or HasMethod(frame, UIPanelButtonMixin, "OnEnter")) then
            if frame:GetFontString() then StylePlate(frame, "button") end
        end
        for _, child in ipairs({ frame:GetChildren() }) do
            if not (child.IsForbidden and child:IsForbidden()) and child ~= edges[frame] then Visit(child) end
        end
    end

    local function SetArrow(frame, direction)
        local control = controls[frame]
        if direction then
            if not control.arrow then
                local arrow = frame:CreateTexture(nil, "OVERLAY")
                arrow:SetTexture(chevron)
                arrow:SetSize(14, 14)
                arrow:SetPoint("LEFT", 8, 0)
                control.arrow = arrow
            end
            control.arrow:SetRotation(direction == "open" and 0 or math.pi / 2)
            control.arrow:Show()
        elseif control.arrow and control.arrow:IsShown() then
            control.arrow:Hide()
        end
    end

    local RefreshSidebar
    local layoutPass = CreateFrame("Frame", nil, menu)
    layoutPass:Hide()
    -- OnUpdate runs before this visible frame is drawn. A zero-delay timer
    -- can leave the freshly rebuilt rows at TRP3's anchors for one paint.
    layoutPass:SetScript("OnUpdate", function() RefreshSidebar() end)
    local function QueueSidebar()
        if enabled then layoutPass:Show() end
    end

    -- Native rows anchor to the scroll child. Use a distinct, coincident anchor
    -- for our layout so even identical native/styled offsets are unambiguous.
    local rowAnchor
    local closeAllLayout = {}
    local nav = TRP3_API.navigation and TRP3_API.navigation.menu
    local canLayout = TRP3_MainFrameMenuContainer and nav and type(nav.rebuildMenu) == "function"
        and type(nav.isMenuRegistered) == "function" and type(nav.getMenuItem) == "function"

    local function RestoreCategory(frame, control)
        control.fill:Hide()
        control.hover:Hide()
        control.bar:Hide()
        SetArrow(frame, nil)
        if not control.sidebar then return end
        -- The current pool slot's font can differ from the one initially skinned.
        local font = frame:IsEnabled() and frame:GetNormalFontObject() or frame:GetDisabledFontObject()
        frame.Text:SetTextColor(font:GetTextColor())
        frame:SetHeight(control.nativeHeight)
        RestorePoints(frame.Text, control.textPoints)
        RestorePoints(frame.Icon, control.iconPoints)
        if control.closePoints then RestorePoints(frame.CloseButton, control.closePoints) end
        control.sidebar, control.section, control.closePoints = nil, nil, nil
    end

    RefreshSidebar = function()
        layoutPass:Hide()
        if not enabled then return end
        Visit(menu)
        local container = TRP3_MainFrameMenuContainer
        if not canLayout then return end
        if not rowAnchor then
            rowAnchor = CreateFrame("Frame", nil, container)
            rowAnchor:SetAllPoints(container)
            rowAnchor:Hide()
        end
        local parents, rows = {}, {}
        local rootInset
        local function MarkParent(id)
            if id and nav.isMenuRegistered(id) then parents[nav.getMenuItem(id).text] = true end
        end
        -- These sections have temporary profile pages rather than permanent children.
        MarkParent(nav.id and nav.id.COMPANIONS_MAIN)
        MarkParent(TRP3_API.register and TRP3_API.register.MENU_LIST_ID)
        for _, id in ipairs(sectionChildren) do
            if nav.isMenuRegistered(id) then
                local child = nav.getMenuItem(id)
                if not child.hidden then MarkParent(child.isChildOf) end
            end
        end
        for _, row in ipairs({ container:GetChildren() }) do
            local control = controls[row]
            if control and control.bar then
                if not control.watch then
                    row:HookScript("OnShow", QueueSidebar)
                    control.watch = true
                end
                if row:IsShown() then
                    local _, relative, _, x, y = row:GetPointByName("TOPLEFT")
                    if y and relative ~= rowAnchor then control.nativeX, control.nativeY = x, y end
                    if y and control.nativeY then
                        rootInset = math.min(rootInset or control.nativeX, control.nativeX)
                        rows[#rows + 1] = { frame = row, y = control.nativeY, inset = control.nativeX }
                    else
                        SetArrow(row, nil)
                    end
                end
            end
        end
        local all = TRP3_MainFrameMenuButtonCloseAll
        if all and all:IsShown() then
            local _, relative, _, _, y = all:GetPointByName("LEFT")
            if y and relative ~= rowAnchor then closeAllLayout.y = y end
            if y and closeAllLayout.y then rows[#rows + 1] = { frame = all, y = closeAllLayout.y } end
        end
        -- TRP3 doesn't expose a menu ID on a pooled row. Its root entries
        -- share the shallowest native indent; sort by native visual order.
        table.sort(rows, function(a, b) return a.y > b.y end)
        local right = menu:GetWidth() - container:GetWidth() - 6
        local rootLabels = {}
        for _, row in ipairs(rows) do
            if row.frame ~= all and row.inset == rootInset then
                local label = row.frame:GetText()
                if label then rootLabels[label] = (rootLabels[label] or 0) + 1 end
            end
        end
        for i, row in ipairs(rows) do
            local nextRow = rows[i + 1]
            local frame = row.frame
            local y = -8 - (i - 1) * 30
            if frame == all then
                all:SetPoint("LEFT", rowAnchor, "LEFT", 6, y - 15)
                all:SetPoint("RIGHT", rowAnchor, "RIGHT", right, y - 15)
            else
                local root = row.inset == rootInset
                local open = nextRow and nextRow.frame ~= all and nextRow.inset ~= rootInset
                local label = frame:GetText()
                local direction = root and (open and "open" or parents[label] and rootLabels[label] == 1 and "closed")
                SetArrow(frame, direction)
                local control = controls[frame]
                if not control.sidebar then
                    control.nativeHeight = frame:GetHeight()
                    control.textPoints = SavePoints(frame.Text)
                    control.iconPoints = SavePoints(frame.Icon)
                end
                control.sidebar, control.section = true, direction
                control.paint()
                frame:SetPoint("TOPLEFT", rowAnchor, "TOPLEFT", 6, y)
                frame:SetPoint("TOPRIGHT", rowAnchor, "TOPRIGHT", right, y)
                frame:SetHeight(30)
                local inset = direction and 26 or root and 10 or 20
                if frame.Icon:IsShown() then
                    frame.Icon:SetPoint("LEFT", inset, 0)
                    inset = inset + 20
                end
                local close = frame.CloseButton
                if close then
                    if not control.closePoints then control.closePoints = SavePoints(close) end
                    close:ClearAllPoints()
                    close:SetPoint("RIGHT", -4, 0)
                end
                frame.Text:SetPoint("LEFT", inset, 0)
                frame.Text:SetPoint("RIGHT", close and close:IsShown() and -26 or -6, 0)
                frame:SetJustifyH("LEFT")
            end
        end
    end

    local panelClose
    local resizeArt, originalArt = {}, {}
    local resizeAtlases = { Normal = "RedButton-Expand", Pushed = "RedButton-Expand-Pressed",
        Disabled = "RedButton-Expand-Disabled", Highlight = "RedButton-Highlight" }
    local hasCorners = C_Texture ~= nil
    for _, atlas in pairs(resizeAtlases) do
        hasCorners = hasCorners and C_Texture.GetAtlasInfo(atlas) ~= nil
    end
    local function Refresh()
        if not enabled then return end
        Mute(window.Backdrop)
        Mute(menu.SidebarWoodBorder)
        Fill(window, window.Background, true)
        Fill(menu, menu.Background, false, 0.40)
        local windowEdge = WindowBorder()
        KeepAbove(window.CloseButton, windowEdge)
        KeepAbove(window.ResizeButton, windowEdge)
        if hasCorners and window.CloseButton and window.ResizeButton then
            local close = window.CloseButton
            if not panelClose then
                panelClose = CreateFrame("Button", nil, close, "UIPanelCloseButton")
                panelClose:SetAllPoints(close)
                -- The template normally hides its parent. Route this click
                -- through TRP3 instead so its window navigation still runs.
                panelClose:SetScript("OnClick", function() close:Click() end)
            end
            Mute(close:GetNormalTexture())
            Mute(close:GetPushedTexture())
            Mute(close:GetHighlightTexture())
            Mute(close:GetDisabledTexture())
            panelClose:Show()
            local resize = window.ResizeButton
            for state, atlas in pairs(resizeAtlases) do
                if not resizeArt[state] then
                    local tex = resize:CreateTexture(nil, state == "Highlight" and "HIGHLIGHT" or "ARTWORK")
                    tex:SetAtlas(atlas)
                    tex:SetRotation(-math.pi / 2) -- point toward the bottom-right resize corner
                    tex:SetAllPoints(resize)
                    if state == "Highlight" then tex:SetBlendMode("ADD") end
                    resizeArt[state] = tex
                end
                local current = resize["Get" .. state .. "Texture"](resize)
                if current ~= resizeArt[state] then
                    originalArt[state] = current
                    resize["Set" .. state .. "Texture"](resize, resizeArt[state])
                end
            end
        end
        -- The scroll child clips at the menu bounds. Put the horizontal rim
        -- outside that viewport so rows disappear before crossing the artwork.
        local sidebarEdge = edges[menu]
        if sidebarEdge then
            sidebarEdge:Show()
        else
            sidebarEdge = Edge(menu, 8, thin)
            sidebarEdge:ClearAllPoints()
            sidebarEdge:SetPoint("TOPLEFT", menu, "TOPLEFT", 0, 8)
            sidebarEdge:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", 0, -8)
            if fills[menu] then
                fills[menu]:SetPoint("TOPLEFT", sidebarEdge, "TOPLEFT", 4, -4)
                fills[menu]:SetPoint("BOTTOMRIGHT", sidebarEdge, "BOTTOMRIGHT", -4, 4)
            end
        end
        -- TRP3 deliberately overlaps the bottom edge with its tutorial button.
        KeepAbove(TRP3_MainTutorialButton, sidebarEdge)
        KeepAbove(TRP3_MainTutorialButton, windowEdge)
        RefreshSidebar()
        -- PAGE_OPENED follows TRP3's lazy page creation and post-show setup.
        for _, page in ipairs({ pages:GetChildren() }) do
            if not page:IsForbidden() and page:IsShown() then Visit(page) end
        end
    end
    window:HookScript("OnShow", Refresh)
    -- TRP3 also rebuilds its pool without opening a page (e.g. close a
    -- directory entry). Coalesce row shows until the new anchors are in place.
    if canLayout then
        hooksecurefunc(nav, "rebuildMenu", RefreshSidebar)
    end
    TRP3_API.RegisterCallback(TRP3_Addon, TRP3_Addon.Events.PAGE_OPENED, Refresh)
    config.registerHandler(key, function(_, on)
        enabled = on
        if on then Refresh(); return end
        layoutPass:Hide()
        if dashboardAnchors then
            RestorePoints(TRP3_Dashboard.Background, dashboardAnchors)
            dashboardAnchors = nil
        end
        if inventoryFill then
            RestorePoints(inventoryFill, inventoryFillPoints)
            inventoryFill, inventoryFillPoints = nil, nil
        end
        if panelClose then panelClose:Hide() end
        for state, tex in pairs(resizeArt) do
            local resize = window.ResizeButton
            RestoreTexture(resize, state, tex, originalArt[state])
            originalArt[state] = nil
        end
        if bronze then bronze:Hide() end
        for button, level in pairs(buttonLevels) do
            button:SetFrameLevel(level)
            buttonLevels[button] = nil
        end
        for _, edge in pairs(edges) do edge:Hide() end
        for _, fill in pairs(fills) do fill:Hide() end
        for b, skin in pairs(menuFaces) do
            for state in pairs(menuStates) do
                RestoreTexture(b, state, skin[state], skin.original[state])
            end
        end
        for bar, scale in pairs(scrollScales) do
            bar:SetScale(scale)
            scrollScales[bar] = nil
        end
        for title, color in pairs(titleColors) do
            title:SetTextColor(unpack(color))
            titleColors[title] = nil
        end
        for button, plate in pairs(plates) do RestorePlate(button, plate) end
        for frame, control in pairs(controls) do RestoreCategory(frame, control) end
        -- Reacquire the pooled rows with their current native anchors, text
        -- alignment, and close-all placement (not a stale layout snapshot).
        if canLayout then nav.rebuildMenu() end
        for region, alpha in pairs(native) do
            region:SetAlpha(alpha)
            native[region] = nil
        end
    end)
    elements[#elements + 1] = { inherit = "TRP3_ConfigCheck", configKey = key, title = "Use FlareUI Styling",
        help = "Style the main window, sidebar, page buttons, tabs and group panels. Turn off to restore TRP3's appearance." }
    Refresh()
end
