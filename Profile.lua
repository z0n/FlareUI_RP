local _, ns = ...

-- Check both name components before passing the unit to TRP3's identity resolver.
-- A cached name from the last target must never stand in for a restricted identity.
function ns.CharacterID(unit)
    local player = UnitIsPlayer(unit)
    if not canaccessvalue(player) or not player then return end
    if not canaccessallvalues(UnitNameUnmodified(unit)) then return end
    return TRP3_NameUtil.GetQualifiedName(unit)
end

function ns.Profile(unit)
    local id = ns.CharacterID(unit)
    if not id then return end
    return AddOn_TotalRP3.Player.CreateFromCharacterID(id), id
end

local function Trimmed(name)
    if canaccessvalue(name) and type(name) == "string" then
        name = strtrim(name)
        if name ~= "" then return name end
    end
end

local function ParseProfileColor(value, forDisplay)
    local hex = Trimmed(value)
    if not hex then return end
    local length = #hex - (hex:sub(1, 1) == "#" and 1 or 0)
    -- TRP3 parses a leading hex colour even when the field contains trailing junk.
    if (length ~= 3 and length ~= 4 and length ~= 6 and length ~= 8) or not hex:match("^#?%x+$") then return end
    local color = TRP3_API.ParseColorFromHexString(hex)
    if color and forDisplay then return TRP3_API.GenerateReadableColor(color, TRP3_API.Colors.Black) end
    return color
end

function ns.PlayerColor(profile, forDisplay)
    local characteristics = profile and profile:GetCharacteristics()
    return characteristics and ParseProfileColor(characteristics.CH, forDisplay)
end

function ns.ProfileColor(profile, forDisplay)
    local color = ns.PlayerColor(profile, forDisplay)
    if color then return color:GetRGB() end
end

function ns.ProfileGuild(profile)
    local membership = profile and profile.GetCustomGuildMembership and profile:GetCustomGuildMembership()
    return Trimmed(membership and membership.name)
end

-- TRP3 keys local links by short ID and remote links by owner + short ID.
-- Resolve both on this paint: different owners' pets can share a game name.
function ns.CompanionID(unit)
    local misc = TRP3_API.ui and TRP3_API.ui.misc
    if not (misc and misc.getTargetType and misc.isTargetTypeACompanion
        and misc.getCompanionFullID and UnitOwnerGUID) then return end
    local player = UnitIsPlayer(unit)
    if not canaccessvalue(player) or player then return end
    local guid = UnitOwnerGUID(unit)
    if not canaccessvalue(guid) or not guid or not canaccessallvalues(UnitNameUnmodified(unit)) then return end
    -- These TRP3 helpers also inspect client-specific identity values internally.
    local ok, kind = pcall(misc.getTargetType, unit)
    if not ok or not canaccessvalue(kind) or not misc.isTargetTypeACompanion(kind) then return end
    local resolved, id, owner = pcall(misc.getCompanionFullID, unit, kind)
    if not resolved or not canaccessallvalues(id, owner) or not id or not owner then return end
    return id, owner
end

function ns.CompanionData(unit)
    local api = TRP3_API.companions
    if not api then return end
    local id, owner = ns.CompanionID(unit)
    if not id then return end
    local profile
    if owner == TRP3_API.globals.player_id then
        if api.player and api.player.getCompanionProfile then
            profile = api.player.getCompanionProfile(id:sub(#owner + 2))
        end
    elseif api.register and api.register.getCompanionProfile then
        profile = api.register.getCompanionProfile(id)
    end
    return profile and profile.data, id
end

function ns.CompanionName(data) return Trimmed(data and data.NA) end
function ns.CompanionTitle(data) return Trimmed(data and data.TI) end
function ns.CompanionColor(data, forDisplay)
    return ParseProfileColor(data and data.NH, forDisplay)
end

function ns.ProfileTitle(profile, mode)
    if not profile then return end
    if mode == "short" then return Trimmed(profile.GetTitle and profile:GetTitle()) end
    if mode == "full" then return Trimmed(profile.GetFullTitle and profile:GetFullTitle()) end
end

function ns.SharesProfileGuild(profile)
    local guild = ns.ProfileGuild(profile)
    if not guild then return false end
    local own = ns.ProfileGuild(AddOn_TotalRP3.Player.GetCurrentUser())
    return own and strcmputf8i(own, guild) == 0
end

-- Match FlareUI's UnitDisplayName argument, including the surname-only pick.
function ns.NameFormat(pick)
    return pick == "lastname" and "lastname" or pick == "fullname"
end

function ns.ProfileName(profile, full)
    if not profile then return end
    local name
    if full == "lastname" then
        name = profile:GetLastName()
        if not name or name == "" then name = profile:GetFirstName() end
    elseif full then name = profile:GetFullName()
    else name = profile:GetFirstName() end
    if name and name ~= "" then return name end
end
