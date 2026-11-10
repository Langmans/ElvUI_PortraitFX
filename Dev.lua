--@debug@
-- Screenshots for development: the first time each kind of moment from the in-game checks happens
-- (combat text per frame and portrait style, a hidden amount, the loss of control, test mode), a
-- grey chat line says which, then one screenshot. It hooks in like any other addon could. The whole
-- file is a --@debug@ block, so only a copy straight from the repository has it; off until switched
-- on, English only (README > Screenshots while testing in game).

local addon, ns = ... ---@type string, AddonNamespace
local E, G = ElvUI[1], ElvUI[5]

local SHOT_DELAY = 0.3 -- seconds for the game to draw what changed before the screenshot
local SHOT_GAP = 2 -- seconds at least between two screenshots
local lastShot = -SHOT_GAP
-- The kinds noticed in the moment being looked at, for one screenshot together.
---@type string[]
local pending = {}

G[addon] = { dev = { on = false, shots = {} } }

---@return AddonDevData
local function Dev()
    return E.global[addon].dev
end

---The screenshot itself. C_Timer.After takes only a Lua function, not the client's Screenshot.
local function TakeScreenshot()
    Screenshot()
end

---Notes a kind for this moment's screenshot, when switched on and not shot yet.
---@param kind string
local function Notice(kind)
    local dev = Dev()
    if not dev.on or dev.shots[kind] then return end
    pending[#pending + 1] = kind
end

---One screenshot for the kinds noticed, each said in chat first. Within SHOT_GAP of the last one
---there is none, and the kinds stay unmarked, so they are shot the next time.
local function Flush()
    if #pending == 0 then return end
    if GetTime() - lastShot < SHOT_GAP then
        wipe(pending)
        return
    end
    local shots = Dev().shots
    for _, kind in ipairs(pending) do
        shots[kind] = true
        print("|cff888888[" .. addon .. " dev] " .. kind .. "|r")
    end
    wipe(pending)
    lastShot = GetTime()
    C_Timer.After(SHOT_DELAY, TakeScreenshot)
end

---Where a frame's portrait is, in words.
---@param frame AddonFrame
---@return string
local function Style(frame)
    if not frame.USE_PORTRAIT then return "no portrait" end
    return frame.USE_PORTRAIT_OVERLAY and "overlay" or "side portrait"
end

---@param holder AddonHolder
---@param _ string|AddonSecret the event
---@param __ string|AddonSecret the flags
---@param amount number|AddonSecret
hooksecurefunc(ns, "ShowText", function(holder, _, __, amount)
    if ns.testing or holder.started ~= GetTime() or not holder.text:IsShown() then return end
    Notice("combat text: " .. holder.key .. ", " .. Style(holder.frame))
    if ns.IsSecret(amount) then Notice("combat text: hidden amount") end
    Flush()
end)

---@param holder AddonHolder
hooksecurefunc(ns, "UpdateLoss", function(holder)
    if not holder.loss:IsShown() then return end
    Notice("loss of control: " .. holder.key)
    Flush()
end)

---@param on boolean
hooksecurefunc(ns, "SetTesting", function(on)
    if not on then return end
    Notice("test mode")
    Flush()
end)

---The switch and the forget button, a box on the Frames tab.
---@return table
function ns.DevOptions()
    return {
        type = "group",
        inline = true,
        name = "Development",
        order = 100,
        args = {
            on = {
                type = "toggle",
                name = "Dev screenshots",
                desc = "A screenshot the first time each kind of moment from the in-game checks happens. Repository copies only.",
                order = 1,
                get = function()
                    return Dev().on
                end,
                ---@param _ table AceConfig's info
                ---@param value boolean
                set = function(_, value)
                    Dev().on = value
                end,
            },
            forget = {
                type = "execute",
                name = "Forget the screenshots taken",
                order = 2,
                func = function()
                    wipe(Dev().shots)
                end,
            },
        },
    }
end
--@end-debug@
