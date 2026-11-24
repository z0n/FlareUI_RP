local ns, active, skins = {}, {}, {}
assert(loadfile("Toolbar.lua"))("FlareUI_RP", ns)
local function button(alpha)
    return { Icon = {}, Border = { alpha = alpha,
        GetAlpha = function(self) return self.alpha end,
        SetAlpha = function(self, a) self.alpha = a end },
        width = 25, GetWidth = function(self) return self.width end }
end
local function noop() end
TRP3_API = { toolbar = {} }
TRP3_ToolbarFrame = { UpdateButtons = noop, buttonPool = { EnumerateActive = function() return pairs(active) end } }
local function backdrop(id)
    return { db = { edgeFile = id }, fill = { 0.1, 0.2, 0.3, 0.4 }, border = { 0.5, 0.6, 0.7, 0.8 },
        GetBackdrop = function(self) return self.db end,
        SetBackdrop = function(self, db) self.db = db end,
        GetBackdropColor = function(self) return unpack(self.fill) end,
        GetBackdropBorderColor = function(self) return unpack(self.border) end,
        SetBackdropColor = function(self, ...) self.fill = { ... } end,
        SetBackdropBorderColor = function(self, ...) self.border = { ... } end }
end
local panel, title = backdrop("panel"), backdrop("title")
local titleShown = true
title.IsShown = function() return titleShown end
TRP3_ToolbarFrame.GetFrameLevel = function() return 1 end
local pieces = {}
local function texture(parent)
    local tex = { parent = parent, SetWidth = function(self, w) self.width = w end, SetHeight = noop,
        SetSnapToPixelGrid = noop, SetTexelSnappingBias = noop,
        SetPoint = function(self, _, anchor, _, x) self.anchor, self.x = anchor, x end,
        SetTexCoord = function(self, ...) self.uv = { ... } end,
        SetTexture = function(_, id) assert(id == 123) end, SetShown = function(self, on) self.shown = on end }
    pieces[#pieces + 1] = tex
    return tex
end
panel.CreateTexture, title.CreateTexture = texture, texture
TRP3_ToolbarFrame.Container = { Backdrop = panel, IsShown = function() return next(active) ~= nil end }
TRP3_ToolbarFrame.TitleBar, TRP3_ToolbarFrame.UpdateTitleBar = title, noop
local afterLayout, afterTitle, surround, file
function hooksecurefunc(_, method, fn)
    if method == "UpdateTitleBar" then afterTitle = fn
    else assert(method == "UpdateButtons"); afterLayout = fn end
end
function LibStub() return { Fetch = function(_, kind, name, noDefault)
    if kind == "background" then assert(name == "Blizzard Dialog Background Dark"); return name end
    assert(kind == "border" and noDefault); return file and name
end } end
function CreateFrame(_, _, parent)
    if parent == panel then
        assert(not surround)
        surround = backdrop("outer")
        surround.ClearAllPoints = function(self) self.anchors = {} end
        surround.SetPoint = function(self, p, owner) self.anchors[p] = owner end
        surround.SetAllPoints = function(self, owner) self.anchors.all = owner end
        surround.SetShown = function(self, shown) self.shown = shown end
        surround.EnableMouse, surround.SetFrameLevel = noop, noop
        surround.GetWidth = function() return 250 end
        surround.sizeChanged = {}
        surround.HookScript = function(self, event, fn)
            assert(event == "OnSizeChanged")
            table.insert(self.sizeChanged, fn)
        end
        return surround
    end
    assert(not skins[parent], "pool reuse must reuse the skin")
    skins[parent] = { EnableMouse = function(_, on) assert(not on) end,
        SetAllPoints = function(_, target) assert(target == parent.Icon) end,
        SetBackdrop = function(self, db) assert(db.edgeFile == file); self.size = db.edgeSize end,
        SetBackdropBorderColor = noop,
        Show = function(self) self.shown = true end, Hide = function(self) self.shown = false end }
    return skins[parent]
end
local values, handlers = {}, {}
local config = { registerConfigKey = function(k, default) values[k] = default end,
    registerHandler = function(k, fn) handlers[k] = fn end, getValue = function(k) return values[k] end }
local elements = {}
ns.StartToolbar(config, elements)
assert(not afterLayout and #elements == 0, "missing media leaves the toolbar alone")
file = "FlareUI Frames"
local a, b = button(0.8), button(1)
active[a] = true
ns.StartToolbar(config, elements)
local toggle, choose = handlers.flareui_rp_toolbar_borders, handlers.flareui_rp_toolbar_window_border
afterLayout()
assert(values.flareui_rp_toolbar_window_border == "Quest Tracker" and skins[a].shown and a.Border.alpha == 0)
assert(panel.db.edgeFile == "FlareUI Thick" and title.db.edgeFile == "FlareUI Thick")
choose(nil, "Thin")
assert(panel.db.edgeSize == 8 and title.db.edgeFile == "FlareUI Thin")
assert(skins[a].shown and a.Border.alpha == 0)
local size = skins[a].size
a.width, active[b] = 40, true
afterLayout()
assert(skins[a].size > size and skins[b].shown)
active[a] = nil
toggle(nil, false)
for frame, id in pairs({ [panel] = "panel", [title] = "title" }) do
    assert(frame.db.edgeFile == id and frame.fill[4] == 0.4 and frame.border[1] == 0.5)
end
choose(nil, "Frames")
assert(panel.db.edgeFile == "panel")
assert(not skins[a].shown and not skins[b].shown and a.Border.alpha == 0.8 and b.Border.alpha == 1)
active[a] = true
afterLayout()
assert(not skins[a].shown and a.Border.alpha == 0.8)
toggle(nil, true)
assert(title.db.edgeFile == "FlareUI Frames" and panel.db.edgeFile == "FlareUI Frames")
choose(nil, "Quest Tracker")
assert(#pieces == 0 and title.db.edgeFile == "FlareUI Thick", "missing atlas falls back to Thick")
C_Texture = { GetAtlasInfo = function(name)
    assert(name == "ui-questtracker-primary-objective-header")
    return { file = 123, width = 300, height = 40, leftTexCoord = 0.25, rightTexCoord = 0.75, topTexCoord = 0, bottomTexCoord = 1 }
end }
choose(nil, "Quest Tracker")
assert(#pieces == 6 and pieces[1].parent == title and pieces[4].parent == panel)
assert(pieces[1].anchor == surround and pieces[4].anchor == surround)
for _, i in ipairs({ 1, 4 }) do
    assert(pieces[i].uv[1] == 0.25 and pieces[i+1].uv[2] == 0.75, "both ornaments include the atlas ends")
    assert(pieces[i].x == -11 and pieces[i+1].x == 17 and pieces[i+1].width == 90)
end
for _, resize in ipairs(surround.sizeChanged) do resize(surround, 40) end
for _, i in ipairs({ 1, 4 }) do
    local left, right = pieces[i], pieces[i+1]
    assert(left.uv[1] == 0.25 and right.uv[2] == 0.75)
    assert(left.width + right.width < 40 - left.x + right.x, "caps overlap on a narrow toolbar")
end
assert(surround.shown and not panel.db and not title.db and surround.anchors.TOPLEFT == TRP3_ToolbarFrame)
assert(surround.db.edgeFile == "FlareUI Thick" and surround.db.edgeSize == 16 and surround.db.insets.left == 3)
assert(surround.db.bgFile == "Blizzard Dialog Background Dark")
active[a], active[b] = nil, nil
afterLayout()
assert(not surround.shown and not pieces[1].shown and title.db.edgeFile == "FlareUI Thick")
active[b] = true
afterLayout()
assert(surround.shown and pieces[1].shown and not title.db)
titleShown = false
afterTitle()
assert(surround.anchors.all == panel)
choose(nil, "Thin")
assert(not surround.shown and title.db.edgeFile == "FlareUI Thin")
for _, tex in ipairs(pieces) do assert(not tex.shown) end
choose(nil, "Quest Tracker")
assert(#pieces == 6)
for _, tex in ipairs(pieces) do assert(tex.shown) end
toggle(nil, false)
for _, tex in ipairs(pieces) do assert(not tex.shown) end
assert(panel.db.edgeFile == "panel" and title.db.edgeFile == "title")
print("PASS: toolbar window styles, resizing, pool reuse and native appearance restoration")
