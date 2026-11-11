-- The absorbing buff's icon beside an absorb (CombatText.lua, CrowdControl.lua). The addon cannot
-- read buffs in combat, so Blizzard's aura container does: one slot per frame, HELPFUL buffs limited
-- to the absorb spells (Data/Absorbs.lua, from the spell data), and the game draws the icon of the
-- one on the unit. It shows beside the text while an absorb shows, as high as the text, takes no
-- mouse, and is switched in the options.

---The absorb slot's parts on a unit's frame.
local function Absorb(client, unit)
    local holder = client:Holder(unit)
    return holder.absorb, holder.absorbContainer
end

describe("the absorbing buff's icon", function()
    it("is an aura slot for the absorb spells among the frame's unit's buffs", function()
        local client = NewClient()
        local _, container = Absorb(client, "player")
        local slot = container.slots.absorb
        assert.are.equal("HELPFUL", slot.filter)
        assert.are.equal(client.ns.absorbSpells, slot.options.candidateFilters.includeSpellIDs)
        assert.are.equal("player", container:GetUnit())
        assert.is_true(container:IsEnabled())
        assert.is_false(container.preview)
        local button = slot.button
        assert.is_false(button.mouse, "clicks go through to the frame")
        assert.are.equal("Texture", button.icon.kind)
        assert.are.same({ ALL = { client:Holder("player").absorb } }, button.points)
    end)

    it("knows the absorb spells from the spell data", function()
        local client = NewClient()
        for _, id in ipairs({ 17, 10901, 11426, 1463, 543, 6143, 6229, 7812 }) do
            assert.is_true(client.ns.absorbSpells[id], id)
        end
        assert.is_nil(client.ns.absorbSpells[642], "Divine Shield makes immune, it absorbs nothing")
    end)

    it("shows beside the text while an absorb shows, as high as the text", function()
        local client = NewClient()
        local absorb = Absorb(client, "player")
        local text = client:Holder("player").text
        assert.is_false(absorb:IsShown())
        client:Combat("player", "WOUND", "ABSORB", 80, 1)
        assert.is_true(absorb:IsShown())
        assert.are.same({ text, "RIGHT", 2, 0 }, absorb.points.LEFT)
        assert.are.equal(text.font[2], absorb:GetHeight())
        assert.are.equal(text.font[2], absorb:GetWidth())
        client:Combat("player", "WOUND", "ABSORB", SECRET, 1)
        assert.is_true(absorb:IsShown(), "a hidden amount too")
        client:Combat("player", "WOUND", "", 30, 1)
        assert.is_false(absorb:IsShown(), "not beside other text")
    end)

    it("fades with the text and goes with it", function()
        local client = NewClient():Combat("player", "WOUND", "ABSORB", 80, 1)
        local absorb, holder = Absorb(client, "player"), client:Holder("player")
        client:Advance(0.1)
        assert.are.equal(holder.text:GetAlpha(), absorb:GetAlpha())
        client:Advance(2)
        assert.is_false(absorb:IsShown())
        client:Combat("player", "WOUND", "ABSORB", 80, 1)
        client:Fire("PLAYER_TARGET_CHANGED")
        client:Combat("target", "WOUND", "ABSORB", 80, 1)
        client:Fire("PLAYER_TARGET_CHANGED")
        assert.is_false(Absorb(client, "target"):IsShown())
    end)

    it("follows the frame's unit", function()
        local client = NewClient()
        client.frames.party2.__unit = "party3"
        client:Fire("GROUP_ROSTER_UPDATE")
        assert.are.equal("party3", select(2, Absorb(client, "party2")):GetUnit())
    end)

    it("is left out when switched off, or where the frame's text is off", function()
        local client = NewClient()
        client:db().text.absorbAura = false
        client.ns.ApplyAll()
        local absorb, container = Absorb(client, "player")
        assert.is_false(container:IsEnabled())
        client:Combat("player", "WOUND", "ABSORB", 80, 1)
        assert.is_false(absorb:IsShown())
        client:db().text.absorbAura = true
        client:db().units.target.text = false
        client.ns.ApplyAll()
        assert.is_true(container:IsEnabled())
        assert.is_false(select(2, Absorb(client, "target")):IsEnabled())
    end)

    it("is left out on a client without the aura container", function()
        local client = NewClient({ noAuraContainer = true })
        assert.is_nil(select(2, Absorb(client, "player")))
        client:Combat("player", "WOUND", "ABSORB", 80, 1)
        assert.is_true(client:Holder("player").text:IsShown())
    end)
end)
