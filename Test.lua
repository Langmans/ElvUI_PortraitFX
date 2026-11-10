-- Test mode: sample combat text on every frame in turn and a sample icon with a countdown on each,
-- to place and size things without a fight. Combat ends it (Core.lua).

local _, ns = ... ---@type string, AddonNamespace

ns.TEST_INTERVAL = 1.5
ns.PREVIEW_DURATION = 8
local PREVIEW_ICON = "Interface\\Icons\\Spell_Frost_FrostNova"

-- The samples, in turn: event, flags, amount and school, as UNIT_COMBAT gives them.
ns.samples = {
    { "WOUND", "", 312, 1 },
    { "WOUND", "CRITICAL", 2468, 1 },
    { "DODGE", "", 0, 1 },
    { "WOUND", "", 527, 4 },
    { "HEAL", "", 640, 2 },
    { "WOUND", "ABSORB", 0, 32 },
    { "WOUND", "GLANCING", 98, 1 },
    { "HEAL", "CRITICAL", 1890, 8 },
    { "WOUND", "", 433, 16 },
    { "IMMUNE", "", 0, 1 },
}

-- The running ticker.
---@type FunctionContainer?
local ticker
local turn = 0

---The next sample on every frame.
local function Play()
    turn = turn % #ns.samples + 1
    local sample = ns.samples[turn]
    for _, holder in ipairs(ns.holderList) do
        ns.ShowText(holder, unpack(sample))
    end
end

---Turns test mode on or off.
---@param on boolean
function ns.SetTesting(on)
    ns.testing = on
    if ticker then ticker:Cancel() end
    ticker = on and C_Timer.NewTicker(ns.TEST_INTERVAL, Play) or nil
    turn = 0
    local units = ns.db().units
    for _, holder in ipairs(ns.holderList) do
        holder.preview = holder.preview or ns.IconFrame(holder, ns.PREVIEW_LEVEL)
        local preview = holder.preview
        preview.icon:SetTexture(PREVIEW_ICON)
        preview.cooldown:SetCooldown(GetTime(), ns.PREVIEW_DURATION)
        preview:SetShown(on and units[holder.key].cc)
        if not on then ns.HideText(holder) end
    end
end
