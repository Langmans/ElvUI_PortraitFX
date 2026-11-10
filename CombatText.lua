-- Combat text on the portrait: what UNIT_COMBAT says happened to the frame's unit, faded in, held
-- and faded out with the timings of Blizzard's own portrait text (CombatFeedback.lua), in its words
-- (CombatFeedbackText) and sizes. Blizzard's functions themselves cannot be borrowed: they compare
-- the event's values, which an addon may not do with values WoW: Forever hides. Here a hidden amount
-- only goes to the game's number formatters, and the flags decide what it means.

local _, ns = ... ---@type string, AddonNamespace
local E = ElvUI[1]

local PHYSICAL = Enum.Damageclass.MaskPhysical
-- Sizes beside a normal hit, as Blizzard's portrait text has them.
local GLANCING, SMALL, IMMUNE = 0.75, 0.75, 0.5

-- Spell damage per school, when coloured by school; another school or several are the spell colour.
local D = Enum.Damageclass
ns.schoolColors = {
    [D.MaskHoly] = { 1, 0.9, 0.5 },
    [D.MaskFire] = { 1, 0.5, 0 },
    [D.MaskNature] = { 0.3, 0.85, 0.3 },
    [D.MaskFrost] = { 0.4, 0.8, 1 },
    [D.MaskShadow] = { 0.6, 0.4, 0.9 },
    [D.MaskArcane] = { 1, 0.5, 1 },
}

-- Blizzard's words for what is shown as a word, by event or flag (FrameXML's CombatFeedback.lua).
---@type table<string, string>
local WORDS = CombatFeedbackText
-- Flags that name damage avoided in full when the amount is 0, and the word for it.
local AVOIDED = { ABSORB = true, BLOCK = true, RESIST = true }
-- The word's size, for the events shown as a word.
local WORD_SIZES = { IMMUNE = IMMUNE, BLOCK = SMALL }

---An amount as text, by the game's formatters, which take a hidden amount too (and hide the text).
---@param amount number|AddonSecret
---@param text AddonTextSettings
---@return string|AddonSecret
local function Amount(amount, text)
    ---@cast amount number
    if text.short then return AbbreviateNumbers(amount, E.Abbreviate.short) end
    return BreakUpLargeNumbers(amount)
end

---Whether a hit did no damage: an amount of 0, or, when the amount is hidden, flags that name a
---full absorb, block or resist.
---@param flags string
---@param amount number|AddonSecret
---@return boolean
local function Avoided(flags, amount)
    if ns.IsSecret(amount) then return AVOIDED[flags] or false end
    return amount == 0
end

---The colour of damage of a school; a hidden school is spell damage.
---@param school number|AddonSecret
---@param text AddonTextSettings
---@return number r, number g, number b
local function DamageColor(school, text)
    local colors = text.colors
    if ns.IsSecret(school) then return colors.spell.r, colors.spell.g, colors.spell.b end
    if school == PHYSICAL then return colors.physical.r, colors.physical.g, colors.physical.b end
    local own = text.schools and ns.schoolColors[school]
    if own then return own[1], own[2], own[3] end
    return colors.spell.r, colors.spell.g, colors.spell.b
end

---What to show for an event: a format with one %s, what fills it, the size beside a normal hit and
---the colour. Nothing for an event switched off, one without a word, or one the client hides.
---@param event string|AddonSecret
---@param flags string|AddonSecret
---@param amount number|AddonSecret
---@param school number|AddonSecret
---@return string? format, (string|AddonSecret)? value, number? scale, number? r, number? g, number? b
function ns.Feedback(event, flags, amount, school)
    if ns.IsSecret(event) or ns.IsSecret(flags) then return nil end
    ---@cast event string
    ---@cast flags string
    local text = ns.db().text
    local colors = text.colors
    if event == "WOUND" and not Avoided(flags, amount) then
        if not text.damage then return nil end
        local scale = 1
        if flags == "CRITICAL" or flags == "CRUSHING" then
            scale = text.crit
        elseif flags == "GLANCING" then
            scale = GLANCING
        end
        local format = flags == "BLOCK_REDUCED" and COMBAT_TEXT_BLOCK_REDUCED or "%s"
        return format, Amount(amount, text), scale, DamageColor(school, text)
    elseif event == "HEAL" or event == "ENERGIZE" then
        local heal = event == "HEAL"
        if not (heal and text.heals or not heal and text.energize) then return nil end
        local color = heal and colors.heal or colors.power
        return "%s", Amount(amount, text), flags == "CRITICAL" and text.crit or 1, color.r, color.g, color.b
    end
    if not text.misses then return nil end
    ---@type string?, number
    local word, scale
    if event == "WOUND" then
        word = WORDS[AVOIDED[flags] and flags or "MISS"]
        scale = AVOIDED[flags] and SMALL or 1
    else
        word, scale = WORDS[event], WORD_SIZES[event] or 1
    end
    if not word then return nil end
    return "%s", word, scale, colors.miss.r, colors.miss.g, colors.miss.b
end

---Fades the text in, holds it and fades it out.
---@param holder AddonHolder
local function Fade(holder)
    local fadeIn, hold, fadeOut = COMBATFEEDBACK_FADEINTIME, ns.db().text.hold, COMBATFEEDBACK_FADEOUTTIME
    local t = GetTime() - holder.started
    if t < fadeIn then
        holder.text:SetAlpha(t / fadeIn)
    elseif t < fadeIn + hold then
        holder.text:SetAlpha(1)
    elseif t < fadeIn + hold + fadeOut then
        holder.text:SetAlpha(1 - (t - fadeIn - hold) / fadeOut)
    else
        ns.HideText(holder)
    end
end

---Shows an event on a frame, if its text is switched on.
---@param holder AddonHolder
---@param event string|AddonSecret
---@param flags string|AddonSecret
---@param amount number|AddonSecret
---@param school number|AddonSecret
function ns.ShowText(holder, event, flags, amount, school)
    local db = ns.db()
    if not db.units[holder.key].text then
        ns.Log("debug", "combat: text is off on {1}", holder.key)
        return
    end
    local format, value, scale, r, g, b = ns.Feedback(event, flags, amount, school)
    if not format then
        if ns.Logging("debug") then
            ns.Log("debug", "combat: nothing to show for {1} {2}", ns.Shown(event), ns.Shown(flags))
        end
        return
    end
    ---@cast value string
    ---@cast scale number
    ---@cast r number
    ---@cast g number
    ---@cast b number
    local text, look = holder.text, db.text
    text:SetFont(E.LSM:Fetch("font", look.font), holder.size * look.size * scale, look.outline)
    text:SetFormattedText(format, value)
    text:SetTextColor(r, g, b)
    text:SetAlpha(0)
    text:Show()
    holder.started = GetTime()
    holder:SetScript("OnUpdate", Fade)
end

---Hides a frame's text at once.
---@param holder AddonHolder
function ns.HideText(holder)
    holder.text:Hide()
    holder:SetScript("OnUpdate", nil)
end
