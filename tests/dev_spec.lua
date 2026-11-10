-- Screenshots for development (Dev.lua): only in a copy straight from the repository, never in a
-- release (the packager comments it out), off until switched on. The first time each kind of moment
-- from tasks\01-todo\01-ingame.md happens, a grey chat line says which, then one screenshot.

---A development copy with the screenshots switched on.
local function shooting()
    local client = NewClient({ dev = true })
    local dev = client:LoadOptions().args.units.args.dev.args
    assert.is_false(dev.on.get(), "off until switched on")
    dev.on.set(nil, true)
    return client, dev
end

---Whether a chat line contains text.
local function printed(client, text)
    for _, line in ipairs(client.printed) do
        if line:find(text, 1, true) then return true end
    end
    return false
end

describe("development screenshots", function()
    it("take one the first time a frame shows combat text, after saying which", function()
        local client = shooting()
        client:Combat("player", "WOUND", "", 10, 1)
        assert.is_true(printed(client, "|cff888888[" .. ADDON_NAME .. " dev] combat text: player, side portrait|r"))
        assert.are.equal(0, client.screenshots, "not before it is drawn")
        client:Advance(0.5)
        assert.are.equal(1, client.screenshots)
    end)

    it("take each kind once, kept, until forgotten", function()
        local client, dev = shooting()
        client:Combat("player", "WOUND", "", 10, 1):Advance(3)
        client:Combat("player", "WOUND", "", 10, 1):Advance(3)
        assert.are.equal(1, client.screenshots)
        assert.is_true(client.E.global[ADDON_NAME].dev.shots["combat text: player, side portrait"])
        dev.forget.func()
        client:Combat("player", "WOUND", "", 10, 1):Advance(3)
        assert.are.equal(2, client.screenshots)
    end)

    it("take at most one every two seconds; a kind skipped comes again later", function()
        local client = shooting()
        client:Combat("player", "WOUND", "", 10, 1):Combat("target", "WOUND", "", 10, 1):Advance(0.5)
        assert.are.equal(1, client.screenshots)
        local shots = client.E.global[ADDON_NAME].dev.shots
        assert.is_nil(shots["combat text: target, side portrait"], "too soon, not marked")
        client:Advance(3):Combat("target", "WOUND", "", 10, 1):Advance(0.5)
        assert.are.equal(2, client.screenshots)
    end)

    it("know the moments from the in-game checks", function()
        local client = shooting()
        local shots = client.E.global[ADDON_NAME].dev.shots
        client:Style("target", "overlay"):Combat("target", "WOUND", "", 10, 1):Advance(3)
        client:Style("focus", "none"):Combat("focus", "WOUND", "", 10, 1):Advance(3)
        client:Combat("player", "WOUND", "", SECRET, 1):Advance(3)
        client.loss.target = { { displayType = 2, locType = "STUN", iconTexture = 1, startTime = 0, duration = 5 } }
        client:Fire("LOSS_OF_CONTROL_ADDED", "target", 1):Advance(3)
        client.ns.SetTesting(true)
        client:Advance(3)
        for _, kind in ipairs({
            "combat text: target, overlay",
            "combat text: focus, no portrait",
            "combat text: hidden amount",
            "loss of control: target",
            "test mode",
        }) do
            assert.is_true(shots[kind], kind)
        end
    end)

    it("take none while switched off", function()
        local client = NewClient({ dev = true })
        client:Combat("player", "WOUND", "", 10, 1):Advance(3)
        assert.are.equal(0, client.screenshots)
        assert.is_false(printed(client, "dev]"))
    end)

    it("are not there in a release", function()
        local client = NewClient()
        client:Combat("player", "WOUND", "", 10, 1):Advance(3)
        assert.are.equal(0, client.screenshots)
        assert.is_nil(client.ns.DevOptions)
        assert.is_nil(client:LoadOptions().args.units.args.dev)
    end)
end)
