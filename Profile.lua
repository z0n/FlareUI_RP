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

function ns.ProfileColor(unit)
    local profile, id = ns.Profile(unit)
    local color = profile and profile:GetCustomColor()
    if color then
        local r, g, b = color:GetRGB()
        return r, g, b, id
    end
end

function ns.ProfileName(profile, full)
    if not profile then return end
    local name
    if full then name = profile:GetFullName() else name = profile:GetFirstName() end
    if name and name ~= "" then return name end
end
