-- Combat text on the portrait (CombatText.lua): what UNIT_COMBAT says happened to the frame's unit,
-- briefly, fading in and out as Blizzard's own portrait text does. WoW: Forever may hide the amount
-- (a secret value): it can only be handed to the game's number formatters, never compared, so the
-- flags decide what a hidden amount means.

---The text on a unit's frame.
local function Text(client, unit)
    return client:Holder(unit).text
end

describe("combat text", function()
    it("shows damage on the portrait, in ElvUI's font, sized to the portrait", function()
        local client = NewClient():Combat("player", "WOUND", "", 1234, 1)
        local text = Text(client, "player")
        assert.is_true(text:IsShown())
        assert.are.equal("1,234", text:GetText())
        assert.are.same({ 1, 1, 1 }, text.color)
        assert.are.same({ "Fonts\\PT Sans Narrow.ttf", 45 * 0.5, "OUTLINE" }, text.font)
        assert.are.equal(0, text:GetAlpha(), "it fades in")
    end)

    it("makes a critical or crushing hit bigger and a glancing one smaller", function()
        local client = NewClient():Combat("player", "WOUND", "CRITICAL", 50, 1)
        assert.are.equal(45 * 0.5 * 1.5, Text(client, "player").font[2])
        client:Combat("player", "WOUND", "CRUSHING", 50, 1)
        assert.are.equal(45 * 0.5 * 1.5, Text(client, "player").font[2])
        client:Combat("player", "WOUND", "GLANCING", 50, 1)
        assert.are.equal(45 * 0.5 * 0.75, Text(client, "player").font[2])
    end)

    it("colours spell damage by its school, or in one spell colour", function()
        local client = NewClient():Combat("target", "WOUND", "", 80, 4)
        assert.are.same(client.ns.schoolColors[4], Text(client, "target").color)
        client:db().text.schools = false
        client:Combat("target", "WOUND", "", 80, 4)
        assert.are.same({ 1, 1, 0 }, Text(client, "target").color)
    end)

    it("shows heals in green, a critical one bigger", function()
        local client = NewClient():Combat("player", "HEAL", "CRITICAL", 300, 2)
        local text = Text(client, "player")
        assert.are.equal("300", text:GetText())
        assert.are.same({ 0, 1, 0 }, text.color)
        assert.are.equal(45 * 0.5 * 1.5, text.font[2])
    end)

    it("shows power gains only when asked", function()
        local client = NewClient():Combat("player", "ENERGIZE", "", 25, 0)
        assert.is_false(Text(client, "player"):IsShown())
        client:db().text.energize = true
        client:Combat("player", "ENERGIZE", "", 25, 0)
        assert.are.equal("25", Text(client, "player"):GetText())
        assert.are.same({ 0.41, 0.8, 0.94 }, Text(client, "player").color)
    end)

    it("names a miss, a dodge, an absorb, a block and an immunity in the game's words", function()
        local client = NewClient()
        local text = Text(client, "player")
        local full = 45 * 0.5
        for _, case in ipairs({
            { "DODGE", "", 0, "Dodge", full },
            { "PARRY", "", 0, "Parry", full },
            { "WOUND", "", 0, "Miss", full },
            { "WOUND", "ABSORB", 0, "Absorb", full * 0.75 },
            { "WOUND", "RESIST", 0, "Resist", full * 0.75 },
            { "WOUND", "BLOCK", 0, "Block", full * 0.75 },
            { "BLOCK", "", 0, "Block", full * 0.75 },
            { "IMMUNE", "", 0, "Immune", full * 0.5 },
        }) do
            client:Combat("player", case[1], case[2], case[3], 1)
            assert.are.equal(case[4], text:GetText(), case[1] .. " " .. case[2])
            assert.are.equal(case[5], text.font[2], case[1] .. " " .. case[2])
        end
    end)

    it("marks damage partly blocked", function()
        local client = NewClient():Combat("player", "WOUND", "BLOCK_REDUCED", 120, 1)
        assert.are.equal("120 (Blocked)", Text(client, "player"):GetText())
    end)

    it("shortens big numbers in ElvUI's number style when asked", function()
        local client = NewClient()
        client:db().text.short = true
        client:Combat("player", "WOUND", "", 1234, 1)
        assert.are.equal("1.2K", Text(client, "player"):GetText())
        assert.are.same({ 1234, client.E.Abbreviate.short }, client:called("AbbreviateNumbers")[1])
    end)

    it("shows a hidden amount through the game's formatter, and lets the flags name an avoided one", function()
        local client = NewClient():Combat("player", "WOUND", "", SECRET, 1)
        assert.are.equal("<secret>", Text(client, "player"):GetText())
        client:db().text.short = true
        client:Combat("player", "HEAL", "", SECRET, 2)
        assert.are.equal("<secret>", Text(client, "player"):GetText())
        client:Combat("player", "WOUND", "ABSORB", SECRET, 1)
        assert.are.equal("Absorb", Text(client, "player"):GetText())
    end)

    it("works on a client that hides nothing and has no check for it", function()
        local client = NewClient({ noSecretCheck = true }):Combat("player", "WOUND", "", 10, 1)
        assert.are.equal("10", Text(client, "player"):GetText())
    end)

    it("shows nothing for an event or flags the client hides", function()
        local client = NewClient():Combat("player", SECRET, "", 10, 1)
        assert.is_false(Text(client, "player"):IsShown())
        client:Combat("player", "WOUND", SECRET, 10, 1)
        assert.is_false(Text(client, "player"):IsShown())
        client:Combat("player", "WOUND", "", 10, SECRET)
        assert.are.equal("10", Text(client, "player"):GetText(), "a hidden school is the spell colour")
        assert.are.same({ 1, 1, 0 }, Text(client, "player").color)
    end)

    it("leaves out the kinds switched off", function()
        local client = NewClient()
        local db = client:db().text
        db.damage, db.heals, db.misses = false, false, false
        client:Combat("player", "WOUND", "", 10, 1)
        client:Combat("player", "HEAL", "", 10, 2)
        client:Combat("player", "DODGE", "", 0, 1)
        client:Combat("player", "WOUND", "ABSORB", 0, 1)
        assert.is_false(Text(client, "player"):IsShown())
        db.misses = true
        client:Combat("player", "SOMETHING_NEW", "", 0, 1)
        assert.is_false(Text(client, "player"):IsShown(), "an event the plugin has no word for")
    end)

    it("fades in, holds and fades out, as Blizzard's portrait text does", function()
        local client = NewClient():Combat("player", "WOUND", "", 10, 1)
        local text = Text(client, "player")
        client:Advance(0.1)
        assert.is_near(0.5, text:GetAlpha(), 0.01)
        client:Advance(0.5)
        assert.are.equal(1, text:GetAlpha())
        client:Advance(0.45)
        assert.is_near(0.5, text:GetAlpha(), 0.01)
        client:Advance(0.2)
        assert.is_false(text:IsShown())
        client:db().text.hold = 2
        client:Combat("player", "WOUND", "", 10, 1):Advance(2)
        assert.are.equal(1, text:GetAlpha(), "held longer")
    end)

    it("goes only to the frame of the unit it happened to, and only where switched on", function()
        local client = NewClient():Combat("party1", "WOUND", "", 10, 1)
        assert.is_true(Text(client, "party1"):IsShown())
        assert.is_false(Text(client, "party2"):IsShown())
        assert.is_nil(client:Holder("targettarget"), "not a frame of the plugin's")
        assert.is_nil(client:Holder("partypet1"), "the party's pets are not")
        client:db().units.party.text = false
        client:Combat("party2", "WOUND", "", 10, 1)
        assert.is_false(Text(client, "party2"):IsShown())
    end)

    it("follows a party frame to its new unit", function()
        local client = NewClient()
        client.frames.party2.unit = "party3"
        client:Combat("party3", "WOUND", "", 10, 1)
        assert.is_true(Text(client, "party2"):IsShown())
    end)

    it("clears the target's and focus's text when they change", function()
        local client = NewClient():Combat("target", "WOUND", "", 10, 1):Combat("focus", "WOUND", "", 10, 1)
        client:Fire("PLAYER_TARGET_CHANGED")
        assert.is_false(Text(client, "target"):IsShown())
        assert.is_true(Text(client, "focus"):IsShown())
        client:Fire("PLAYER_FOCUS_CHANGED")
        assert.is_false(Text(client, "focus"):IsShown())
    end)
end)
