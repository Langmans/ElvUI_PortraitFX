-- The plugin's parts on a frame: a frame of its own on ElvUI's raised element parent (above the 3D
-- portrait and the health bar, with the frame's texts), holding the icon and, above everything of
-- the icon, the text. Made once per frame; laid out again on each Configure_Portrait, which ElvUI
-- runs on every settings change. Strata and level can be set (Frames tab); the strata is the
-- frame's own unless set.

local _, ns = ... ---@type string, AddonNamespace

-- Levels above the holder's: the icon's frame, the aura container (its slots up to 3 above it),
-- the loss of control, test mode's sample icon and the text.
local CC, CONTAINER, LOSS, PREVIEW, TEXT = 1, 2, 6, 8, 10

---The frame the parts hang on.
---@param frame AddonFrame
---@return Frame
local function Parent(frame)
    return frame.RaisedElementParent or frame
end

---Puts the parts at the strata and level set, keeping their order.
---@param holder AddonHolder
function ns.Stack(holder)
    local parent, layer = Parent(holder.frame), ns.db().layer
    holder:SetFrameStrata((layer.strata ~= "" and layer.strata or parent:GetFrameStrata()) --[[@as FrameStrata]])
    local base = parent:GetFrameLevel() + layer.level
    holder:SetFrameLevel(base)
    holder.cc:SetFrameLevel(base + CC)
    if holder.container then holder.container:SetFrameLevel(base + CONTAINER) end
    holder.loss:SetFrameLevel(base + LOSS)
    if holder.preview then holder.preview:SetFrameLevel(base + PREVIEW) end
    holder.textFrame:SetFrameLevel(base + TEXT)
end

-- The events each frame registers for its own unit, as Blizzard's unit frames do.
local UNIT_EVENTS = { "UNIT_COMBAT", "LOSS_OF_CONTROL_UPDATE", "LOSS_OF_CONTROL_ADDED" }

---Something happened to the frame's unit.
---@param holder AddonHolder
---@param event string
---@param unit string
---@param what string|AddonSecret UNIT_COMBAT's event
---@param flags string|AddonSecret
---@param amount number|AddonSecret
---@param school number|AddonSecret
local function OnEvent(holder, event, unit, what, flags, amount, school)
    if event ~= "UNIT_COMBAT" then
        ns.UpdateLoss(holder)
        return
    end
    ns.Count("combat")
    if ns.Logging("debug") then
        ns.Log("debug", "combat: {1} {2} on {3}, amount {4}", ns.Shown(what), ns.Shown(flags), unit, ns.Shown(amount))
    end
    ns.ShowText(holder, what, flags, amount, school)
end

---Registers the unit events for the frame's unit, again when it shows another; none while it has
---no unit.
---@param holder AddonHolder
function ns.Listen(holder)
    local unit = ns.Unit(holder)
    if holder.listening == unit then return end
    holder.listening = unit
    if not unit then
        holder:UnregisterAllEvents()
        return
    end
    for _, event in ipairs(UNIT_EVENTS) do
        holder:RegisterUnitEvent(event, unit)
    end
end

---@param frame AddonFrame
---@return AddonHolder
local function Build(frame)
    local holder = CreateFrame("Frame", nil, Parent(frame)) --[[@as AddonHolder]]
    holder.frame, holder.key = frame, frame.unitframeType
    holder:SetScript("OnEvent", OnEvent)
    ns.BuildCC(holder)
    holder.textFrame = CreateFrame("Frame", nil, holder)
    holder.textFrame:SetAllPoints(holder)
    holder.text = holder.textFrame:CreateFontString(nil, "OVERLAY")
    holder.text:Hide()
    ns.holders[frame] = holder
    ns.holderList[#ns.holderList + 1] = holder
    return holder
end

---Puts the text and the icon on the frame's spot (Spot.lua), at the strata and level set.
---@param holder AddonHolder
function ns.Layout(holder)
    ns.Listen(holder)
    local region, point, size = ns.Spot(holder.frame)
    holder.size = size
    local text = ns.db().text
    holder.text:ClearAllPoints()
    holder.text:SetPoint(text.point, region, text.point, text.x, text.y)
    ns.LayoutCC(holder, region, point, size)
    ns.Stack(holder)
end

---Takes a frame on, if it is one of the plugin's: its parts made, or laid out again.
---@param frame AddonFrame
function ns.Attach(frame)
    if not ns.units[frame.unitframeType] or frame.isChild then return end
    local holder = ns.holders[frame]
    if not holder then
        holder = Build(frame)
        ns.ApplyCC(holder)
    end
    ns.Layout(holder)
end

---Every frame again, after a settings change.
function ns.ApplyAll()
    for _, holder in ipairs(ns.holderList) do
        ns.Layout(holder)
        ns.ApplyCC(holder)
    end
end
