-- The plugin's page in ElvUI's options, among the plugins in its side bar: test mode at the top,
-- then three tabs. Frames: per frame the text and the icon. Combat text: its look, the kinds of
-- event, the colours. Crowd control: countdown numbers and the player's interrupts.

local addon, ns = ... ---@type string, AddonNamespace
local E, P = ElvUI[1], ElvUI[4]
local L = LibStub("AceLocale-3.0"):GetLocale(addon)

-- The plugin's name in the side bar.
local TITLE = "|cffff4040%s|r"
local OUTLINES = { [""] = L.OUTLINE_NONE, OUTLINE = L.OUTLINE_OUTLINE, THICKOUTLINE = L.OUTLINE_THICK }
local KINDS = { "damage", "heals", "misses", "energize" }
local COLORS = { "physical", "spell", "heal", "power", "miss" }

---@param order number
---@param name string
---@param desc string?
---@return table
local function Toggle(order, name, desc)
    return { type = "toggle", order = order, name = name, desc = desc }
end

---@param order number
---@param name string
---@param desc string?
---@param min number
---@param max number
---@param step number
---@return table
local function Range(order, name, desc, min, max, step)
    return { type = "range", order = order, name = name, desc = desc, min = min, max = max, step = step }
end

---@return table
local function UnitsTab()
    local args = {}
    for order, key in ipairs(ns.unitOrder) do
        args[key] = {
            type = "group",
            inline = true,
            order = order,
            name = L[key],
            ---@param info string[]
            ---@return boolean
            get = function(info)
                return ns.db().units[info[#info - 1]][info[#info]] --[[@as boolean]]
            end,
            ---@param info string[]
            ---@param value boolean
            set = function(info, value)
                ns.db().units[info[#info - 1]][info[#info]] = value
                ns.ApplyAll()
            end,
            args = { text = Toggle(1, L.SHOW_TEXT), cc = Toggle(2, L.SHOW_CC) },
        }
    end
    args.dev = ns.DevOptions and ns.DevOptions()
    return { type = "group", order = 1, name = L.UNITS, args = args }
end

---@return table
local function ColorsBox()
    local args = {
        reset = {
            type = "execute",
            order = 100,
            name = L.RESET,
            func = function()
                for key, color in pairs(P[addon].text.colors) do
                    local own = ns.db().text.colors[key] --[[@as AddonColor]]
                    own.r, own.g, own.b = color.r, color.g, color.b
                end
            end,
        },
    }
    for order, key in ipairs(COLORS) do
        args[key] = { type = "color", order = order, name = L[key] }
    end
    return {
        type = "group",
        inline = true,
        order = 30,
        name = L.COLORS,
        ---@param info string[]
        ---@return number, number, number
        get = function(info)
            local c = ns.db().text.colors[info[#info]] --[[@as AddonColor]]
            return c.r, c.g, c.b
        end,
        ---@param info string[]
        ---@param r number
        ---@param g number
        ---@param b number
        set = function(info, r, g, b)
            local c = ns.db().text.colors[info[#info]] --[[@as AddonColor]]
            c.r, c.g, c.b = r, g, b
        end,
        args = args,
    }
end

---@return table
local function TextTab()
    local args = {
        font = {
            type = "select",
            order = 1,
            name = L.FONT,
            dialogControl = "LSM30_Font",
            values = AceGUIWidgetLSMlists.font,
        },
        size = Range(2, L.SIZE, L.SIZE_DESC, 0.2, 1.5, 0.05),
        outline = { type = "select", order = 3, name = L.OUTLINE, values = OUTLINES },
        crit = Range(4, L.CRIT, L.CRIT_DESC, 1, 3, 0.05),
        hold = Range(5, L.HOLD, L.HOLD_DESC, 0.2, 3, 0.1),
        kinds = { type = "header", order = 10, name = L.KINDS },
        short = Toggle(20, L.SHORT, L.SHORT_DESC),
        schools = Toggle(21, L.SCHOOLS, L.SCHOOLS_DESC),
        colors = ColorsBox(),
    }
    args.size.isPercent = true
    for order, key in ipairs(KINDS) do
        args[key] = Toggle(10 + order, L[key])
    end
    return {
        type = "group",
        order = 2,
        name = L.TEXT,
        ---@param info string[]
        ---@return string|number|boolean
        get = function(info)
            return ns.db().text[info[#info]] --[[@as string|number|boolean]]
        end,
        ---@param info string[]
        ---@param value string|number|boolean
        set = function(info, value)
            ns.db().text[info[#info]] = value
        end,
        args = args,
    }
end

---@return table
local function CrowdControlTab()
    return {
        type = "group",
        order = 3,
        name = L.CC,
        ---@param info string[]
        ---@return boolean
        get = function(info)
            return ns.db().cc[info[#info]] --[[@as boolean]]
        end,
        ---@param info string[]
        ---@param value boolean
        set = function(info, value)
            ns.db().cc[info[#info]] = value
            ns.ApplyAll()
        end,
        args = {
            desc = { type = "description", order = 0, name = L.CC_DESC },
            numbers = Toggle(1, L.NUMBERS),
            interrupts = Toggle(2, L.INTERRUPTS),
        },
    }
end

---LibElvUIPlugin calls this once ElvUI's options are loaded.
function ns.InsertOptions()
    if not E.Options then return end
    E.Options.args[addon] = {
        type = "group",
        name = TITLE:format(L.OPTIONS),
        childGroups = "tab",
        args = {
            desc = { type = "description", order = 0, name = L.OPTIONS_DESC },
            test = {
                type = "toggle",
                order = 1,
                name = L.TEST,
                desc = L.TEST_DESC,
                ---@return boolean
                get = function()
                    return ns.testing or false
                end,
                ---@param _ table AceConfig's info
                ---@param on boolean
                set = function(_, on)
                    ns.SetTesting(on)
                end,
            },
            units = UnitsTab(),
            text = TextTab(),
            cc = CrowdControlTab(),
        },
    }
end
