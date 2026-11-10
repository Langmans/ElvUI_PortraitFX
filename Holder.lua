-- The plugin's parts on a frame: a frame of its own on ElvUI's raised element parent (above the 3D
-- portrait and the health bar, with the frame's texts), holding the text and the icon. Made once
-- per frame; laid out again on each Configure_Portrait, which ElvUI runs on every settings change.

local _, ns = ... ---@type string, AddonNamespace

-- Above the raised element parent's own level, below the auras ElvUI puts at its level + 10.
local LEVEL = 5

---@param frame AddonFrame
---@return AddonHolder
local function Build(frame)
    local parent = frame.RaisedElementParent or frame
    local holder = CreateFrame("Frame", nil, parent) --[[@as AddonHolder]]
    holder:SetFrameLevel(parent:GetFrameLevel() + LEVEL)
    holder.frame, holder.key = frame, frame.unitframeType
    holder.text = holder:CreateFontString(nil, "OVERLAY")
    holder.text:Hide()
    ns.BuildCC(holder)
    ns.holders[frame] = holder
    ns.holderList[#ns.holderList + 1] = holder
    return holder
end

---Puts the text and the icon on the frame's spot (Spot.lua).
---@param holder AddonHolder
function ns.Layout(holder)
    local region, point, size = ns.Spot(holder.frame)
    holder.size = size
    holder.text:ClearAllPoints()
    holder.text:SetPoint("CENTER", region, "CENTER", 0, 0)
    ns.LayoutCC(holder, region, point, size)
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
    ns.UpdateLoss()
end
