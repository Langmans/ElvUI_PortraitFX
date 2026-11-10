-- The crowd control icon over the portrait (CrowdControl.lua). Blizzard's custom aura container
-- picks the aura and draws it, so it keeps working in combat while aura details are hidden from
-- addons: one aura slot per frame, filtered HARMFUL|CROWD_CONTROL. On the player the game's loss of
-- control data goes on top, which also knows interrupts, silences and roots.

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

describe("the crowd control icon", function()
    it("is one crowd control aura slot over the portrait, for the frame's unit", function()
        local client = NewClient()
        local container = Container(client, "target")
        local slot = container.slots.cc
        assert.are.equal("HARMFUL|CROWD_CONTROL", slot.filter)
        assert.are.equal("target", container:GetUnit())
        assert.is_true(container:IsEnabled())
        assert.is_false(container.preview, "no Edit Mode placeholder auras")
        local button = slot.button
        assert.are.same({ ALL = { client:Holder("target").cc } }, button.points)
        assert.are.equal("Texture", button.icon.kind)
        assert.are.same(client.E.TexCoords, button.icon.texCoord)
        assert.is_true(button.durationCooldown.reverse)
        assert.is_false(button.durationCooldown.hideNumbers)
        assert.is_false(button.mouse, "no tooltip in the way of clicks on the frame")
    end)

    it("sits on the spot: the portrait's box, or the health bar's portrait side", function()
        local client = NewClient()
        local cc = client:Holder("player").cc
        assert.are.same({ client.frames.player.Portrait.backdrop, "CENTER", 0, 0 }, cc.points.CENTER)
        assert.are.equal(45, cc:GetWidth())
        client:Style("player", "overlay")
        assert.are.same({ client.frames.player.Health, "LEFT", 0, 0 }, cc.points.LEFT)
        assert.are.equal(40, cc:GetHeight())
    end)

    it("is above ElvUI's 3D portrait and the frame's texts", function()
        local client = NewClient()
        local holder = client:Holder("player")
        assert.are.equal(client.frames.player.RaisedElementParent, holder.parent)
        assert.is_true(holder.cc:GetFrameLevel() > client.frames.player.RaisedElementParent:GetFrameLevel())
    end)

    it("hangs on the frame itself where it has no raised parent", function()
        local client = NewClient({ noRaised = true })
        assert.are.equal(client.frames.player, client:Holder("player").parent)
    end)

    it("is switched per unit and the countdown numbers for all", function()
        local client = NewClient()
        client:db().units.target.cc = false
        client:db().cc.numbers = false
        client.ns.ApplyAll()
        assert.is_false(Container(client, "target"):IsEnabled())
        assert.is_false(client:Holder("target").cc:IsShown())
        assert.is_true(Container(client, "player").slots.cc.button.durationCooldown.hideNumbers)
        assert.is_true(client:Holder("player").loss.cooldown.hideNumbers)
    end)

    it("follows the frame's unit, and refreshes when the target, focus, party or pet change", function()
        local client = NewClient()
        client.frames.party2.unit = "party3"
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
    end)

    it("is left out on a client without the aura container, with the player's loss of control still there", function()
        local client = NewClient({ noAuraContainer = true })
        assert.is_nil(Container(client, "target"))
        client.loss[1] = Loss()
        client:Fire("LOSS_OF_CONTROL_ADDED", "player", 1)
        assert.is_true(client:Holder("player").loss:IsShown())
    end)
end)

describe("the player's loss of control", function()
    it("shows the game's icon and countdown over the aura slot", function()
        local client = NewClient()
        client.loss[1] = Loss()
        client:Fire("LOSS_OF_CONTROL_ADDED", "player", 1)
        local loss = client:Holder("player").loss
        assert.is_true(loss:IsShown())
        assert.are.equal(132298, loss.icon.texture)
        assert.are.same({ 990, 20 }, loss.cooldown.cooldown)
        assert.is_true(loss:GetFrameLevel() > client:Holder("player").cc:GetFrameLevel())
    end)

    it("uses the game's duration object when the times are hidden", function()
        local client = NewClient()
        local duration = {}
        client.loss[1] = Loss({ startTime = SECRET, duration = SECRET, durationObject = duration })
        client:Fire("LOSS_OF_CONTROL_UPDATE", "player")
        assert.are.equal(duration, client:Holder("player").loss.cooldown.durationObject)
        client.loss[1].durationObject = nil
        client:Fire("LOSS_OF_CONTROL_UPDATE", "player")
        assert.is_false(client:Holder("player").loss:IsShown(), "no countdown to show")
    end)

    it("skips what is not shown, and interrupts when switched off", function()
        local client = NewClient()
        local loss = client:Holder("player").loss
        client.loss[1] = Loss({ displayType = 0 })
        client:Fire("LOSS_OF_CONTROL_UPDATE", "player")
        assert.is_false(loss:IsShown())
        client.loss[1] = Loss({ locType = "SCHOOL_INTERRUPT", iconTexture = 1 })
        client.loss[2] = Loss({ iconTexture = 2 })
        client:Fire("LOSS_OF_CONTROL_UPDATE", "player")
        assert.are.equal(1, loss.icon.texture, "the first one the game lists")
        client:db().cc.interrupts = false
        client:Fire("LOSS_OF_CONTROL_UPDATE", "player")
        assert.are.equal(2, loss.icon.texture)
        client.loss[1] = Loss({ locType = SECRET, iconTexture = 1 })
        client:Fire("LOSS_OF_CONTROL_UPDATE", "player")
        assert.are.equal(2, loss.icon.texture, "a hidden kind might be an interrupt")
    end)

    it("shows a hidden display type, which may be anything", function()
        local client = NewClient()
        client.loss[1] = Loss({ displayType = SECRET })
        client:Fire("LOSS_OF_CONTROL_UPDATE", "player")
        assert.is_true(client:Holder("player").loss:IsShown())
    end)

    it("hides when the loss of control ends, or the player's icon is switched off", function()
        local client = NewClient()
        local loss = client:Holder("player").loss
        client.loss[1] = Loss()
        client:Fire("LOSS_OF_CONTROL_UPDATE", "player")
        client.loss[1] = nil
        loss.cooldown:GetScript("OnCooldownDone")(loss.cooldown)
        assert.is_false(loss:IsShown())
        assert.is_nil(loss.cooldown.cooldown)
        client.loss[1] = Loss()
        client:db().units.player.cc = false
        client:Fire("LOSS_OF_CONTROL_UPDATE", "player")
        assert.is_false(loss:IsShown())
    end)

    it("listens only for the player", function()
        local client = NewClient()
        client.loss[1] = Loss()
        client:Fire("LOSS_OF_CONTROL_UPDATE", "target")
        assert.is_false(client:Holder("player").loss:IsShown())
        assert.is_nil(client:Holder("target").loss)
    end)
end)
