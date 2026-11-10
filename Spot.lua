-- Where on a frame the text and the icon go. With the portrait beside the bars: its box (the
-- backdrop, which keeps its size whatever the portrait style). As an overlay ElvUI fits the portrait
-- into the health bar, unless "full overlay" is on only into its filled part, so the portrait
-- changes size with the health: the health bar is the spot then, the icon a square on the side the
-- portrait would be on. Without a portrait the same.

local _, ns = ... ---@type string, AddonNamespace

-- A spot's size when the client hides it or the frame is not laid out yet.
ns.FALLBACK_SIZE = 32

-- The icon's point on the health bar, by ElvUI's frame orientation.
local SIDES = { LEFT = "LEFT", RIGHT = "RIGHT", MIDDLE = "CENTER" }

---A usable size: a number the client shows, above 0, else the fallback.
---@param size number|AddonSecret
---@return number
local function Usable(size)
    if ns.IsSecret(size) or not size or size <= 0 then return ns.FALLBACK_SIZE end
    return size --[[@as number]]
end

---The region to put the text and the icon on, the icon's point on it, and the icon's size (also
---what the text's size is measured against).
---@param frame AddonFrame
---@return table region, string point, number size
function ns.Spot(frame)
    if frame.USE_PORTRAIT and not frame.USE_PORTRAIT_OVERLAY then
        local box = frame.Portrait.backdrop
        local width, height = box:GetWidth(), box:GetHeight()
        if ns.IsSecret(width) or ns.IsSecret(height) then return box, "CENTER", ns.FALLBACK_SIZE end
        return box, "CENTER", Usable(math.min(width, height))
    end
    local health = frame.Health
    return health, SIDES[frame.ORIENTATION] or "LEFT", Usable(health:GetHeight())
end
