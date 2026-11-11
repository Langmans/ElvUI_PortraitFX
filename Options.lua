-- The plugin's page in ElvUI's options, among the plugins in its side bar: test mode at the top,
-- then three tabs. Frames: a page per kind of frame (the text and the icon on or off, where each
-- sits), the strata and level, the debug addons. Combat text: its look, the kinds of event, the
-- colours. Crowd control: countdown numbers, interrupts, defensives.

local addon, ns = ... ---@type string, AddonNamespace
local E, P = ElvUI[1], ElvUI[4]
local L = LibStub("AceLocale-3.0"):GetLocale(addon)

-- The plugin's name in the side bar.
local TITLE = "|cffff4040%s|r"
local OUTLINES = { [""] = L.OUTLINE_NONE, OUTLINE = L.OUTLINE_OUTLINE, THICKOUTLINE = L.OUTLINE_THICK }
local KINDS = { "damage", "heals", "misses", "energize" }
local COLORS = { "physical", "spell", "heal", "power", "miss" }
-- The points the text and the icon can sit on, in the order of a 3x3 grid.
local POINT_ORDER = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }
local POINTS = {}
for _, point in ipairs(POINT_ORDER) do
    POINTS[point] = L["POINT_" .. point]
end
-- What the text and the icon can be anchored to (Spot.lua), with their names.
local ANCHORS = {}
for _, anchor in ipairs(ns.anchors) do
    ANCHORS[anchor] = L["ANCHOR_" .. anchor]
end
-- The client's frame stratas, bottom to top.
local STRATAS = { "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "FULLSCREEN", "FULLSCREEN_DIALOG", "TOOLTIP" }

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

---The parts' strata and level, as a box on the Frames tab.
---@return table
local function LayerBox()
    local stratas = { [""] = L.STRATA_OWN }
    for _, strata in ipairs(STRATAS) do
        stratas[strata] = strata
    end
    local sorting = { "" }
    for i, strata in ipairs(STRATAS) do
        sorting[i + 1] = strata
    end
    return {
        type = "group",
        inline = true,
        order = 50,
        name = L.LAYER,
        ---@param info string[]
        ---@return string|number
        get = function(info)
            return ns.db().layer[info[#info]] --[[@as string|number]]
        end,
        ---@param info string[]
        ---@param value string|number
        set = function(info, value)
            ns.db().layer[info[#info]] = value
            ns.ApplyAll()
        end,
        args = {
            strata = { type = "select", order = 1, name = L.STRATA, values = stratas, sorting = sorting },
            level = Range(2, L.LEVEL, L.LEVEL_DESC, 0, 100, 1),
        },
    }
end

---How much goes to the debug addons (Debug.lua), as a box on the Frames tab.
---@return table
local function DebugBox()
    local values = {}
    for _, level in ipairs(ns.debugLevels) do
        values[level] = L["DEBUG_" .. level]
    end
    return {
        type = "group",
        inline = true,
        order = 60,
        name = L.DEBUG,
        args = {
            level = {
                type = "select",
                order = 1,
                name = L.DEBUG_LEVEL,
                ---@return string
                desc = function()
                    return ns.HasDebugAddon() and L.DEBUG_DESC or L.DEBUG_DESC .. " " .. L.DEBUG_MISSING
                end,
                values = values,
                sorting = ns.debugLevels,
                ---@return string
                get = function()
                    return ns.db().debug
                end,
                ---@param _ table AceConfig's info
                ---@param level string
                set = function(_, level)
                    ns.db().debug = level
                end,
            },
        },
    }
end

---Where the text or the icon sits on a kind of frame, as a box on its page: what it is anchored to,
---the point on it and the offset. The icon on automatic picks its point itself.
---@param key string the kind of frame
---@param place "textPlace"|"ccPlace"
---@param order number
---@param name string
---@return table
local function PlaceBox(key, place, order, name)
    local point = {
        type = "select",
        order = 2,
        name = L.POINT,
        desc = L.POINT_DESC,
        values = POINTS,
        sorting = POINT_ORDER,
    }
    if place == "ccPlace" then
        ---@return boolean
        point.disabled = function()
            return ns.db().units[key].ccPlace.anchor == "auto"
        end
    end
    return {
        type = "group",
        inline = true,
        order = order,
        name = name,
        ---@param info string[]
        ---@return string|number
        get = function(info)
            return ns.db().units[key][place][info[#info]] --[[@as string|number]]
        end,
        ---@param info string[]
        ---@param value string|number
        set = function(info, value)
            ns.db().units[key][place][info[#info]] = value
            ns.ApplyAll()
        end,
        args = {
            anchor = {
                type = "select",
                order = 1,
                name = L.ANCHOR,
                desc = L.ANCHOR_DESC,
                values = ANCHORS,
                sorting = ns.anchors,
            },
            point = point,
            x = Range(3, L.X, nil, -200, 200, 1),
            y = Range(4, L.Y, nil, -200, 200, 1),
        },
    }
end

---A kind of frame's page: the text and the icon on or off, and where each sits.
---@param key string
---@param order number
---@return table
local function UnitPage(key, order)
    return {
        type = "group",
        order = order,
        name = L[key],
        args = {
            show = {
                type = "group",
                inline = true,
                order = 1,
                name = L.SHOW,
                ---@param info string[]
                ---@return boolean
                get = function(info)
                    return ns.db().units[key][info[#info]] --[[@as boolean]]
                end,
                ---@param info string[]
                ---@param value boolean
                set = function(info, value)
                    ns.db().units[key][info[#info]] = value
                    ns.ApplyAll()
                end,
                args = { text = Toggle(1, L.SHOW_TEXT), cc = Toggle(2, L.SHOW_CC) },
            },
            textPlace = PlaceBox(key, "textPlace", 2, L.TEXT_PLACE),
            ccPlace = PlaceBox(key, "ccPlace", 3, L.CC_PLACE),
        },
    }
end

---@return table
local function UnitsTab()
    local args = {}
    for order, key in ipairs(ns.unitOrder) do
        args[key] = UnitPage(key, order)
    end
    args.layer = LayerBox()
    args.debug = DebugBox()
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
        icons = Toggle(22, L.ICONS, L.ICONS_DESC),
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
            ns.ApplyAll()
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
            defensives = Toggle(3, L.DEFENSIVES, L.DEFENSIVES_DESC),
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
