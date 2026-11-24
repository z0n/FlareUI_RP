local ns = {}
assert(loadfile("MainWindow.lua"))("FlareUI_RP", ns)
local noop = function() end
local function Frame(parent)
    local f = { children = {}, alpha = 0.7, shown = true, SetAllPoints = noop, SetColorTexture = noop,
        SetBackdrop = noop, SetBackdropBorderColor = noop, EnableMouse = noop, HookScript = noop,
        SetTexture = noop, SetVertexColor = noop, SetGradient = noop, SetWidth = noop, SetPoint = noop,
        SetHorizTile = noop, SetVertTile = noop, ClearAllPoints = noop }
    function f:GetWidth() return self.w end
    local anchors = {}
    function f:SetPoint(p, relative, point, x, y)
        if type(relative) == "number" then x, y, relative, point = relative, point, parent, p end
        for i, anchor in ipairs(anchors) do
            if anchor[1] == p then table.remove(anchors, i); break end
        end
        anchors[#anchors + 1] = {p, relative, point, x or 0, y or 0}
    end
    function f:GetNumPoints() return #anchors end
    function f:GetPoint(i) return unpack(anchors[i], 1, 5) end
    function f:ClearAllPoints() anchors = {} end
    function f:GetName() return self.name end
    function f:GetFrameLevel() return self.level or (parent and parent:GetFrameLevel() + 1) or 0 end
    function f:SetFrameLevel(level) self.level = level end
    function f:GetHeight() return self.h end
    function f:GetScale() return self.scale or 1 end
    function f:SetScale(scale) self.scale = scale end
    function f:SetHeight(h) self.h = h end
    function f:SetJustifyH(v) self.justify = v end
    function f:SetAtlas(atlas) self.atlas = atlas end
    function f:IsEnabled() return not self.disabled end
    function f:IsMouseOver() return self.over end
    function f:SetScript(event, fn) self[event] = fn end
    function f:HookScript(event, fn) self[event] = fn end
    function f:SetSize(w,h) self.w,self.h = w,h end
    function f:SetRotation(angle) self.angle = angle end
    function f:SetAllPoints(region) self.allPoints = region end
    function f:SetShown(shown) self.shown = shown end
    function f:GetAlpha() return self.alpha end
    function f:SetAlpha(a) self.alpha = a end
    function f:IsShown() return self.shown end
    function f:Show() self.shown = true end
    function f:Hide() self.shown = false end
    function f:IsForbidden() return false end
    function f:IsObjectType(t) return self.kind == t end
    function f:GetChildren() return unpack(self.children) end
    function f:GetButtonState() return self.state or "NORMAL" end
    function f:CreateTexture(_, layer)
        self.textures = self.textures or {}
        if self.textures[layer] then layer = layer .. "2" end
        assert(not self.textures[layer], "duplicate skin texture")
        local texture = Frame()
        self.textures[layer] = texture
        function texture:SetColorTexture(r) self.red = r end
        return texture
    end
    if parent then table.insert(parent.children, f) end
    return f
end
local win, menu, pages = Frame(), Frame(), Frame()
local function TextureButton(parent)
    local b = Frame(parent)
    b.art = Frame()
    for _, state in ipairs({"Normal", "Pushed", "Disabled", "Highlight"}) do
        b[state] = b.art
        b["Get" .. state .. "Texture"] = function(self) return self[state] end
        b["Set" .. state .. "Texture"] = function(self, tex) self[state] = assert(tex) end
        b["Clear" .. state .. "Texture"] = function(self) self[state] = nil end
    end
    function b:CreateTexture()
        local tex = Frame()
        tex.SetBlendMode = noop
        return tex
    end
    return b
end
win.CloseButton = TextureButton(win)
menu.kind, menu.scrollBarTemplate, menu.ScrollBar = "ScrollFrame", "MinimalScrollBar", Frame(menu)
win.Backdrop, win.Background, menu.Background, menu.SidebarWoodBorder = Frame(), Frame(), Frame(), Frame()
TRP3_MainFrame, TRP3_MainFrameMenuScroll, TRP3_MainFramePageContainer = win, menu, pages
TRP3_TabButtonMixin = { SetTabState = function(self, state)
    self.MiddleActive.shown = state == "SELECTED"
    local y = self.MiddleActive.shown and -9 or -6
    self.Text:SetPoint("LEFT", self, "LEFT", 26, y)
    self.Text:SetPoint("RIGHT", self, "RIGHT", -10, y)
    self.Icon:SetPoint("LEFT", self, "LEFT", 10, y)
end }
CreateColor = function(...) return {...} end
TRP3_CategoryButtonArtMixin = { SetVisualState = noop }
function hooksecurefunc(frame, key, hook)
    local original = assert(frame[key])
    frame[key] = function(...) original(...); hook(...) end
end
local container = Frame(menu)
TRP3_MainTutorialButton = Frame(menu)
TRP3_MainTutorialButton:Hide()
local tutorialLevel = TRP3_MainTutorialButton:GetFrameLevel()
menu.w, container.w = 175, 195
C_Texture = { GetAtlasInfo = function() return true end }
TRP3_MainFrameMenuContainer = container
local category = Frame(container)
category.kind, category.SetVisualState = "Button", noop
category.BorderCenter, category.HighlightBorderEdgeLeft, category.Icon = Frame(), Frame(), Frame()
local function MenuRow(row, text, x, y)
    row.kind, row.SetVisualState, row.Text = "Button", noop, Frame()
    row.Text.SetTextColor = function(self, r, g, b) self.r, self.g, self.b = r, g, b end
    row.GetNormalFontObject = function() return { GetTextColor = function() return 1, 1, 1 end } end
    row.GetDisabledFontObject = function() return { GetTextColor = function() return 0.9, 0.9, 0.9 end } end
    row.Icon = row.Icon or Frame()
    row.Icon:Hide()
    row.GetText = function() return text end
    row.h = 34
    row.points = { TOPLEFT = {x,y,container,"TOPLEFT"} }
    row.SetPoint = function(self, p, relative, point, a,b)
        if type(relative) == "number" then a,b,relative,point = relative,point,container,p end
        self.points[p] = {a,b,relative,point}
    end
    row.GetPointByName = function(self,p)
        local value = self.points[p]
        if value then return p, value[3], value[4], value[1], value[2] end
    end
    row.resetLayout = function(self)
        self:SetPoint("TOPLEFT", x, y)
        self:SetPoint("TOPRIGHT", -20, y)
        self:SetJustifyH(x == 6 and "LEFT" or "RIGHT")
    end
end
MenuRow(category, "Profiles", 27, -44)
category.Text:SetPoint("RIGHT", category, "RIGHT", -19, 2)
local character = Frame(container)
MenuRow(character, "Character", 6, -10)
local toggle, opened
TRP3_Addon = { Events = { PAGE_OPENED = "PAGE_OPENED" } }
TRP3_API = { RegisterCallback = function(_, event, fn) assert(event == "PAGE_OPENED"); opened = fn end }
local items = { main_11_profiles = { isChildOf = "character" }, character = { text = "Character" } }
TRP3_API.navigation = { menu = { rebuildMenu = function() character:resetLayout(); category:resetLayout() end,
    isMenuRegistered = function(id) return items[id] ~= nil end,
    getMenuItem = function(id) return items[id] end } }
CreateFrame = function(_, _, parent, template)
    local f = Frame(parent)
    f.template = template
    return f
end
LibStub = function() return { Fetch = function() return "border" end } end
ns.StartMainWindow({ registerConfigKey = noop, getValue = function() return true end,
    registerHandler = function(_, fn) toggle = fn end }, {})
assert(win.Backdrop.alpha == 0 and menu.SidebarWoodBorder.alpha == 0)
assert(win.CloseButton.art.alpha == 0.7 and #win.CloseButton.children == 0)
win.ResizeButton = TextureButton(win)
opened()
assert(win.CloseButton.art.alpha == 0 and win.ResizeButton.Normal.atlas == "RedButton-Expand")
local panelClose = win.CloseButton.children[1]
assert(panelClose.template == "UIPanelCloseButton" and panelClose:IsShown())
assert(win.ResizeButton.Pushed.atlas == "RedButton-Expand-Pressed" and win.ResizeButton.Highlight.atlas == "RedButton-Highlight")
local clicks = 0
win.CloseButton.Click = function() clicks = clicks + 1 end
panelClose:OnClick()
assert(clicks == 1)
local bronze
for _, child in ipairs(win.children) do
    if child.textures and child.textures.BORDER and child.textures.BORDER.atlas == "heavybronze-frame-basic" then bronze = child end
end
assert(bronze and bronze:GetFrameLevel() > pages:GetFrameLevel())
local sidebarEdge
for _, child in ipairs(menu.children) do
    if child.template == "BackdropTemplate" then sidebarEdge = child end
end
local tp, tr, _, _, top = sidebarEdge:GetPoint(1)
local bp, br, _, _, bottom = sidebarEdge:GetPoint(2)
assert(tp == "TOPLEFT" and bp == "BOTTOMRIGHT" and tr == menu and br == menu and top >= 8 and bottom <= -8)
assert(not TRP3_MainTutorialButton:IsShown(), "TRP3 owns tutorial visibility")
TRP3_MainTutorialButton:Show()
assert(TRP3_MainTutorialButton:GetFrameLevel() > math.max(bronze:GetFrameLevel(), sidebarEdge:GetFrameLevel()))
assert(win.CloseButton:GetFrameLevel() > bronze:GetFrameLevel() and win.ResizeButton:GetFrameLevel() > bronze:GetFrameLevel())
assert(character.justify == "LEFT" and category.justify == "LEFT" and category.h == 30)
assert(character.Text.r == 0.66 and category.Text.r == 0.85)
assert(category.points.TOPLEFT[1] == 6 and category.points.TOPLEFT[2] == -38 and category.points.TOPRIGHT[1] == -26)
-- Internal rebuilds call a local function, then show the reused buttons.
-- The native positions must be gone by the next paint, even without PAGE_OPENED.
local pass
for _, f in ipairs(menu.children) do if f.OnUpdate then pass = f end end
category:resetLayout()
category.OnShow(category)
assert(pass:IsShown())
pass:OnUpdate()
assert(category.justify == "LEFT" and category.points.TOPLEFT[1] == 6 and not pass:IsShown())
-- A page refresh before paint consumes the pending pass too.
category.OnShow(category)
opened()
assert(not pass:IsShown())
local arrow = character.textures.OVERLAY
local companions = Frame(container)
MenuRow(companions, "Begleiter", 6, -78)
TRP3_API.navigation.menu.id = { COMPANIONS_MAIN = "companion-root" }
items["companion-root"] = { text = "Begleiter" }
opened()
local companionArrow = companions.textures.OVERLAY
assert(companionArrow:IsShown() and companionArrow.angle == math.pi / 2)
local pet = Frame(container)
MenuRow(pet, "Wolf", 39, -112)
opened()
assert(companionArrow.angle == 0)
pet:Hide()
opened()
assert(companionArrow:IsShown() and companionArrow.angle == math.pi / 2 and companions.Text.r == 0.66)
local directory = Frame(container)
MenuRow(directory, "Verzeichnis", 6, -146)
TRP3_API.register = { MENU_LIST_ID = "directory-root" }
items["directory-root"] = { text = "Verzeichnis" }
opened()
local directoryArrow = directory.textures.OVERLAY
assert(directoryArrow:IsShown() and directoryArrow.angle == math.pi / 2)
local entry = Frame(container)
MenuRow(entry, "Example profile", 39, -180)
opened()
assert(directoryArrow.angle == 0 and companionArrow.angle == math.pi / 2)
entry:Hide()
opened()
assert(directoryArrow:IsShown() and directoryArrow.angle == math.pi / 2 and directory.Text.r == 0.66)
assert(arrow:IsShown() and arrow.angle == 0 and not category.textures.OVERLAY)
assert(category.textures.HIGHLIGHT.allPoints == category.textures.BACKGROUND)
category:Hide()
opened()
assert(arrow:IsShown() and arrow.angle == math.pi / 2)
category:Show()
opened()
assert(arrow.angle == 0)
-- Same pool slot becomes a closeable child; another slot becomes the parent.
category.GetText = function() return "Character" end
category:SetPoint("TOPLEFT", 6, -10)
character.GetText = function() return "Temporary profile" end
character:SetPoint("TOPLEFT", 39, -44)
character.CloseButton = Frame()
opened()
assert(not arrow:IsShown() and category.textures.OVERLAY.angle == 0)
assert(character.Text.r == 0.85 and category.Text.r == 0.66)
assert(character.points.TOPLEFT[2] == -38 and category.points.TOPLEFT[2] == -8)
category.GetText = function() return "Profiles" end
character.GetText = function() return "Character" end
character.CloseButton:Hide()
character:resetLayout()
category:resetLayout()
opened()
assert(arrow:IsShown() and not category.textures.OVERLAY:IsShown())
local page = Frame(pages)
TRP3_QuestLogPage = Frame(pages)
local navBar = Frame(TRP3_QuestLogPage)
TRP3_QuestLogPage.navBar = navBar
TRP3_QuestLogPage.TopEdge, navBar.InsetBorderLeft = Frame(), Frame()
local questDetails = Frame(TRP3_QuestLogPage)
questDetails.Background = Frame()
navBar.action, navBar.home = TextureButton(navBar), TextureButton(navBar)
opened()
local pageTrim = TRP3_QuestLogPage.children[#TRP3_QuestLogPage.children]
assert(pageTrim.template == "BackdropTemplate" and #navBar.children == 2, "keep the native breadcrumb without a second rim")
assert(TRP3_QuestLogPage.TopEdge.alpha == 0 and navBar.InsetBorderLeft.alpha == 0.7 and questDetails.Background.alpha == 0.7)
assert(navBar.action.Normal.atlas == "common-dropdown-a-button" and navBar.home.Normal == navBar.home.art)
TRP3_QuestLogPage:Hide()
-- Extended may create its page after the skin starts.
TRP3_InventoryPage = Frame(pages)
local inventory = Frame(TRP3_InventoryPage)
TRP3_InventoryPage.Main = inventory
inventory.Model = Frame(inventory)
local panelFill, top, bottom = Frame(), Frame(), Frame()
panelFill.kind = "Texture"
panelFill:SetPoint("TOPLEFT", inventory, "TOPLEFT", 0, 0)
panelFill:SetPoint("BOTTOMRIGHT", inventory, "BOTTOMRIGHT", 0, 0)
local function CheckPanelInset(inset)
    assert(panelFill:GetNumPoints() == 2)
    for i, anchor in ipairs({"TOPLEFT", "BOTTOMRIGHT"}) do
        local p, parent, relative, x, y = panelFill:GetPoint(i)
        local offset = i == 1 and inset or -inset
        assert(p == anchor and parent == inventory and relative == anchor and x == offset and y == -offset)
    end
end
panelFill.GetDrawLayer = function() return "BACKGROUND", 0 end
top.GetDrawLayer = function() return "BORDER", -5 end
bottom.GetDrawLayer = top.GetDrawLayer
inventory.InsetBorderLeft = top
inventory.GetRegions = function() return panelFill, top, bottom end
local empty, equipped, otherSlot = Frame(inventory), Frame(inventory), Frame(inventory)
empty.bkg, equipped.bkg, otherSlot.bkg = Frame(), Frame(), Frame()
equipped.Icon, equipped.IconBorder = Frame(), Frame()
local bagSettings = {}
FlareUI = { db = { profile = { tweaks = bagSettings } } }
equipped.IconBorder.GetVertexColor = function() return 0.3, 0.4, 1 end
equipped.additionalOnUpdateHandler = noop
empty.IconBorder = Frame()
empty.IconBorder:Hide()
inventory.slots = { empty, equipped }
local getAtlas = C_Texture.GetAtlasInfo
C_Texture.GetAtlasInfo = function(atlas) return atlas ~= "bags-item-slot64" end
opened()
assert(empty.bkg.alpha == 0.7 and not empty.textures)
assert(equipped.bkg.alpha == 0.7 and not equipped.textures)
assert(equipped.children[1]:IsShown() and equipped.IconBorder.alpha == 0, "missing background atlas must not disable borders")
assert(top.alpha == 0 and bottom.alpha == 0 and panelFill.alpha == 0.7)
CheckPanelInset(4)
local panelEdge = inventory.children[#inventory.children]
assert(panelEdge.template == "BackdropTemplate" and panelEdge:IsShown())
C_Texture.GetAtlasInfo = getAtlas
opened()
local slotFill = empty.textures.BACKGROUND
empty.IconBorder:Show() -- An item arrives before Extended installs its update handler.
assert(empty.bkg.alpha == 0 and #empty.children == 0 and empty.IconBorder.alpha == 0.7,
    "background styling must preserve the live native border without an update hook")
empty.IconBorder.GetVertexColor = equipped.IconBorder.GetVertexColor
empty.additionalOnUpdateHandler = noop
opened()
assert(empty.IconBorder.alpha == 0, "a later page visit should pick up the update hook")
local slotEdge = empty.children[1]
assert(slotEdge.template == "BackdropTemplate" and slotEdge:IsShown() and #otherSlot.children == 0)
assert(slotFill.atlas == "bags-item-slot64" and slotFill.allPoints == empty.bkg and empty.bkg.alpha == 0)
assert(equipped.bkg.alpha == 0 and equipped.Icon.alpha == 0.7 and equipped.IconBorder.alpha == 0)
local itemEdge = equipped.children[1]
itemEdge.SetBackdrop = function(self, backdrop) self.size = backdrop.edgeSize end
itemEdge.SetBackdropBorderColor = function(self, r, g, b) self.rgb = {r,g,b} end
bagSettings.bagThickBorders = true
equipped:additionalOnUpdateHandler()
assert(itemEdge.size == 16 and itemEdge.rgb[3] == 1)
equipped.IconBorder:Hide() -- Extended repaints a slot after an item is removed.
equipped:additionalOnUpdateHandler()
assert(itemEdge.rgb[3] == 0.27)
equipped.IconBorder:Show()
bagSettings.bagRarity = false
equipped:additionalOnUpdateHandler()
assert(itemEdge.rgb[3] == 0.27)
bagSettings.bagSkinSlots = false
equipped:additionalOnUpdateHandler()
assert(not itemEdge:IsShown() and equipped.IconBorder.alpha == 0.7)
bagSettings.bagSkinSlots, bagSettings.bagThickBorders = true, false
equipped:additionalOnUpdateHandler()
assert(itemEdge:IsShown() and itemEdge.size == 8 and equipped.IconBorder.alpha == 0)
assert(otherSlot.bkg.alpha == 0.7 and not otherSlot.textures)
TRP3_Dashboard = Frame(pages)
local parchment = Frame(TRP3_Dashboard)
TRP3_Dashboard.Background = parchment
local anchors = {{"TOPLEFT", TRP3_Dashboard, "TOPLEFT", 0, 0}, {"BOTTOMRIGHT", TRP3_Dashboard, "BOTTOMRIGHT", 0, 0}}
function parchment:GetNumPoints() return #anchors end
function parchment:GetPoint(i) return unpack(anchors[i]) end
function parchment:ClearAllPoints() anchors = {} end
function parchment:SetPoint(...) anchors[#anchors + 1] = {...} end
opened()
assert(#anchors == 3 and anchors[1][2] == win.textures.BACKGROUND and anchors[3][2] == menu.ScrollBar)
local function IllustratedPage(path)
    local host = Frame(page)
    host.Background = Frame(host)
    local art = Frame()
    art.GetTexture = function() return path end
    host.Background.GetResizeRegions = function() return {art} end
    return host, art
end
local settingsPage, settingsArt = IllustratedPage("Interface/AddOns/totalRP3/Resources/UI/ui-frame-settings-background")
local profilesPage, profilesArt = IllustratedPage("Interface\\AddOns\\totalRP3\\Resources\\UI\\ui-frame-profiles-background.blp")
local parchmentPage, parchmentArt = IllustratedPage("Interface/AddOns/totalRP3/Resources/UI/ui-frame-parchment-background")
settingsPage.name = "TRP3_ConfigurationPage14"
TRP3_ProfileManagerListMixin = { SetElementInitializer = function() end }
profilesPage.SetElementInitializer = TRP3_ProfileManagerListMixin.SetElementInitializer
TRP3_RelationsListMixin = { GetTargetNameForRelation = function() end }
local relationsPage, relationsArt = IllustratedPage(nil)
relationsPage.GetTargetNameForRelation = TRP3_RelationsListMixin.GetTargetNameForRelation
local scroll, other = Frame(page), Frame(page)
scroll.kind, scroll.scrollBarTemplate, scroll.ScrollBar = "ScrollFrame", "MinimalScrollBar", Frame(scroll)
other.kind, other.scrollBarTemplate, other.ScrollBar = "ScrollFrame", "CustomScrollBar", Frame(other)
scroll.ScrollBar:SetScale(0.9)
scroll.ScrollBar:Hide()
opened()
opened()
assert(menu.ScrollBar:GetScale() == 0.7 and scroll.ScrollBar:GetScale() == 0.7 and not scroll.ScrollBar:IsShown())
assert(other.ScrollBar:GetScale() == 1)
TRP3_RegisterCharact = Frame(page)
TRP3_RegisterCharact.Background = Frame()
TRP3_GroupBoxMixin = { GetTitleWidth = function() return 150 end }
local function GroupBox()
    local box = Frame(TRP3_RegisterCharact)
    box.GetTitleWidth = TRP3_GroupBoxMixin.GetTitleWidth
    box.Center, box.TopEdge, box.Header = Frame(), Frame(), Frame(box)
    box.Header.Center, box.Header.Text = Frame(), Frame()
    local text = box.Header.Text
    text.color = {0.95, 0.95, 0.95, 0.8}
    function text:GetTextColor() return unpack(self.color) end
    function text:SetTextColor(...) self.color = {...} end
    return box
end
TRP3_RegisterCharact_NamePanel = GroupBox()
local edit = Frame(TRP3_RegisterCharact_NamePanel)
TRP3_RegisterCharact_NamePanel_EditButton = edit
edit.kind = "Button"
edit:SetSize(48, 48)
function edit:GetSize() return self.w, self.h end
for _, state in ipairs({"Normal", "Pushed", "Highlight"}) do
    edit[state] = Frame()
    edit["Get" .. state .. "Texture"] = function(self) return self[state] end
end
edit:Hide() -- TRP3 hides this button on someone else's profile.
local characteristics = GroupBox()
TRP3_RedButtonMixin = {} -- A renamed method must not match unrelated buttons.
UIPanelButtonMixin = { OnEnter = function() end }
local panelButton, lookalike = Frame(page), Frame(page)
TRP3_RegisterAbout_AboutPanel_Edit = Frame(page)
TRP3_RegisterAbout_Edit_Template2_Container = Frame(TRP3_RegisterAbout_AboutPanel_Edit)
local listPage = Frame(page)
listPage.ScrollBox = Frame(listPage)
listPage.ScrollBox.ForEachFrame = noop
ScrollUtil = { AddInitializedFrameCallback = function(list, callback, owner)
    assert(not list.initialize)
    list.initialize = function(row) callback(owner, row) end
end }
TRP3_ProfileManagerListElementMixin = { SetMenuButtonCallback = noop }
panelButton.kind, panelButton.OnEnter = "Button", UIPanelButtonMixin.OnEnter
panelButton.h = 22
panelButton.Middle, panelButton.highlight = Frame(), Frame()
panelButton.GetHighlightTexture = function(self) return self.highlight end
panelButton.GetFontString = function() return "ButtonText" end
for i, state in ipairs({"Normal", "Highlight", "Disabled"}) do
    panelButton[state] = "native" .. state
    panelButton["Get" .. state .. "FontObject"] = function(self) return self[state] end
    panelButton["Set" .. state .. "FontObject"] = function(self, value) self[state] = value end
    _G["FlareUI_PanelButtonSmall" .. ({"", "Hover", "Off"})[i]] = "flare" .. state
end
lookalike.kind, lookalike.Left, lookalike.Middle, lookalike.Right = "Button", {}, {}, {}
local tab, art = Frame(page), Frame(page)
local wrapper = Frame(page)
TRP3_DropdownButtonMixin = { SetupMenu = noop }
wrapper.SetupMenu = TRP3_DropdownButtonMixin.SetupMenu
local dd = Frame(wrapper)
wrapper.Button = dd
dd.Background, dd.Arrow, dd.Text = Frame(), Frame(), Frame()
dd.IsMenuOpen = function(self) return self.open end
dd.OnMenuOpened = function(self) self.open = true end
dd.OnMenuClosed = function(self) self.open = false end
dd.IsDown = function() return false end
dd.Text.SetTextColor = function(self, r, g, b) self.r, self.g, self.b = r, g, b end
dd.OnButtonStateChanged = function(self)
    local shade = self:IsEnabled() and 1 or 0.4
    self.Text:SetTextColor(shade, shade, shade)
end
dd.Text.justify = "LEFT"
dd.Text.GetJustifyH = function(self) return self.justify end
local points = {{"TOPRIGHT", dd.Arrow, "LEFT", 0, 0}, {"TOPLEFT", dd, "TOPLEFT", 8, -8}}
dd.Text.GetNumPoints = function() return #points end
dd.Text.GetPoint = function(_, i) return unpack(points[i]) end
dd.Text.ClearAllPoints = function() points = {} end
dd.Text.SetPoint = function(_, ...) points[#points + 1] = {...} end
local unrelated = Frame(page)
unrelated.Button = Frame(unrelated)
tab.kind, tab.SetTabState = "Button", TRP3_TabButtonMixin.SetTabState
tab.pushX, tab.pushY = 1, -1
function tab:GetPushedTextOffset() return self.pushX, self.pushY end
function tab:SetPushedTextOffset(x, y) self.pushX, self.pushY = x, y end
tab.Middle, tab.MiddleActive, tab.LeftHighlight = Frame(), Frame(), Frame()
local function Anchored()
    local points = {}
    return { SetPoint = function(_, point, ...) points[point] = {point, ...} end,
        GetPointByName = function(_, point) return unpack(points[point]) end }
end
tab.Text, tab.Icon = Anchored(), Anchored()
local function CheckTab(y)
    for _, anchor in ipairs({{tab.Text, "LEFT", 26}, {tab.Text, "RIGHT", -10}, {tab.Icon, "LEFT", 10}}) do
        local _, relative, point, x, offset = anchor[1]:GetPointByName(anchor[2])
        assert(relative == tab and point == anchor[2] and x == anchor[3] and offset == y)
    end
end
tab:SetTabState("NORMAL")
opened()
opened()
local face = tab.textures.BACKGROUND
local profileRow = Frame(listPage.ScrollBox)
profileRow.SetMenuButtonCallback = TRP3_ProfileManagerListElementMixin.SetMenuButtonCallback
local options = TextureButton(profileRow)
profileRow.MenuButton = options
local function LateButton(parent)
    local b = Frame(parent)
    b.kind, b.OnEnter, b.h = "Button", UIPanelButtonMixin.OnEnter, 25
    b.GetFontString, b.GetHighlightTexture = panelButton.GetFontString, noop
    return b
end
profileRow.BindButton = LateButton(profileRow)
options.Disabled = nil
listPage.ScrollBox.initialize(profileRow)
assert(profileRow.BindButton.textures.BACKGROUND:IsShown())
local section = Frame(TRP3_RegisterAbout_Edit_Template2_Container)
local remove, background = LateButton(section), LateButton(section)
TRP3_RegisterAbout_AboutPanel_Edit:OnShow()
assert(remove.textures.BACKGROUND:IsShown() and background.textures.BACKGROUND:IsShown())
local menuNormal = options.Normal
listPage.ScrollBox.initialize(profileRow)
assert(options.Normal == menuNormal and menuNormal.atlas == "common-dropdown-a-button")
assert(options.Pushed.atlas == "common-dropdown-a-button-pressed" and options.Highlight.atlas == "common-dropdown-a-button-hover")
assert(not options.OnMouseUp and not options.OnMouseDown)
assert(settingsPage.Background.alpha == 0 and not settingsPage.textures)
assert(profilesPage.Background.alpha == 0 and not profilesPage.textures)
assert(relationsPage.Background.alpha == 0 and not relationsPage.textures)
relationsArt.GetTexture = function() return 123456 end
opened()
assert(relationsPage.Background.alpha == 0 and not relationsPage.textures)
assert(parchmentArt.alpha == 0.7 and not parchmentPage.textures)
assert(TRP3_RegisterCharact.Background.alpha == 0.7 and not TRP3_RegisterCharact.textures)
assert(TRP3_RegisterCharact_NamePanel.Center.alpha == 0)
assert(characteristics.TopEdge.alpha == 0 and characteristics.Header.Center.alpha == 0)
assert(characteristics.Header.Text.color[2] == 0.82 and characteristics.Center.alpha == 0.7 and not characteristics.textures)
characteristics.Center:SetTexture("another profile background")
assert(face:IsShown() and not tab.textures.BACKGROUND2 and #art.children == 0)
assert(panelButton.Middle.alpha == 0 and panelButton.highlight.alpha == 0 and not lookalike.textures)
assert(panelButton.Highlight == "flareHighlight")
panelButton.over = true
panelButton:OnEnter()
assert(not edit:IsShown() and not edit.textures and edit.w == 48 and edit.h == 48)
assert(edit.Normal.alpha == 0.7 and edit.Pushed.alpha == 0.7 and edit.Highlight.alpha == 0.7)
assert(panelButton.textures.BACKGROUND.atlas == "common-dropdown-c-button-hover-1")
panelButton.disabled = true
panelButton:OnDisable()
assert(panelButton.textures.BACKGROUND.atlas == "common-dropdown-c-button-disabled")
assert(dd.Text.justify == "CENTER" and #points == 2 and dd.Arrow.alpha == 0 and not unrelated.Button.textures)
dd:OnMenuOpened()
assert(dd.textures.BACKGROUND.atlas == "common-dropdown-c-button-open")
dd:OnMenuClosed()
assert(dd.textures.BACKGROUND.atlas == "common-dropdown-c-button")
assert(dd.Text.r == 1 and dd.Text.g == 0.82 and dd.Text.b == 0)
dd.disabled = true
dd:OnButtonStateChanged()
assert(dd.textures.BACKGROUND.atlas == "common-dropdown-c-button-disabled")
assert(dd.Text.r == 0.5 and dd.Text.g == 0.5 and dd.Text.b == 0.5)
assert(category.BorderCenter.alpha == 0 and category.HighlightBorderEdgeLeft.alpha == 0 and category.Icon.alpha == 0.7)
assert(tab.Middle.alpha == 0 and tab.MiddleActive.alpha == 0 and tab.LeftHighlight.alpha == 0)
local normal = "common-dropdown-c-button"
assert(face.atlas == normal)
CheckTab(0)
tab.state, tab.over = "PUSHED", true
tab:OnMouseDown()
assert(face.atlas == normal .. "-pressedhover-1")
tab:SetTabState("SELECTED")
CheckTab(0)
assert(tab.pushX == 0 and tab.pushY == 0)
assert(face.atlas == normal and tab.MiddleActive.alpha == 0)
tab.state, tab.over = "NORMAL", false
local function CheckRow(selected)
    assert(category.textures.BACKGROUND:IsShown() == selected)
    assert(category.textures.ARTWORK:IsShown() == selected)
    assert(category.children[1]:IsShown() == selected)
end
CheckRow(false)
category.disabled = true
category:SetVisualState("DISABLED")
assert(category.Text.r == 1 and category.Text.g == 0.84 and category.Text.b == 0.50)
CheckRow(true)
page:Hide()
TRP3_InventoryPage:Hide()
toggle(nil, false)
assert(not slotFill:IsShown() and empty.bkg.alpha == 0.7 and equipped.bkg.alpha == 0.7)
assert(not slotEdge:IsShown() and equipped.IconBorder.alpha == 0.7)
assert(not panelEdge:IsShown() and top.alpha == 0.7 and bottom.alpha == 0.7)
CheckPanelInset(0)
assert(TRP3_MainTutorialButton:GetFrameLevel() == tutorialLevel and TRP3_MainTutorialButton:IsShown())
local point, relative, _, x, y = category.Text:GetPoint(1)
assert(point == "RIGHT" and relative == category and x == -19 and y == 2)
listPage.ScrollBox.initialize(profileRow)
TRP3_RegisterAbout_AboutPanel_Edit:OnShow()
assert(not remove.textures.BACKGROUND:IsShown() and not profileRow.BindButton.textures.BACKGROUND:IsShown())
assert(options.Normal == options.art and options.Pushed == options.art and options.Highlight == options.art and not options.Disabled)
assert(navBar.action.Normal == navBar.action.art)
assert(not pageTrim:IsShown())
assert(TRP3_QuestLogPage.TopEdge.alpha == 0.7 and navBar.InsetBorderLeft.alpha == 0.7)
assert(#anchors == 2 and anchors[1][1] == "TOPLEFT" and anchors[2][2] == TRP3_Dashboard)
assert(settingsPage.Background.alpha == 0.7 and profilesPage.Background.alpha == 0.7)
assert(relationsPage.Background.alpha == 0.7)
assert(not panelClose:IsShown() and win.ResizeButton.Normal == win.ResizeButton.art and win.ResizeButton.Pushed == win.ResizeButton.art)
assert(win.CloseButton.art.alpha == 0.7 and win.ResizeButton.art.alpha == 0.7)
assert(menu.ScrollBar:GetScale() == 1 and scroll.ScrollBar:GetScale() == 0.9)
assert(TRP3_RegisterCharact.Background.alpha == 0.7 and TRP3_RegisterCharact_NamePanel.Center.alpha == 0.7)
assert(characteristics.TopEdge.alpha == 0.7 and characteristics.Header.Center.alpha == 0.7)
assert(characteristics.Header.Text.color[2] == 0.95 and characteristics.Header.Text.color[4] == 0.8)
assert(panelButton.Middle.alpha == 0.7 and panelButton.highlight.alpha == 0.7 and not panelButton.textures.BACKGROUND:IsShown())
assert(panelButton.Normal == "nativeNormal" and panelButton.Disabled == "nativeDisabled")
assert(character.Text.g == 1 and category.Text.g == 0.9)
assert(not arrow:IsShown())
CheckTab(-9)
assert(tab.pushX == 1 and tab.pushY == -1)
CheckRow(false)
assert(not face:IsShown() and win.Backdrop.alpha == 0.7 and menu.Background.alpha == 0.7)
assert(tab.MiddleActive.alpha == 0.7 and tab.MiddleActive:IsShown())
assert(not dd.textures.BACKGROUND:IsShown() and not dd.textures.OVERLAY:IsShown() and dd.Arrow.alpha == 0.7)
assert(dd.Text.justify == "LEFT" and #points == 2 and points[1][2] == dd.Arrow and points[2][5] == -8)
assert(dd.Text.r == 0.4)
assert(category.BorderCenter.alpha == 0.7 and not category.textures.BACKGROUND:IsShown())
tab:SetTabState("NORMAL")
CheckTab(-6)
opened()
assert(not bronze:IsShown() and category.h == 34)
assert(win.CloseButton:GetFrameLevel() == win:GetFrameLevel() + 1 and win.ResizeButton:GetFrameLevel() == win:GetFrameLevel() + 1)
assert(category.justify == "RIGHT" and category.points.TOPLEFT[1] == 27 and category.points.TOPLEFT[2] == -44)
page:Show()
toggle(nil, true)
TRP3_InventoryPage:Show()
opened()
assert(slotFill:IsShown() and empty.bkg.alpha == 0 and not empty.textures.BACKGROUND2)
assert(slotEdge:IsShown() and #empty.children == 1)
CheckPanelInset(4)
assert(scroll.ScrollBar:GetScale() == 0.7)
CheckTab(0)
CheckRow(true)
category.disabled = false
category:SetVisualState("NORMAL")
CheckRow(false)
assert(face:IsShown() and face.atlas == normal and tab.Middle.alpha == 0 and category.BorderCenter.alpha == 0)
-- An incompatible navigation API disables custom layout only, including on restore.
TRP3_MainFrame, TRP3_MainFrameMenuScroll, TRP3_MainFramePageContainer = Frame(), Frame(), Frame()
TRP3_MainFrame.Backdrop = Frame()
TRP3_API.navigation.menu.rebuildMenu = nil
local rows = {}
ns.StartMainWindow({ registerConfigKey = noop, getValue = function() return true end,
    registerHandler = function(_, fn) toggle = fn end }, rows)
assert(#rows == 1 and TRP3_MainFrame.Backdrop.alpha == 0)
toggle(nil, false)
assert(TRP3_MainFrame.Backdrop.alpha == 0.7)
print("PASS: main window toggle, late page controls, profile art and hidden page restoration")
