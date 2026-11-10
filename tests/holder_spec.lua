-- The plugin's parts on each frame (Holder.lua): made once per frame of the player, target, focus,
-- pet and party, at login for the frames oUF built so far and through UF.Configure_Portrait for a
-- frame built later. Configure_Portrait runs on every settings change of a frame, so the parts
-- move along when the portrait does.

describe("the parts on a frame", function()
    it("are made for the plugin's units only", function()
        local client = NewClient()
        for _, unit in ipairs({ "player", "target", "focus", "pet", "party1", "party2" }) do
            assert.is_table(client:Holder(unit), unit)
        end
        assert.is_nil(client:Holder("targettarget"))
        assert.is_nil(client:Holder("partypet1"))
    end)

    it("are made once, and follow the portrait when ElvUI configures it again", function()
        local client = NewClient()
        local holder = client:Holder("player")
        client:Style("player", "overlay")
        assert.are.equal(holder, client:Holder("player"))
        assert.are.same({ client.frames.player.Health, "CENTER", 0, 0 }, holder.text.points.CENTER)
        client:Style("player", "side")
        assert.are.same({ client.frames.player.Portrait.backdrop, "CENTER", 0, 0 }, holder.text.points.CENTER)
    end)

    it("listen to their own unit's combat and loss of control, as Blizzard's frames do", function()
        local client = NewClient()
        local holder = client:Holder("party2")
        assert.are.same(
            { UNIT_COMBAT = "party2", LOSS_OF_CONTROL_UPDATE = "party2", LOSS_OF_CONTROL_ADDED = "party2" },
            holder.unitEvents
        )
        client.frames.party2.__unit = "party4"
        client:Fire("GROUP_ROSTER_UPDATE")
        assert.are.equal("party4", holder.unitEvents.UNIT_COMBAT, "the frame's new unit")
        assert.is_nil(client.events.UNIT_COMBAT, "not for every unit at once")
    end)

    it("wait for a frame without a unit yet, and take it on once it has one", function()
        local client = NewClient()
        local frame = client:BuildFrame("party3", "party", "side", true)
        local holder = client:Holder("party3")
        assert.is_nil(holder.unitEvents, "no unit to listen to")
        assert.are.equal("none", holder.container:GetUnit(), "the client's token for no unit")
        assert.is_false(holder.loss:IsShown())
        frame.__unit = "party3"
        client:Fire("GROUP_ROSTER_UPDATE")
        assert.are.equal("party3", holder.unitEvents.UNIT_COMBAT)
        assert.are.equal("party3", holder.container:GetUnit())
    end)

    it("stop listening when the frame loses its unit", function()
        local client = NewClient()
        local holder = client:Holder("party2")
        client.frames.party2.__unit = nil
        client:Fire("GROUP_ROSTER_UPDATE")
        assert.is_nil(holder.listening)
        assert.are.same({}, holder.unitEvents)
    end)

    it("take every frame's unit again when the world loads", function()
        local client = NewClient()
        client.frames.target.__unit = "target"
        client:Holder("target").listening = nil
        client:Fire("PLAYER_ENTERING_WORLD")
        assert.are.equal("target", client:Holder("target").listening)
    end)

    it("put the text at the point and offset set, on the spot", function()
        local client = NewClient()
        local text = client:db().text
        text.point, text.x, text.y = "TOP", 6, -4
        client.ns.ApplyAll()
        local holder = client:Holder("player")
        assert.are.same({ TOP = { client.frames.player.Portrait.backdrop, "TOP", 6, -4 } }, holder.text.points)
        client:Style("player", "overlay")
        assert.are.same({ TOP = { client.frames.player.Health, "TOP", 6, -4 } }, holder.text.points)
    end)

    it("are made for a frame ElvUI builds later", function()
        local client = NewClient()
        client:BuildFrame("party3", "party")
        assert.is_table(client:Holder("party3"), "ElvUI configures its portrait")
        assert.are.equal(client.ns.holderList[#client.ns.holderList], client:Holder("party3"))
    end)
end)
