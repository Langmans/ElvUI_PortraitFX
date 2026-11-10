-- The icon over the portrait. Blizzard's custom aura container picks the auras and draws them: per
-- frame one container with three aura slots, the plugin only giving each a texture and a
-- cooldown. So they keep working in combat while WoW: Forever hides aura details from addons.
-- Above the slots the game's loss of control for the frame's unit (as Blizzard's own nameplates
-- read it), which also knows interrupts, silences and roots, which are no aura.

local _, ns = ... ---@type string, AddonNamespace
local E = ElvUI[1]

-- The aura slots, bottom to top: each one's key, filter and level in the container. Filter parts
-- all have to hold, so each kind of defensive gets a slot of its own.
local SLOTS = {
    { key = "external", filter = "HELPFUL|EXTERNAL_DEFENSIVE", level = 1 },
    { key = "big", filter = "HELPFUL|BIG_DEFENSIVE", level = 2 },
    { key = "cc", filter = "HARMFUL|CROWD_CONTROL", level = 3 },
}
local DEFENSIVES = { "external", "big" }
local ACTIVE = Constants.LossOfControlConsts.LOSS_OF_CONTROL_ACTIVE_INDEX

---An icon texture filling its frame, cropped as ElvUI crops its icons.
---@param parent Frame
---@return Texture
local function Icon(parent)
    local icon = parent:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(parent)
    icon:SetTexCoord(unpack(E.TexCoords))
    return icon
end

---A countdown swipe filling its frame, kept to follow the countdown numbers setting.
---@param holder AddonHolder
---@param parent Frame
---@return AddonCooldown
local function Cooldown(holder, parent)
    local cooldown = CreateFrame("Cooldown", nil, parent, "CooldownFrameTemplate") --[[@as AddonCooldown]]
    cooldown:SetAllPoints(parent)
    cooldown:SetReverse(true)
    cooldown:SetDrawEdge(false)
    cooldown:SetHideCountdownNumbers(not ns.db().cc.numbers)
    holder.cooldowns[#holder.cooldowns + 1] = cooldown
    return cooldown
end

---An icon of the plugin's own above the aura slots: a texture and a countdown, hidden.
---@param holder AddonHolder
---@return AddonIconFrame
function ns.IconFrame(holder)
    local frame = CreateFrame("Frame", nil, holder.cc) --[[@as AddonIconFrame]]
    frame:SetAllPoints(holder.cc)
    frame.icon = Icon(frame)
    frame.cooldown = Cooldown(holder, frame)
    frame:Hide()
    return frame
end

---The aura container with its slots, for the frame's unit. Errors on a client without one.
---@param holder AddonHolder
---@return AddonAuraContainer
local function Container(holder)
    local container = CreateFrame("AuraContainer", nil, holder.cc, "CustomAuraContainerTemplate") --[[@as AddonAuraContainer]]
    container:SetAllPoints(holder.cc)
    container:SetEditModePreviewEnabled(false)
    for _, slot in ipairs(SLOTS) do
        container:AddAuraSlot(slot.key, slot.filter, {
            ---@param button AddonAuraButton the game's aura button
            initializeFrame = function(button)
                button:SetAllPoints(holder.cc)
                button:SetFrameLevel(container:GetFrameLevel() + slot.level)
                button:EnableMouse(false)
                button:SetIcon(Icon(button))
                button:SetDurationCooldown(Cooldown(holder, button))
            end,
        })
    end
    container:SetUnit(holder.frame.unit)
    return container
end

---Updates a frame's loss of control when its countdown runs out.
---@param cooldown AddonCooldown
local function LossDone(cooldown)
    ns.UpdateLoss(cooldown.holder --[[@as AddonHolder]])
end

---Makes a frame's icon: the aura slots and the loss of control.
---@param holder AddonHolder
function ns.BuildCC(holder)
    holder.cooldowns = {}
    holder.cc = CreateFrame("Frame", nil, holder)
    local ok, container = pcall(Container, holder)
    if ok then
        holder.container = container
    else
        ns.Log("error", "cc: no aura container on {1}: {2}", holder.key, tostring(container))
    end
    holder.loss = ns.IconFrame(holder)
    holder.loss.cooldown.holder = holder
    holder.loss.cooldown:SetScript("OnCooldownDone", LossDone)
end

---Puts a frame's icon on its spot.
---@param holder AddonHolder
---@param region Region
---@param point FramePoint
---@param size number
function ns.LayoutCC(holder, region, point, size)
    local cc = holder.cc
    cc:ClearAllPoints()
    cc:SetPoint(point, region, point, 0, 0)
    cc:SetSize(size, size)
end

---The aura slots and the loss of control show the frame's unit, as it is now.
---@param holder AddonHolder
function ns.RefreshCC(holder)
    ns.UpdateLoss(holder)
    local container = holder.container
    if not container or not container:IsEnabled() then return end
    local unit = holder.frame.unit
    if container:GetUnit() ~= unit then container:SetUnit(unit) end
    container:UpdateAllAuras()
    if ns.Logging("debug") then ns.Log("debug", "cc: {1} shows {2}", holder.key, unit) end
end

---A frame's icon after a settings change: on or off, the defensives, countdown numbers.
---@param holder AddonHolder
function ns.ApplyCC(holder)
    local db = ns.db()
    local on = db.units[holder.key].cc
    holder.cc:SetShown(on)
    local container = holder.container
    if container then
        container:SetEnabled(on)
        for _, key in ipairs(DEFENSIVES) do
            container:SetAuraSlotEnabled(key, db.cc.defensives)
        end
    end
    for _, cooldown in ipairs(holder.cooldowns) do
        cooldown:SetHideCountdownNumbers(not db.cc.numbers)
    end
    ns.RefreshCC(holder)
end

---Whether a loss of control entry is for the icon: one the game displays (a hidden display type
---may be anything), and no interrupt when those are off (a hidden kind may be one).
---@param data LossOfControlData
---@return boolean
local function Wanted(data)
    local display = data.displayType
    if not ns.IsSecret(display) and display == 0 then return false end
    if ns.db().cc.interrupts then return true end
    local kind = data.locType
    -- The LS knows only the client's own checks as guards, not ns.IsSecret, which is one.
    ---@diagnostic disable-next-line: secret-comparison
    return not ns.IsSecret(kind) and kind ~= "SCHOOL_INTERRUPT"
end

---A unit's first entry the icon shows, in the game's order, and its index.
---@param unit string
---@return LossOfControlData? data, number index
local function Entry(unit)
    local count = C_LossOfControl.GetActiveLossOfControlDataCountByUnit(unit)
    -- A hidden count cannot be looped over: the game's active entry is the one in force.
    if ns.IsSecret(count) then count = ACTIVE end
    for index = 1, count do
        local data = C_LossOfControl.GetActiveLossOfControlDataByUnit(unit, index)
        if not ns.IsSecret(data) and data and Wanted(data) then return data, index end
    end
    return nil, 0
end

---A frame's loss of control icon, as the game has it now for the frame's unit. Hidden times come
---as the game's duration object; without one there is no countdown to show, so no icon either.
---@param holder AddonHolder
function ns.UpdateLoss(holder)
    local loss, unit = holder.loss, holder.frame.unit
    local data, index = nil, 0
    if ns.db().units[holder.key].cc then
        data, index = Entry(unit)
    end
    local start, duration = data and data.startTime, data and data.duration
    local hidden = ns.IsSecret(start) or ns.IsSecret(duration)
    local object = data and hidden and C_LossOfControl.GetActiveLossOfControlDuration(unit, index)
    if not data or hidden and not object then
        loss.cooldown:Clear()
        loss:Hide()
        return
    end
    if object then
        loss.cooldown:SetCooldownFromDurationObject(object)
    else
        loss.cooldown:SetCooldown(start --[[@as number]], duration --[[@as number]])
    end
    loss.icon:SetTexture(data.iconTexture)
    loss:Show()
    ns.Count("loss")
    if ns.Logging("info") then ns.Log("info", "loss: {1} on {2}", ns.Shown(data.locType), unit) end
end
