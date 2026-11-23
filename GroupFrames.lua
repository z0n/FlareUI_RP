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
    if not FlareUI.EditPreviewing() and f:IsVisible() and canaccessvalue(unit) and unit and UnitExists(unit) then return unit end
end

local function Names(f, unit, enabled, restore)
    local profile = enabled and ns.Profile(unit)
    if not profile and not restore then return end
    local full
    if pf.SlotOn(f) then full = f.btFullName ~= false
    else full = FlareUI.db.profile.unitframes.fullNames ~= false end
    local function Label(label, long)
        local name = profile and ns.ProfileName(profile, long)
        if name then label:SetFormattedText("%s", name)
        elseif restore then label:SetText(FlareUI.UnitDisplayName(unit, nil, long)) end
    end
    Label(f.Name, full)
    if f.NameAboveText and f.NameAboveText:IsShown() then
        local slot, pick = FlareUI.NameAbove.Get(pf.NameAboveDb(f))
        if slot then Label(f.NameAboveText, pick == "fullname") end
    end
end

local function Paint(f, s)
    local unit = Live(f)
    if not unit then return end
    local opt = options[s.kind]
    if opt.names or s.names then
        Names(f, unit, opt.names, true)
        s.names = opt.names
    end
    if opt.health or s.applied then
        if opt.health then ns.ReadHealthColor(unit, s) end
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
        if opt.health then ns.ReadHealthColor(unit, s) end
        if opt.names then Names(f, unit, true, false) end
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

local function Refresh(kind)
    for f, s in pairs(tiles) do
        if not kind or s.kind == kind then
            s.refreshing = true
            securecallfunction(Paint, f, s)
            s.refreshing = nil
        end
    end
end

local pending
local function Queue()
    if pending then return end
    if not (options.party.names or options.party.health or options.raid.names or options.raid.health) then return end
    pending = true
    C_Timer.After(0, function() pending = nil; Refresh() end)
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
        Option(kind, "names", "RP Names on " .. label .. " Frames", "Use RP names on member tiles, following FlareUI's name format.")
        if uf and uf.HealthColorMode and uf.HealthBarColor and FlareUI.ClassColorsOn then
            Option(kind, "health", "RP " .. label .. " Health Colour", "Enable Class Colours in this frame's Look settings. Health warnings keep priority.")
        end
    end
    hooksecurefunc(pf, "SlotOn", Discover)
    hooksecurefunc(FlareUI.NameAbove, "SetName", function(f)
        local s = tiles[f]
        if s and options[s.kind].names then
            local unit = Live(f)
            if unit then Names(f, unit, true, false) end
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
    for _, event in ipairs({ "REGISTER_DATA_UPDATED", "REGISTER_PROFILES_LOADED", "REGISTER_PROFILE_DELETED" }) do
        TRP3_API.RegisterCallback(TRP3_Addon, event, Queue)
    end
    for _, event in ipairs({ "GROUP_ROSTER_UPDATE", "PLAYER_REGEN_ENABLED" }) do
        TRP3_API.RegisterCallback(TRP3_API.GameEvents, event, Queue)
    end
    Queue()
end
