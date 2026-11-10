-- How the plugin's parts stack (Holder.lua). The text is above everything of the icon (the aura
-- slots, the loss of control, test mode's sample), the icon above ElvUI's 3D portrait. The strata
-- and the level above ElvUI's raised element parent can be set; the strata is the frame's own
-- unless set.

describe("the layers", function()
    it("put the text above the icon, the loss of control and the sample icon", function()
        local client = NewClient()
        client.ns.SetTesting(true)
        local holder = client:Holder("player")
        local text = holder.textFrame:GetFrameLevel()
        assert.are.equal(holder.textFrame, holder.text.parent)
        assert.is_true(text > holder.preview:GetFrameLevel())
        assert.is_true(text > holder.loss:GetFrameLevel())
        assert.is_true(text > holder.container.slots.cc.button:GetFrameLevel())
    end)

    it("sit on ElvUI's raised element parent, above the 3D portrait and the frame's texts", function()
        local client = NewClient()
        local holder = client:Holder("player")
        local raised = client.frames.player.RaisedElementParent
        assert.are.equal(raised, holder.parent)
        assert.are.equal(raised:GetFrameLevel() + client:db().layer.level, holder:GetFrameLevel())
        assert.are.equal(raised:GetFrameStrata(), holder:GetFrameStrata(), "the frame's own strata")
    end)

    it("hang on the frame itself where it has no raised parent", function()
        local client = NewClient({ noRaised = true })
        assert.are.equal(client.frames.player, client:Holder("player").parent)
    end)

    it("take the strata and level set, keeping their order", function()
        local client = NewClient()
        client:db().layer.strata = "HIGH"
        client:db().layer.level = 30
        client.ns.ApplyAll()
        local holder = client:Holder("target")
        local raised = client.frames.target.RaisedElementParent
        assert.are.equal("HIGH", holder:GetFrameStrata())
        assert.are.equal("HIGH", holder.textFrame:GetFrameStrata(), "the parts take it from the holder")
        assert.are.equal(raised:GetFrameLevel() + 30, holder:GetFrameLevel())
        assert.is_true(holder.cc:GetFrameLevel() > holder:GetFrameLevel())
        assert.is_true(holder.container:GetFrameLevel() > holder.cc:GetFrameLevel())
        assert.is_true(holder.loss:GetFrameLevel() > holder.container:GetFrameLevel())
        assert.is_true(holder.textFrame:GetFrameLevel() > holder.loss:GetFrameLevel())
        client:db().layer.strata = ""
        client.ns.ApplyAll()
        assert.are.equal(raised:GetFrameStrata(), holder:GetFrameStrata(), "back to the frame's own")
    end)

    it("move the sample icon along once test mode made it", function()
        local client = NewClient()
        client.ns.SetTesting(true)
        client:db().layer.level = 40
        client.ns.ApplyAll()
        local holder = client:Holder("player")
        assert.is_true(holder.preview:GetFrameLevel() > holder.loss:GetFrameLevel())
        assert.is_true(holder.textFrame:GetFrameLevel() > holder.preview:GetFrameLevel())
    end)
end)
