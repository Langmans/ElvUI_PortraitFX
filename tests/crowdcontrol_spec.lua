-- The icon over the portrait (CrowdControl.lua). Blizzard's custom aura container picks the auras
-- and draws them, so they keep working in combat while aura details are hidden from addons: per
-- frame one container with three aura slots, crowd control on top of the big defensives (Divine
-- Shield, Ice Block) on top of the external ones (Blessing of Protection). Above those the game's
-- loss of control for the frame's unit, which also knows interrupts, silences and roots.

---The aura container on a unit's frame.
local function Container(client, unit)
    return client:Holder(unit).container
end

---A loss of control entry as the client gives it.
local function Loss(fields)
    local entry = {
        displayType = 2,
        locType = "STUN",
        iconTexture = 132298,
        startTime = 990,
        duration = 20,
    }
    for k, v in pairs(fields or {}) do
        entry[k] = v
    end
    return entry
end

describe("the icon's aura slots", function()
    it("are crowd control, big and external defensives, for the frame's unit", function()
        local client = NewClient()
        local container = Container(client, "target")
        assert.are.equal("HARMFUL|CROWD_CONTROL", container.slots.cc.filter)
        assert.are.equal("HELPFUL|BIG_DEFENSIVE", container.slots.big.filter)
        assert.are.equal("HELPFUL|EXTERNAL_DEFENSIVE", container.slots.external.filter)
        assert.are.equal("target", container:GetUnit())
        assert.is_true(container:IsEnabled())
        assert.is_false(container.preview, "no Edit Mode placeholder auras")
    end)

    it("are each the game's button, filling the icon, with a texture and a countdown", function()
        local client = NewClient()
        local button = Container(client, "target").slots.cc.button
        assert.are.same({ ALL = { client:Holder("target").cc } }, button.points)
        assert.are.equal("Texture", button.icon.kind)
        assert.are.same(client.E.TexCoords, button.icon.texCoord)
        assert.is_true(button.durationCooldown.reverse)
        assert.is_false(button.durationCooldown.hideNumbers)
        assert.is_false(button.mouse, "no tooltip in the way of clicks on the frame")
    end)

    it("stack crowd control over the big defensives over the external ones", function()
        local client = NewClient()
        local slots = Container(client, "player").slots
        assert.is_true(slots.cc.button:GetFrameLevel() > slots.big.button:GetFrameLevel())
        assert.is_true(slots.big.button:GetFrameLevel() > slots.external.button:GetFrameLevel())
    end)

    it("leave the defensives out when switched off", function()
        local client = NewClient()
        client:db().cc.defensives = false
        client.ns.ApplyAll()
        local slots = Container(client, "focus").slots
        assert.is_false(slots.big.enabled)
        assert.is_false(slots.external.enabled)
        assert.is_true(slots.cc.enabled)
    end)

    it("sit on the spot: the portrait's box, or the health bar's portrait side", function()
        local client = NewClient()
        local cc = client:Holder("player").cc
        assert.are.same({ client.frames.player.Portrait.backdrop, "CENTER", 0, 0 }, cc.points.CENTER)
        assert.are.equal(45, cc:GetWidth())
        client:Style("player", "overlay")
        assert.are.same({ client.frames.player.Health, "LEFT", 0, 0 }, cc.points.LEFT)
        assert.are.equal(40, cc:GetHeight())
    end)

    it("are switched per unit and the countdown numbers for all", function()
        local client = NewClient()
        client:db().units.target.cc = false
        client:db().cc.numbers = false
        client.ns.ApplyAll()
        assert.is_false(Container(client, "target"):IsEnabled())
        assert.is_false(client:Holder("target").cc:IsShown())
        assert.is_true(Container(client, "player").slots.cc.button.durationCooldown.hideNumbers)
        assert.is_true(client:Holder("player").loss.cooldown.hideNumbers)
    end)

    it("follow the frame's unit, and refresh when the target, focus, party or pet change", function()
        local client = NewClient()
        client.frames.party2.__unit = "party3"
        client:Fire("GROUP_ROSTER_UPDATE")
        assert.are.equal("party3", Container(client, "party2"):GetUnit())
        local before = Container(client, "target").updates
        client:Fire("PLAYER_TARGET_CHANGED")
        assert.are.equal(before + 1, Container(client, "target").updates)
        before = Container(client, "focus").updates
        client:Fire("PLAYER_FOCUS_CHANGED")
        assert.are.equal(before + 1, Container(client, "focus").updates)
        before = Container(client, "pet").updates
        client:Fire("UNIT_PET", "player")
        assert.are.equal(before + 1, Container(client, "pet").updates)
        client:Fire("UNIT_PET", "party1")
        assert.are.equal(before + 1, Container(client, "pet").updates, "another's pet")
    end)

    it("are left out on a client without the aura container, the loss of control still there", function()
        local client = NewClient({ noAuraContainer = true })
        assert.is_nil(Container(client, "target"))
        client.loss.player = { Loss() }
        client:Fire("LOSS_OF_CONTROL_ADDED", "player", 1)
        assert.is_true(client:Holder("player").loss:IsShown())
    end)
end)

describe("the loss of control", function()
    it("shows the game's icon and countdown for the frame's unit, over the aura slots", function()
        local client = NewClient()
        client.loss.target = { Loss() }
        client:Fire("LOSS_OF_CONTROL_ADDED", "target", 1)
        local loss = client:Holder("target").loss
        assert.is_true(loss:IsShown())
        assert.are.equal(132298, loss.icon.texture)
        assert.are.same({ 990, 20 }, loss.cooldown.cooldown)
        assert.is_true(loss:GetFrameLevel() > Container(client, "target").slots.cc.button:GetFrameLevel())
        assert.is_false(client:Holder("player").loss:IsShown(), "only on the frame of that unit")
    end)

    it("is on every frame: player, target, focus, pet and party", function()
        local client = NewClient()
        for _, unit in ipairs({ "player", "target", "focus", "pet", "party1", "party2" }) do
            client.loss[unit] = { Loss() }
            client:Fire("LOSS_OF_CONTROL_UPDATE", unit)
            assert.is_true(client:Holder(unit).loss:IsShown(), unit)
        end
    end)

    it("is read again when the frame shows another unit", function()
        local client = NewClient()
        client.loss.target = { Loss() }
        client:Fire("PLAYER_TARGET_CHANGED")
        assert.is_true(client:Holder("target").loss:IsShown())
        client.loss.target = nil
        client:Fire("PLAYER_TARGET_CHANGED")
        assert.is_false(client:Holder("target").loss:IsShown())
    end)

    it("uses the game's duration object when the times are hidden, and none without one", function()
        local client = NewClient()
        local duration = {}
        client.loss.player = { Loss({ startTime = SECRET, duration = SECRET, durationObject = duration }) }
        client:Fire("LOSS_OF_CONTROL_UPDATE", "player")
        assert.are.equal(duration, client:Holder("player").loss.cooldown.durationObject)
        client.loss.player[1].durationObject = nil
        client:Fire("LOSS_OF_CONTROL_UPDATE", "player")
        assert.is_false(client:Holder("player").loss:IsShown(), "no countdown to show")
    end)

    it("skips what is not shown, and interrupts when switched off", function()
        local client = NewClient()
        local loss = client:Holder("player").loss
        client.loss.player = { Loss({ displayType = 0 }) }
        client:Fire("LOSS_OF_CONTROL_UPDATE", "player")
        assert.is_false(loss:IsShown())
        client.loss.player = { Loss({ locType = "SCHOOL_INTERRUPT", iconTexture = 1 }), Loss({ iconTexture = 2 }) }
        client:Fire("LOSS_OF_CONTROL_UPDATE", "player")
        assert.are.equal(1, loss.icon.texture, "the first one the game lists")
        client:db().cc.interrupts = false
        client:Fire("LOSS_OF_CONTROL_UPDATE", "player")
        assert.are.equal(2, loss.icon.texture)
        client.loss.player[1] = Loss({ locType = SECRET, iconTexture = 1 })
        client:Fire("LOSS_OF_CONTROL_UPDATE", "player")
        assert.are.equal(2, loss.icon.texture, "a hidden kind might be an interrupt")
    end)

    it("shows a hidden display type, which may be anything, and the active entry for a hidden count", function()
        local client = NewClient()
        client.loss.player = { Loss({ displayType = SECRET }), Loss({ iconTexture = 2 }) }
        client.lossCount.player = SECRET
        client:Fire("LOSS_OF_CONTROL_UPDATE", "player")
        assert.is_true(client:Holder("player").loss:IsShown())
        assert.are.equal(132298, client:Holder("player").loss.icon.texture)
    end)

    it("hides when it ends, or the frame's icon is switched off", function()
        local client = NewClient()
        local loss = client:Holder("player").loss
        client.loss.player = { Loss() }
        client:Fire("LOSS_OF_CONTROL_UPDATE", "player")
        client.loss.player = nil
        loss.cooldown:GetScript("OnCooldownDone")(loss.cooldown)
        assert.is_false(loss:IsShown())
        assert.is_nil(loss.cooldown.cooldown)
        client.loss.player = { Loss() }
        client:db().units.player.cc = false
        client:Fire("LOSS_OF_CONTROL_UPDATE", "player")
        assert.is_false(loss:IsShown())
    end)
end)
