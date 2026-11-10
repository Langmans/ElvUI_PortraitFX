-- The crowd control icon over the portrait. Blizzard's custom aura container picks the aura and
-- draws it: one aura slot per frame, filtered HARMFUL|CROWD_CONTROL, the plugin only giving it a
-- texture and a cooldown. So it keeps working in combat while WoW: Forever hides aura details from
-- addons. On the player the game's loss of control data goes on top: it also knows interrupts,
-- silences and roots, which are no aura.

local _, ns = ... ---@type string, AddonNamespace
local E = ElvUI[1]

local FILTER = "HARMFUL|CROWD_CONTROL"
local SLOT = "cc"
-- Levels above the icon's frame: the player's loss of control, then test mode's sample.
ns.LOSS_LEVEL, ns.PREVIEW_LEVEL = 5, 10

-- The player's parts, for the loss of control; nil until the player's frame is built.
---@type AddonHolder?
local player

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
---@param parent table
---@return table
local function Cooldown(holder, parent)
    local cooldown = CreateFrame("Cooldown", nil, parent, "CooldownFrameTemplate")
    cooldown:SetAllPoints(parent)
    cooldown:SetReverse(true)
    cooldown:SetDrawEdge(false)
    cooldown:SetHideCountdownNumbers(not ns.db().cc.numbers)
    holder.cooldowns[#holder.cooldowns + 1] = cooldown
    return cooldown
end

---An icon of the plugin's own above the aura slot: a texture and a countdown, hidden.
---@param holder AddonHolder
---@param level number
---@return AddonIconFrame
function ns.IconFrame(holder, level)
    local frame = CreateFrame("Frame", nil, holder.cc) --[[@as AddonIconFrame]]
    frame:SetAllPoints(holder.cc)
    frame:SetFrameLevel(holder.cc:GetFrameLevel() + level)
    frame.icon = Icon(frame)
    frame.cooldown = Cooldown(holder, frame)
    frame:Hide()
    return frame
end

---The aura container with its one slot, for the frame's unit. Errors on a client without one.
---@param holder AddonHolder
---@return table
local function Container(holder)
    local container = CreateFrame("AuraContainer", nil, holder.cc, "CustomAuraContainerTemplate")
    container:SetAllPoints(holder.cc)
    container:SetEditModePreviewEnabled(false)
    container:AddAuraSlot(SLOT, FILTER, {
        ---@param button table the game's aura button
        initializeFrame = function(button)
            button:SetAllPoints(holder.cc)
            button:EnableMouse(false)
            button:SetIcon(Icon(button))
            button:SetDurationCooldown(Cooldown(holder, button))
        end,
    })
    container:SetUnit(holder.frame.unit)
    return container
end

---Makes a frame's icon: the aura slot, and on the player the loss of control.
---@param holder AddonHolder
function ns.BuildCC(holder)
    holder.cooldowns = {}
    holder.cc = CreateFrame("Frame", nil, holder)
    holder.cc:SetFrameLevel(holder:GetFrameLevel() + 1)
    local ok, container = pcall(Container, holder)
    holder.container = ok and container or nil
    if holder.key == "player" then
        holder.loss = ns.IconFrame(holder, ns.LOSS_LEVEL)
        holder.loss.cooldown:SetScript("OnCooldownDone", ns.UpdateLoss)
        player = holder
    end
end

---Puts a frame's icon on its spot.
---@param holder AddonHolder
---@param region table
---@param point string
---@param size number
function ns.LayoutCC(holder, region, point, size)
    local cc = holder.cc
    cc:ClearAllPoints()
    cc:SetPoint(point, region, point, 0, 0)
    cc:SetSize(size, size)
end

---The aura slot shows the frame's unit, as it is now.
---@param holder AddonHolder
function ns.RefreshCC(holder)
    local container = holder.container
    if not container or not container:IsEnabled() then return end
    local unit = holder.frame.unit
    if container:GetUnit() ~= unit then container:SetUnit(unit) end
    container:UpdateAllAuras()
end

---A frame's icon after a settings change: on or off, countdown numbers.
---@param holder AddonHolder
function ns.ApplyCC(holder)
    local db = ns.db()
    local on = db.units[holder.key].cc
    holder.cc:SetShown(on)
    if holder.container then holder.container:SetEnabled(on) end
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

---The first entry the icon shows, in the game's order, and its index.
---@return LossOfControlData? data, number index
local function Entry()
    local count = C_LossOfControl.GetActiveLossOfControlDataCount()
    -- A hidden count cannot be looped over; the game's first entry is the one in force.
    if ns.IsSecret(count) then count = 1 end
    for index = 1, count do
        local data = C_LossOfControl.GetActiveLossOfControlData(index)
        if not ns.IsSecret(data) and data and Wanted(data) then return data, index end
    end
    return nil, 0
end

---The player's loss of control icon, as the game has it now. Hidden times come as the game's
---duration object; without one there is no countdown to show, so no icon either.
function ns.UpdateLoss()
    if not player then return end
    local loss = player.loss --[[@as AddonIconFrame]]
    local data, index = nil, 0
    if ns.db().units.player.cc then
        data, index = Entry()
    end
    local start, duration = data and data.startTime, data and data.duration
    local hidden = ns.IsSecret(start) or ns.IsSecret(duration)
    local object = data and hidden and C_LossOfControl.GetActiveLossOfControlDuration("player", index)
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
end
