-- Test mode (Test.lua): sample combat text on every frame in turn and a sample icon with its
-- countdown on each, to place and size things without a fight. It ends when combat starts.

describe("test mode", function()
    it("plays sample events on every frame and shows a sample icon", function()
        local client = NewClient()
        client.ns.SetTesting(true)
        assert.is_true(client.ns.testing)
        local holder = client:Holder("party1")
        assert.is_true(holder.preview:IsShown())
        assert.are.same({ client.now, client.ns.PREVIEW_DURATION }, holder.preview.cooldown.cooldown)
        client:Advance(client.ns.TEST_INTERVAL)
        local first = holder.text:GetText()
        assert.is_true(holder.text:IsShown())
        client:Advance(client.ns.TEST_INTERVAL)
        assert.are_not.equal(first, holder.text:GetText(), "the next sample")
    end)

    it("plays every sample in turn, over and over", function()
        local client = NewClient()
        client.ns.SetTesting(true)
        local seen = {}
        for _ = 1, #client.ns.samples * 2 do
            client:Advance(client.ns.TEST_INTERVAL)
            seen[client:Holder("player").text:GetText()] = true
        end
        assert.is_true(seen["2,468"])
        assert.is_true(seen[client.ns.marks.DODGE], "a dodge, as its icon")
    end)

    it("stops on request and when combat starts", function()
        local client = NewClient()
        client.ns.SetTesting(true)
        client.ns.SetTesting(false)
        assert.is_false(client:Holder("player").preview:IsShown())
        client:Advance(client.ns.TEST_INTERVAL * 2)
        assert.is_false(client:Holder("player").text:IsShown())
        client.ns.SetTesting(true)
        client:Fire("PLAYER_REGEN_DISABLED")
        assert.is_false(client.ns.testing)
        assert.is_false(client:Holder("target").preview:IsShown())
    end)

    it("shows the sample icon only where the icon is switched on", function()
        local client = NewClient()
        client:db().units.pet.cc = false
        client.ns.SetTesting(true)
        assert.is_false(client:Holder("pet").preview:IsShown())
        assert.is_true(client:Holder("player").preview:IsShown())
    end)
end)
