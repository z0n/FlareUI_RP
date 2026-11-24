local _, ns = ...
local tiles = setmetatable({}, { __mode = "k" })
local options = { party = {}, raid = {} }
local pf

local function Kind(f)
    if f.fuiSample then return end
    if f.ctx then
        if f.flareTile and f.ctx.fontKey == "raid" then return "raid" end
    elseif f.index ~= nil and f == _G["FlareUI_Party" .. f.index] then
        return "party"
    end
end

local function Live(f)
    local unit = f.fuiUnit
    if not FlareUI.EditPreviewing() and f:IsVisible() and canaccessvalue(unit) and unit and ns.DirectExists(unit) then return unit end
end

local function PaintLabel(label, unit, full, profile, restore)
    local name = profile and ns.ProfileName(profile, full)
    if name then label:SetFormattedText("%s", name)
    elseif restore then label:SetText(FlareUI.UnitDisplayName(unit, nil, full)) end
end

local function MemberName(f, unit, profile, restore)
    if not profile and not restore then return end
    local full
    if pf.NameFull then full = pf.NameFull(f)
    elseif pf.SlotOn(f) and not (pf.SlotStyle and pf.SlotStyle(f) == "partytile") then full = f.btFullName ~= false end
    if full == nil then full = FlareUI.db.profile.unitframes.fullNames ~= false end
    PaintLabel(f.Name, unit, full, profile, restore)
end

local function AboveKind(f)
    if f.NameAboveText and f.NameAboveText:IsShown() then
        local slot, pick = FlareUI.NameAbove.Get(pf.NameAboveDb(f))
        if slot then return pick end
    end
end

local function MemberProfile(unit, s, opt)
    if opt.health then return ns.ReadHealthColor(unit, s) end
    if opt.names then return ns.Profile(unit) end
end

local function Paint(f, s)
    local unit = Live(f)
    if not unit then return end
    local opt = options[s.kind]
    local profile = MemberProfile(unit, s, opt)
    if opt.names or s.names then
        local nameProfile = opt.names and profile
        MemberName(f, unit, nameProfile, true)
        local pick = AboveKind(f)
        if pick then PaintLabel(f.NameAboveText, unit, ns.NameFormat(pick), nameProfile, true) end
        s.names = opt.names
    end
    if opt.health or s.applied then
        ns.ApplyHealth(f, unit, pf.NameAboveDb(f), s, opt.health)
    end
end

local function Discover(f)
    if not f or tiles[f] or not f.Name or not f.Health then return end
    local kind = Kind(f)
    if not kind then return end
    local s = { kind = kind }
    tiles[f] = s
    -- SlotOn runs before the host writes the member's name on every full update.
    -- SetFormattedText avoids re-entering its SetText hook. The host subsequently
    -- writes the above-frame label separately, handled by the SetName hook below.
    hooksecurefunc(f.Name, "SetText", function()
        if s.refreshing then return end
        local unit = Live(f)
        if not unit then return end
        local opt = options[kind]
        local profile = MemberProfile(unit, s, opt)
        if opt.names then MemberName(f, unit, profile, false) end
        s.names = opt.names
    end)
    hooksecurefunc(f.Health, "SetStatusBarColor", function()
        if s.refreshing then return end
        s.applied = nil -- host has just restored its own colour
        if not options[kind].health then return end
        local unit = Live(f)
        if not unit then return end
        s.refreshing = true
        securecallfunction(ns.ApplyHealth, f, unit, pf.NameAboveDb(f), s, true)
        s.refreshing = nil
    end)
end

local function Refresh(kind, ids)
    for f, s in pairs(tiles) do
        local unit = ids and Live(f)
        if (not kind or s.kind == kind) and (not ids or (unit and ids[ns.CharacterID(unit)])) then
            s.refreshing = true
            securecallfunction(Paint, f, s)
            s.refreshing = nil
        end
    end
end

local pending
local function Queue(id)
    if not (options.party.names or options.party.health or options.raid.names or options.raid.health) then return end
    local scheduled = pending ~= nil
    -- true means a full pass; a broad event always wins over individual IDs.
    if not id then pending = true
    elseif pending ~= true then
        pending = pending or {}
        pending[id] = true
    end
    if scheduled then return end
    C_Timer.After(0, function()
        local batch = pending
        pending = nil
        Refresh(nil, batch ~= true and batch or nil)
    end)
end

function ns.StartGroupFrames(config, elements)
    pf = FlareUI.PartyFrames
    local uf = FlareUI.UnitFrames
    if not (pf and pf.SlotOn and pf.NameAboveDb and FlareUI.NameAbove and FlareUI.NameAbove.Get
        and FlareUI.NameAbove.SetName and FlareUI.EditPreviewing and FlareUI.UnitDisplayName) then return end
    local function Option(kind, item, title, help)
        local key = "flareui_rp_" .. kind .. "_" .. item
        config.registerConfigKey(key, true)
        options[kind][item] = config.getValue(key)
        config.registerHandler(key, function(_, on) options[kind][item] = on; Refresh(kind) end)
        elements[#elements + 1] = { inherit = "TRP3_ConfigCheck", configKey = key, title = title, help = help }
    end
    for _, kind in ipairs({ "party", "raid" }) do
        local label = kind == "party" and "Party" or "Raid"
        elements[#elements + 1] = { inherit = "TRP3_ConfigH1", title = label .. " Frames" }
        Option(kind, "names", "Use RP Names", "Use each member's RP name where FlareUI shows their character name, on or above the frame.")
        if uf and uf.HealthColorMode and uf.HealthBarColor and FlareUI.ClassColorsOn then
            Option(kind, "health", "Use RP Health Bar Colours", "Use each member's profile colour when their bar would show a class colour. Low-health warnings and gradients keep priority.")
        end
    end
    hooksecurefunc(pf, "SlotOn", Discover)
    hooksecurefunc(FlareUI.NameAbove, "SetName", function(f)
        local s = tiles[f]
        if s and options[s.kind].names then
            local unit = Live(f)
            local pick = unit and AboveKind(f)
            if pick then PaintLabel(f.NameAboveText, unit, ns.NameFormat(pick), ns.Profile(unit), false) end
        end
    end)
    -- Either addon can finish login first. Attach to existing tiles too; the
    -- renderer hook discovers subsequently created ones without a roster scan.
    for i = 0, 4 do Discover(_G["FlareUI_Party" .. i]) end
    local function Header(header)
        if header then
            local children = { header:GetChildren() }
            for _, child in ipairs(children) do Discover(child) end
        end
    end
    for i = 1, 8 do Header(_G["FlareUI_RaidGroup" .. i]) end
    Header(_G.FlareUI_RaidAll)
    Header(_G.FlareUI_RaidTanksHeader)
    TRP3_API.RegisterCallback(TRP3_Addon, "REGISTER_DATA_UPDATED", function(_, id)
        if canaccessvalue(id) and type(id) == "string" and id ~= "" then Queue(id) else Queue() end
    end)
    local function QueueAll() Queue() end
    for _, event in ipairs({ "REGISTER_PROFILES_LOADED", "REGISTER_PROFILE_DELETED" }) do
        TRP3_API.RegisterCallback(TRP3_Addon, event, QueueAll)
    end
    TRP3_API.RegisterCallback(TRP3_API.GameEvents, "GROUP_ROSTER_UPDATE", QueueAll)
    -- Retry deferred restores even when all group options are now off.
    TRP3_API.RegisterCallback(TRP3_API.GameEvents, "PLAYER_REGEN_ENABLED", function() Refresh() end)
    Queue()
end
