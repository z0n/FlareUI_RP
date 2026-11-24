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

function ns.ProfileColor(profile)
    local color = profile and profile:GetCustomColor()
    if color then return color:GetRGB() end
end

local function Trimmed(name)
    if canaccessvalue(name) and type(name) == "string" then
        name = strtrim(name)
        if name ~= "" then return name end
    end
end

function ns.ProfileGuild(profile)
    local membership = profile and profile.GetCustomGuildMembership and profile:GetCustomGuildMembership()
    return Trimmed(membership and membership.name)
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
