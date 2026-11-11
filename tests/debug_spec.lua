-- The bridge to the debug addons (Debug.lua): OAP Debug and _DebugLog get lines on what the plugin
-- receives and does, to see in the game why something does not show. A hidden value is never sent:
-- the line says "hidden" instead.

---A client with both debug addons.
local function withDebug(level, opts)
    opts = opts or {}
    opts.oapDebug, opts.debugLog, opts.debugLevel = true, true, level
    return NewClient(opts)
end

describe("OAP Debug", function()
    it("gets the plugin registered at login, with its folder for Lua errors", function()
        local client = withDebug()
        local registered = client:debug("Register")
        assert.are.equal(1, #registered)
        assert.are.equal(ADDON_NAME, registered[1][1])
        assert.are.equal(ADDON_NAME, registered[1][2].folder)
    end)

    it("hears each frame the plugin takes on, also those ElvUI builds after the plugin started", function()
        local client = withDebug()
        local before = #client:debug("Log")
        client:BuildFrame("party3", "party")
        local lines = client:debug("Log")
        assert.are.equal(before + 1, #lines)
        assert.are.same({ "frame: {1} taken on", "info", "party" }, { unpack(lines[#lines], 2) })
    end)

    it("hears an aura container that could not be made, with the game's error", function()
        local client = withDebug("errors", { brokenContainer = true })
        local found
        for _, line in ipairs(client:debug("Log")) do
            if line[2]:find("no aura container", 1, true) then found = line end
        end
        assert.is_table(found)
        assert.are.equal("error", found[3])
        assert.is_truthy(tostring(found[5]):find("could not be added", 1, true))
    end)

    it("hears every combat event on a frame at the detailed level, a hidden amount as hidden", function()
        local client = withDebug("detailed")
        client:Combat("player", "WOUND", "", SECRET, 1)
        local found
        for _, line in ipairs(client:debug("Log")) do
            if line[2]:find("combat:", 1, true) then found = line end
        end
        assert.are.same({ "debug", "WOUND", "", "player", "hidden" }, { unpack(found, 3) })
        assert.are.same({ ADDON_NAME, "combat" }, client:debug("Count")[1])
    end)

    it("hears an event that shows nothing, and why", function()
        local client = withDebug("detailed")
        client:db().text.damage = false
        client:Combat("player", "WOUND", "", 10, 1)
        assert.is_true(client:logged("nothing to show"))
        client:db().units.player.text = false
        client:Combat("player", "WOUND", "", 10, 1)
        assert.is_true(client:logged("text is off"))
    end)

    it("hears the loss of control shown, its kind hidden or not", function()
        local client = withDebug()
        client.loss.target = { { displayType = 2, locType = SECRET, iconTexture = 1, startTime = 0, duration = 5 } }
        client:Fire("LOSS_OF_CONTROL_UPDATE", "target")
        assert.is_true(client:logged("loss:"))
    end)

    it("hears the aura slots' unit when they refresh, at the detailed level", function()
        local client = withDebug("detailed")
        client:Fire("PLAYER_TARGET_CHANGED")
        assert.is_true(client:logged("cc: {1} shows {2}"))
    end)

    it("sends nothing above errors at the errors-only level, and counts only from metrics", function()
        local client = withDebug("errors")
        client:Combat("player", "WOUND", "", 10, 1)
        assert.are.same({}, client:debug("Log"))
        assert.are.same({}, client:debug("DebugLog"))
        client = withDebug("normal")
        client:Combat("player", "WOUND", "", 10, 1)
        assert.are.same({}, client:debug("Count"))
    end)
end)

describe("_DebugLog", function()
    it("gets the same lines as text in the plugin's tab, under their category", function()
        local client = withDebug("detailed")
        client:Combat("player", "WOUND", "", SECRET, 1)
        local lines = client:debug("DebugLog")
        local last = lines[#lines]
        assert.are.same({ ADDON_NAME, "%s", "2~combat~WOUND  on player, amount hidden" }, last)
    end)

    it("colours an error", function()
        local client = NewClient({ debugLog = true, brokenContainer = true })
        local first = client:debug("DebugLog")[1]
        assert.is_truthy(first[3]:find("^ERR~cc~"))
    end)
end)

describe("without a debug addon", function()
    it("sends nothing and says so in the options", function()
        local client = NewClient()
        client:Combat("player", "WOUND", "", 10, 1)
        assert.are.same({}, client.debugCalls)
        local level = client:LoadOptions().args.units.args.debug.args.level
        assert.is_truthy(level.desc():find(client.ns.L.DEBUG_MISSING, 1, true))
        level.set(nil, "detailed")
        assert.are.equal("detailed", level.get())
    end)

    it("tells the options that one is there", function()
        local client = withDebug()
        local level = client:LoadOptions().args.units.args.debug.args.level
        assert.is_nil(level.desc():find(client.ns.L.DEBUG_MISSING, 1, true))
    end)
end)
