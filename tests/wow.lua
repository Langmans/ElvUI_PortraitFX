-- A simulated WoW: Forever client for the plugin. The game: frames, font strings, textures and
-- cooldowns as far as the plugin uses them, UNIT_COMBAT, the loss of control API, Blizzard's custom
-- aura container, timers and the number formatters. ElvUI: E with its profile, global data, fonts
-- and modules, the UnitFrames module with Configure_Portrait and oUF's frames (portrait beside the
-- bars, as an overlay on the health bar, or none), LibElvUIPlugin and the options table.
-- NewClient() resets the globals, loads the .toc's files and logs in: ElvUI builds its frames,
-- then initialises the plugin's module, as it does with its plugins' modules after its own.

---@class TestClientOptions
---@field name string? the addon's folder name, the repository's by default
---@field dev boolean? a copy straight from the repository: `--@debug@` blocks run (Dev.lua)
---@field noAuraContainer boolean? a client without Blizzard's custom aura container
---@field noOptions boolean? ElvUI_Options not loaded
---@field noRaised boolean? frames without ElvUI's raised element parent
---@field noSecretCheck boolean? a client without issecretvalue, which hides nothing
---@field oapDebug boolean? OAP Debug installed: its calls go to client.debugCalls
---@field debugLog boolean? _DebugLog installed (DLAPI): its lines go to client.debugCalls too
---@field debugLevel string? the plugin's debug setting in the profile
---@field brokenContainer boolean? the aura container is there, but adding a slot errors

-- What the client returns for a value it hides (issecretvalue says so).
SECRET = setmetatable({}, {
    __tostring = function()
        return "<secret>"
    end,
})

---A file's source as the client gets it: from a release, where the packager comments out every line
---between `--@debug@` and `--@end-debug@`, unless `dev`. The line count stays, so coverage still
---points at the right lines.
---@param file string
---@param dev boolean
---@return string
local function AsPackaged(file, dev)
    local handle = assert(io.open(file, "rb"))
    local source = handle:read("*a")
    handle:close()
    if dev or not source:find("--@debug@", 1, true) then return source end
    local lines, inDebug = {}, false
    for line in (source .. "\n"):gmatch("(.-)\r?\n") do
        if line:match("^%s*%-%-@end%-debug@") then
            inDebug = false
        elseif inDebug then
            line = "--" .. line
        elseif line:match("^%s*%-%-@debug@") then
            inDebug = true
        end
        lines[#lines + 1] = line
    end
    return table.concat(lines, "\n")
end

---@param t table
---@return table
local function copy(t)
    local c = {}
    for k, v in pairs(t) do
        c[k] = type(v) == "table" and copy(v) or v
    end
    return c
end

---@param opts TestClientOptions?
function NewClient(opts)
    opts = opts or {}
    local name = opts.name or ADDON_NAME
    local client = {
        now = 1000,
        calls = {},
        events = {},
        modules = {},
        ns = {},
        frames = {},
        regions = {},
        timers = {},
        tickers = {},
        printed = {},
        screenshots = 0,
        loss = {},
        containers = {},
    }

    local function record(what, ...)
        client.calls[#client.calls + 1] = { what, ... }
    end
    ---The calls recorded under a name, each without it.
    function client:called(what)
        local found = {}
        for _, call in ipairs(self.calls) do
            if call[1] == what then found[#found + 1] = { unpack(call, 2) } end
        end
        return found
    end

    issecretvalue = not opts.noSecretCheck and function(v)
        return v == SECRET
    end or nil
    function GetTime()
        return client.now
    end
    function print(...)
        client.printed[#client.printed + 1] = table.concat({ ... }, " ")
    end
    function Screenshot()
        client.screenshots = client.screenshots + 1
    end
    function wipe(t)
        for k in pairs(t) do
            t[k] = nil
        end
        return t
    end
    function hooksecurefunc(object, method, hook)
        local original = object[method]
        object[method] = function(...)
            local results = { original(...) }
            hook(...)
            return unpack(results)
        end
    end
    function InCombatLockdown()
        return client.inCombat or false
    end
    C_Timer = {
        After = function(delay, fn)
            client.timers[#client.timers + 1] = { at = client.now + delay, fn = fn }
        end,
        NewTicker = function(interval, fn)
            local ticker = { interval = interval, fn = fn, next = client.now + interval }
            function ticker:Cancel()
                self.cancelled = true
            end
            client.tickers[#client.tickers + 1] = ticker
            return ticker
        end,
    }
    -- Blizzard's words and constants for combat feedback, as GlobalStrings and CombatFeedback.lua
    -- have them.
    MISS, DODGE, PARRY, BLOCK, IMMUNE, ABSORB, RESIST = "Miss", "Dodge", "Parry", "Block", "Immune", "Absorb", "Resist"
    EVADE, DEFLECT, REFLECT, INTERRUPT = "Evade", "Deflect", "Reflect", "Interrupt"
    COMBATFEEDBACK_FADEINTIME, COMBATFEEDBACK_HOLDTIME, COMBATFEEDBACK_FADEOUTTIME = 0.2, 0.7, 0.3
    CombatFeedbackText = {
        INTERRUPT = INTERRUPT,
        MISS = MISS,
        RESIST = RESIST,
        DODGE = DODGE,
        PARRY = PARRY,
        BLOCK = BLOCK,
        EVADE = EVADE,
        IMMUNE = IMMUNE,
        DEFLECT = DEFLECT,
        ABSORB = ABSORB,
        REFLECT = REFLECT,
    }
    Enum = {
        Damageclass = {
            MaskPhysical = 1,
            MaskHoly = 2,
            MaskFire = 4,
            MaskNature = 8,
            MaskFrost = 16,
            MaskShadow = 32,
            MaskArcane = 64,
        },
    }

    -- The number formatters take hidden numbers and hand back hidden text.
    function BreakUpLargeNumbers(n)
        if n == SECRET then return SECRET end
        local s = tostring(math.floor(n))
        local formatted = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
        return (formatted:gsub("^,", ""))
    end
    function AbbreviateNumbers(n, options)
        if n == SECRET then return SECRET end
        record("AbbreviateNumbers", n, options)
        if n >= 1000 then return ("%.1fK"):format(n / 1000) end
        return tostring(n)
    end

    -- The loss of control API per unit: client.loss[unit] holds a unit's entries, in the client's
    -- order; client.lossCount[unit], when set, is the count the client gives instead (SECRET).
    client.lossCount = {}
    Constants = { LossOfControlConsts = { LOSS_OF_CONTROL_ACTIVE_INDEX = 1 } }
    C_LossOfControl = {
        GetActiveLossOfControlDataCountByUnit = function(unit)
            assert(type(unit) == "string", "Usage: GetActiveLossOfControlDataCountByUnit(unitToken)")
            return client.lossCount[unit] or #(client.loss[unit] or {})
        end,
        GetActiveLossOfControlDataByUnit = function(unit, index)
            return (client.loss[unit] or {})[index]
        end,
        GetActiveLossOfControlDuration = function(unit, index)
            local entry = (client.loss[unit] or {})[index]
            return entry and entry.durationObject
        end,
    }

    ---A frame, texture, font string or cooldown: what the plugin calls on one.
    ---@param kind string
    ---@param parent table?
    ---@return table
    local function Region(kind, parent)
        local r = {
            kind = kind,
            parent = parent,
            shown = true,
            points = {},
            scripts = {},
            alpha = 1,
            level = parent and parent.level and parent.level + 1 or 1,
            width = 0,
            height = 0,
        }
        client.regions[#client.regions + 1] = r
        function r:Show()
            self.shown = true
        end
        function r:Hide()
            self.shown = false
        end
        function r:SetShown(v)
            self.shown = not not v
        end
        function r:IsShown()
            return self.shown
        end
        function r:IsVisible()
            return self.shown and (not self.parent or not self.parent.IsVisible or self.parent:IsVisible())
        end
        function r:SetAlpha(a)
            self.alpha = a
        end
        function r:GetAlpha()
            return self.alpha
        end
        function r:ClearAllPoints()
            self.points = {}
        end
        function r:SetPoint(point, relativeTo, relativePoint, x, y)
            self.points[point] = { relativeTo, relativePoint or point, x or 0, y or 0 }
        end
        function r:SetAllPoints(relativeTo)
            self.points = { ALL = { relativeTo or self.parent } }
        end
        function r:SetSize(w, h)
            self.width, self.height = w, h
        end
        function r:GetWidth()
            return self.width
        end
        function r:GetHeight()
            return self.height
        end
        function r:SetParent(p)
            self.parent = p
        end
        function r:SetFrameLevel(level)
            self.level = level
        end
        ---A frame's own strata, else its parent's, as the client inherits it.
        function r:SetFrameStrata(strata)
            self.strata = strata
        end
        function r:GetFrameStrata()
            return self.strata
                or (self.parent and self.parent.GetFrameStrata and self.parent:GetFrameStrata())
                or "MEDIUM"
        end
        function r:GetFrameLevel()
            return self.level
        end
        function r:EnableMouse(on)
            self.mouse = on
        end
        ---As the client: a unit event registered again replaces the unit it was registered for.
        function r:RegisterUnitEvent(event, unit)
            assert(type(unit) == "string", "Usage: RegisterUnitEvent(event, unit)")
            self.unitEvents = self.unitEvents or {}
            self.unitEvents[event] = unit
        end
        function r:UnregisterAllEvents()
            self.unitEvents = {}
        end
        function r:SetScript(script, fn)
            self.scripts[script] = fn
        end
        function r:GetScript(script)
            return self.scripts[script]
        end
        function r:CreateTexture(_, layer)
            local t = Region("Texture", self)
            t.layer = layer
            return t
        end
        function r:CreateFontString(_, layer)
            local f = Region("FontString", self)
            f.layer = layer
            return f
        end
        -- Textures.
        function r:SetTexture(path)
            self.texture = path
        end
        function r:SetTexCoord(...)
            self.texCoord = { ... }
        end
        -- Font strings.
        function r:SetFont(file, size, outline)
            self.font = { file, size, outline }
        end
        function r:GetFont()
            return unpack(self.font or {})
        end
        function r:SetText(text)
            self.text = text
        end
        function r:SetFormattedText(format, ...)
            local values = { ... }
            for i, v in ipairs(values) do
                if v == SECRET then values[i] = "<secret>" end
            end
            self.text = format:format(unpack(values))
        end
        function r:GetText()
            return self.text
        end
        function r:SetTextColor(red, green, blue)
            self.color = { red, green, blue }
        end
        function r:SetShadowOffset(x, y)
            self.shadow = { x, y }
        end
        -- Cooldowns.
        function r:SetCooldown(start, duration)
            self.cooldown = { start, duration }
            self.durationObject = nil
        end
        function r:SetCooldownFromDurationObject(duration)
            self.durationObject = duration
            self.cooldown = nil
        end
        function r:Clear()
            self.cooldown, self.durationObject = nil, nil
        end
        function r:SetReverse(on)
            self.reverse = on
        end
        function r:SetDrawEdge(on)
            self.drawEdge = on
        end
        function r:SetHideCountdownNumbers(hide)
            self.hideNumbers = hide
        end
        return r
    end

    ---Blizzard's custom aura container: one aura slot per call to AddAuraSlot, the game's own button.
    ---@param parent table?
    ---@return table
    local function AuraContainer(parent)
        local c = Region("AuraContainer", parent)
        c.slots, c.updates, c.enabled, c.preview = {}, 0, true, true
        function c:SetEditModePreviewEnabled(on)
            self.preview = on
        end
        function c:SetEnabled(on)
            self.enabled = on
        end
        function c:IsEnabled()
            return self.enabled
        end
        function c:SetUnit(unit)
            assert(type(unit) == "string", "unitToken must be a string")
            self.unit = unit
        end
        function c:GetUnit()
            return self.unit
        end
        function c:UpdateAllAuras()
            self.updates = self.updates + 1
        end
        function c:SetAuraSlotEnabled(key, on)
            assert(type(on) == "boolean", "enabled must be a boolean.")
            self.slots[key].enabled = on
        end
        function c:AddAuraSlot(key, filter, options)
            assert(not opts.brokenContainer, "aura slot '" .. key .. "' could not be added")
            assert(not self.slots[key], "one slot per key")
            local button = Region("CustomAuraButton", self)
            function button:SetIcon(texture)
                self.icon = texture
            end
            function button:SetDurationCooldown(cooldown)
                assert(cooldown.kind == "Cooldown", "a Cooldown")
                self.durationCooldown = cooldown
            end
            button:Hide()
            self.slots[key] = { filter = filter, options = options, button = button, enabled = true }
            if options and options.initializeFrame then options.initializeFrame(button) end
            return button
        end
        client.containers[#client.containers + 1] = c
        return c
    end

    function CreateFrame(kind, _, parent, template)
        if kind == "AuraContainer" then
            assert(not opts.noAuraContainer, "Unknown frame type 'AuraContainer'")
            assert(template == "CustomAuraContainerTemplate", "the custom aura container")
            return AuraContainer(parent)
        end
        local f = Region(kind, parent)
        f.template = template
        return f
    end

    -- LibStub with the libraries the plugin asks for: AceLocale (enough of it) and LibElvUIPlugin.
    local locales = {}
    local libs = {
        ["AceLocale-3.0"] = {
            NewLocale = function(_, app, _, isDefault)
                if not isDefault then return nil end
                locales[app] = setmetatable({}, {
                    __newindex = function(t, k, v)
                        rawset(t, k, v == true and k or v)
                    end,
                })
                return locales[app]
            end,
            GetLocale = function(_, app)
                return locales[app]
            end,
        },
        ["LibElvUIPlugin-1.0"] = {
            RegisterPlugin = function(_, plugin, callback)
                record("RegisterPlugin", plugin)
                client.optionsCallback = callback
            end,
        },
    }
    function LibStub(lib)
        return assert(libs[lib], "no library " .. lib)
    end

    -- ElvUI: E with its modules, profile defaults (P) and global defaults (G), fonts, the
    -- UnitFrames module.
    local E, P, G = { Modern = true, TexCoords = { 0.08, 0.92, 0.08, 0.92 } }, {}, {}
    E.LSM = {
        Fetch = function(_, kind, font)
            assert(kind == "font", "a font")
            return "Fonts\\" .. font .. ".ttf"
        end,
    }
    E.Abbreviate = { short = { config = "elvui-style" } }
    E.Options = not opts.noOptions and { args = {} } or nil
    -- ElvUI_Options' font list for LSM30_Font selects.
    AceGUIWidgetLSMlists = { font = {} }
    E.Libs = {
        AceConfigRegistry = {
            NotifyChange = function(_, app)
                record("NotifyChange", app)
            end,
        },
        AceConfigDialog = { OpenFrames = {} },
    }
    ---ElvUI's /ec: opens its options window.
    function E:ToggleOptions()
        self.Libs.AceConfigDialog.OpenFrames.ElvUI = {}
    end
    local UF = {}
    client.UF, client.E = UF, E

    function E:GetModule(module)
        if module == "UnitFrames" then return UF end
        return client.modules[module]
    end
    function E:NewModule(module)
        local m = { name = module }
        function m:GetName()
            return self.name
        end
        function m:RegisterEvent(event, handler)
            client.events[event] = { module = self, handler = handler or event }
        end
        function m:UnregisterEvent(event)
            client.events[event] = nil
        end
        ---As AceHook's SecureHook: the handler runs after the original, with its arguments.
        function m:SecureHook(object, method, handler)
            local original = object[method]
            object[method] = function(...)
                local results = { original(...) }
                self[handler](self, ...)
                return unpack(results)
            end
        end
        client.modules[module] = m
        return m
    end
    function E:RegisterModule(module)
        record("RegisterModule", module)
    end

    ---ElvUI's Configure_Portrait runs on every settings change of a frame; the plugin hooks it.
    function UF:Configure_Portrait(frame)
        record("Configure_Portrait", frame.unitframeType)
    end

    -- oUF's list of every frame it spawned.
    E.oUF = { objects = {} }

    ---A unit frame as ElvUI builds it: a health bar, a portrait with its backdrop, and the raised
    ---element parent its texts sit on.
    ---@param unit string the frame's unit, also its key in client.frames
    ---@param kind string? ElvUI's unitframeType, when not the unit ("party" for party1)
    ---@param style "side"|"overlay"|"none"|nil where the portrait is, "side" by default
    ---@param noUnit boolean? oUF has not given the frame its unit yet, as a party button's
    ---@return table
    function client:BuildFrame(unit, kind, style, noUnit)
        local frame = Region("Button")
        -- ElvUI's oUF keeps the unit in __unit (Private.UpdateUnits); there is no frame.unit.
        frame.unitframeType, frame.__unit, frame.ORIENTATION = kind or unit, not noUnit and unit or nil, "LEFT"
        frame.Health = Region("StatusBar", frame)
        frame.Power = Region("StatusBar", frame)
        frame.Health:SetSize(200, 40)
        local portrait = Region("PlayerModel", frame)
        portrait.backdrop = Region("Frame", frame)
        portrait.backdrop:SetSize(45, 45)
        frame.Portrait = portrait
        if not opts.noRaised then
            frame.RaisedElementParent = Region("Frame", frame)
            frame.RaisedElementParent.level = 100
        end
        E.oUF.objects[#E.oUF.objects + 1] = frame
        self.frames[unit] = frame
        self:Style(unit, style or "side")
        return frame
    end
    ---Changes where a frame's portrait is, as ElvUI's settings do, then runs Configure_Portrait.
    ---@param unit string
    ---@param style "side"|"overlay"|"none"
    function client:Style(unit, style)
        local frame = self.frames[unit]
        frame.USE_PORTRAIT = style ~= "none"
        frame.USE_PORTRAIT_OVERLAY = style == "overlay"
        -- ElvUI's Configure_Portrait: portrait:SetShown(frame.USE_PORTRAIT).
        frame.Portrait:SetShown(frame.USE_PORTRAIT)
        if self.loggedIn then UF:Configure_Portrait(frame) end
        return self
    end

    ElvUI = { E, {}, {}, P, G }

    -- The debug addons, loaded before the plugin (its OptionalDeps): every call recorded as
    -- { name, ... } in client.debugCalls.
    client.debugCalls = {}
    local function recorder(call)
        return function(...)
            client.debugCalls[#client.debugCalls + 1] = { call, ... }
        end
    end
    OAPDebug = opts.oapDebug and { Register = recorder("Register"), Log = recorder("Log"), Count = recorder("Count") }
        or nil
    DLAPI = opts.debugLog and { DebugLog = recorder("DebugLog") } or nil
    ---The debug calls of one kind, without their name.
    function client:debug(call)
        local found = {}
        for _, entry in ipairs(self.debugCalls) do
            if entry[1] == call then found[#found + 1] = { unpack(entry, 2) } end
        end
        return found
    end
    ---Whether a debug line's message (OAP Debug's, before its values) contains text.
    function client:logged(text)
        for _, entry in ipairs(self:debug("Log")) do
            if entry[2]:find(text, 1, true) then return true end
        end
        return false
    end

    for _, file in ipairs(TOC_FILES) do
        assert(loadstring(AsPackaged(file, opts.dev), "@" .. file))(name, client.ns)
    end

    -- Login: ElvUI reads the profile and global data (defaults included), builds its unit frames,
    -- then initialises the plugin's module.
    E.db, E.global = copy(P), copy(G)
    if opts.debugLevel then E.db[name].debug = opts.debugLevel end
    client:BuildFrame("player")
    client:BuildFrame("target")
    client:BuildFrame("focus")
    client:BuildFrame("pet")
    client:BuildFrame("party1", "party")
    client:BuildFrame("party2", "party")
    -- The party's pets and targets are child frames of their own unitframeType.
    client:BuildFrame("partypet1", "party").isChild = true
    client:BuildFrame("targettarget")
    for _, frame in ipairs(E.oUF.objects) do
        UF:Configure_Portrait(frame)
    end
    for _, module in pairs(client.modules) do
        module:Initialize()
    end
    client.loggedIn = true

    ---Fires an event at the module that registered it, as AceEvent does.
    ---A unit event (its first argument the unit) also goes to each frame that registered it for
    ---that unit, as the client delivers RegisterUnitEvent's events.
    function client:Fire(event, ...)
        local entry = self.events[event]
        if entry then entry.module[entry.handler](entry.module, event, ...) end
        local unit = ...
        for _, region in ipairs(self.regions) do
            local events = region.unitEvents
            if events and events[event] == unit and region.scripts.OnEvent then
                region.scripts.OnEvent(region, event, ...)
            end
        end
        return self
    end
    ---A UNIT_COMBAT event: what happened to a unit.
    function client:Combat(unit, event, flags, amount, school)
        return self:Fire("UNIT_COMBAT", unit, event, flags or "", amount or 0, school or 1)
    end
    ---Time passes: due timers and tickers run, then every shown region's OnUpdate.
    ---@param seconds number
    function client:Advance(seconds)
        local step = 0.05
        local passed = 0
        while passed < seconds - 1e-9 do
            local dt = math.min(step, seconds - passed)
            self.now = self.now + dt
            passed = passed + dt
            local due = {}
            for i = #self.timers, 1, -1 do
                if self.timers[i].at <= self.now + 1e-9 then
                    due[#due + 1] = self.timers[i].fn
                    table.remove(self.timers, i)
                end
            end
            for i = #due, 1, -1 do
                due[i]()
            end
            for _, ticker in ipairs(self.tickers) do
                if not ticker.cancelled and ticker.next <= self.now + 1e-9 then
                    ticker.next = ticker.next + ticker.interval
                    ticker.fn(ticker)
                end
            end
            for _, region in ipairs(self.regions) do
                local update = region.scripts.OnUpdate
                if update and region:IsShown() then update(region, dt) end
            end
        end
        return self
    end
    ---Loads ElvUI_Options: LibElvUIPlugin runs the plugin's callback, once.
    function client:LoadOptions()
        if self.optionsCallback and not self.optionsLoaded then
            self.optionsLoaded = true
            self.optionsCallback()
        end
        return E.Options and E.Options.args[name]
    end
    ---The plugin's settings in the current profile.
    function client:db()
        return E.db[name]
    end
    ---The plugin's parts on a unit's frame.
    function client:Holder(unit)
        return self.ns.holders[self.frames[unit]]
    end

    return client
end
