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
        client.frames.party2.unit = "party4"
        client:Fire("GROUP_ROSTER_UPDATE")
        assert.are.equal("party4", holder.unitEvents.UNIT_COMBAT, "the frame's new unit")
        assert.is_nil(client.events.UNIT_COMBAT, "not for every unit at once")
    end)

    it("are made for a frame ElvUI builds later", function()
        local client = NewClient()
        client:BuildFrame("party3", "party")
        assert.is_table(client:Holder("party3"), "ElvUI configures its portrait")
        assert.are.equal(client.ns.holderList[#client.ns.holderList], client:Holder("party3"))
    end)
end)
