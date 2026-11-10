-- The plugin's ElvUI module: its settings in ElvUI's profile, the frames it works on and the events
-- it passes on. The parts on each frame are in Holder.lua; what they show in CombatText.lua and
-- CrowdControl.lua. How it all fits together: README.md, technical part.

local addon, ns = ... ---@type string, AddonNamespace
local E, P = ElvUI[1], ElvUI[4]
local UF = E:GetModule("UnitFrames")

ns.NAME = addon
ns.L = LibStub("AceLocale-3.0"):GetLocale(addon)

---Whether the client hides a value (secret values: WoW: Forever in combat). Such a value may not be
---tested or compared, only passed on. A client without the check hides nothing.
---@param _ string|number|boolean|table|nil
---@return boolean
local function NeverSecret(_)
    return false
end
ns.IsSecret = issecretvalue or NeverSecret

-- The frames the plugin works on: ElvUI's unitframeType of each, in the options' order.
ns.unitOrder = { "player", "target", "focus", "pet", "party" }
ns.units = {}
for _, key in ipairs(ns.unitOrder) do
    ns.units[key] = true
end

P[addon] = {
    units = {
        player = { text = true, cc = true },
        target = { text = true, cc = true },
        focus = { text = true, cc = true },
        pet = { text = true, cc = true },
        party = { text = true, cc = true },
    },
    text = {
        font = "PT Sans Narrow",
        -- The text's height as a part of the spot's (Spot.lua), so party portraits get smaller text.
        size = 0.5,
        outline = "OUTLINE",
        -- Blizzard's own portrait text: a critical hit half again as big, held 0.7 seconds.
        crit = 1.5,
        hold = 0.7,
        damage = true,
        heals = true,
        misses = true,
        energize = false,
        short = false,
        schools = true,
        -- Blizzard's own portrait text colours.
        colors = {
            physical = { r = 1, g = 1, b = 1 },
            spell = { r = 1, g = 1, b = 0 },
            heal = { r = 0, g = 1, b = 0 },
            power = { r = 0.41, g = 0.8, b = 0.94 },
            miss = { r = 1, g = 1, b = 1 },
        },
    },
    cc = {
        numbers = true,
        interrupts = true,
        defensives = true,
    },
    -- The parts' strata ("": the frame's own) and level above ElvUI's raised element parent, which
    -- has the frame's texts; ElvUI puts its auras 10 above it.
    layer = { strata = "", level = 5 },
    -- How much goes to the debug addons (Debug.lua).
    debug = "metrics",
}

---The plugin's settings in the current ElvUI profile.
---@return AddonSettings
function ns.db()
    return E.db[addon]
end

-- The parts on each frame (Holder.lua): by frame, and in the order made.
---@type table<table, AddonHolder>
ns.holders = {}
---@type AddonHolder[]
ns.holderList = {}

-- The frames whose unit changes with each event.
local CHANGES = {
    PLAYER_TARGET_CHANGED = "target",
    PLAYER_FOCUS_CHANGED = "focus",
    GROUP_ROSTER_UPDATE = "party",
}

local M = E:NewModule(addon, "AceHook-3.0", "AceEvent-3.0")

---ElvUI configured a frame's portrait: the plugin's parts on it, made or moved along.
---@param _ table the UnitFrames module
---@param frame AddonFrame
function M:Attach(_, frame)
    ns.Attach(frame)
end

---The frames of a kind show another unit now.
---@param key string
local function Changed(key)
    for _, holder in ipairs(ns.holderList) do
        if holder.key == key then
            ns.Listen(holder)
            ns.HideText(holder)
            ns.RefreshCC(holder)
        end
    end
end

---@param event string
function M:UnitChanged(event)
    Changed(CHANGES[event] --[[@as string]])
end

---@param _ string the event
---@param owner string
function M:UNIT_PET(_, owner)
    if owner == "player" then Changed("pet") end
end

function M:PLAYER_REGEN_DISABLED()
    if ns.testing then ns.SetTesting(false) end
end

function M:Initialize()
    ns.ConnectDebug()
    LibStub("LibElvUIPlugin-1.0"):RegisterPlugin(addon, ns.InsertOptions)
    self:SecureHook(UF, "Configure_Portrait", "Attach")
    for _, frame in ipairs(E.oUF.objects) do
        ns.Attach(frame)
    end
    ns.Log("info", "start: {1} frames taken on", #ns.holderList)
    -- UNIT_COMBAT and the loss of control each frame registers for its own unit (Holder.lua).
    for event in pairs(CHANGES) do
        self:RegisterEvent(event, "UnitChanged")
    end
    self:RegisterEvent("UNIT_PET")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
end

E:RegisterModule(M:GetName())
