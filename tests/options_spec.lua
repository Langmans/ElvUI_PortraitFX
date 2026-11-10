-- The plugin's page in ElvUI's options (Options.lua): the frames and what each shows, the text's
-- look and kinds, the icon's settings, and the test mode.

---Runs an option's getter or setter as AceConfig does: info is the path, the option's key last.
local function info(...)
    return { ... }
end

describe("the options page", function()
    it("is added among ElvUI's plugins once its options load", function()
        local client = NewClient()
        local page = client:LoadOptions()
        assert.are.equal("tab", page.childGroups)
        assert.is_table(page.args.units)
        assert.is_table(page.args.text)
        assert.is_table(page.args.cc)
    end)

    it("is left out without ElvUI_Options", function()
        local client = NewClient({ noOptions = true })
        assert.is_nil(client:LoadOptions())
    end)

    it("switches the text and the icon per frame", function()
        local client = NewClient()
        local units = client:LoadOptions().args.units
        local cc = units.args.target.args.cc
        assert.is_true(units.args.target.get(info("units", "target", "cc")))
        units.args.target.set(info("units", "target", "cc"), false)
        assert.is_false(client:db().units.target.cc)
        assert.is_false(client:Holder("target").container:IsEnabled(), "applied at once")
        units.args.party.set(info("units", "party", "text"), false)
        assert.is_false(client:db().units.party.text)
        assert.are.equal("toggle", cc.type)
    end)

    it("sets the text's look and kinds", function()
        local client = NewClient()
        local text = client:LoadOptions().args.text
        text.set(info("text", "font"), "Expressway")
        text.set(info("text", "size"), 0.8)
        text.set(info("text", "damage"), false)
        local db = client:db().text
        assert.are.equal("Expressway", db.font)
        assert.are.equal(0.8, db.size)
        assert.is_false(db.damage)
        assert.are.equal("Expressway", text.get(info("text", "font")))
        assert.are.equal("LSM30_Font", text.args.font.dialogControl)
    end)

    it("sets the colours, and puts them back", function()
        local client = NewClient()
        local colors = client:LoadOptions().args.text.args.colors
        colors.set(info("text", "colors", "heal"), 0.1, 0.2, 0.3)
        assert.are.same({ 0.1, 0.2, 0.3 }, { colors.get(info("text", "colors", "heal")) })
        colors.args.reset.func()
        assert.are.same({ 0, 1, 0 }, { colors.get(info("text", "colors", "heal")) })
    end)

    it("sets the icon's countdown numbers and the player's interrupts", function()
        local client = NewClient()
        local cc = client:LoadOptions().args.cc
        cc.set(info("cc", "numbers"), false)
        assert.is_false(client:db().cc.numbers)
        assert.is_true(client:Holder("player").container.slots.cc.button.durationCooldown.hideNumbers)
        assert.is_false(cc.get(info("cc", "numbers")))
        cc.set(info("cc", "interrupts"), false)
        assert.is_false(client:db().cc.interrupts)
        cc.set(info("cc", "defensives"), false)
        assert.is_false(client:Holder("player").container.slots.big.enabled)
    end)

    it("sets the strata and level, applied at once", function()
        local client = NewClient()
        local layer = client:LoadOptions().args.units.args.layer
        assert.are.equal("", layer.get(info("units", "layer", "strata")))
        layer.set(info("units", "layer", "strata"), "DIALOG")
        layer.set(info("units", "layer", "level"), 12)
        assert.are.equal("DIALOG", client:Holder("pet"):GetFrameStrata())
        assert.are.equal(12, layer.get(info("units", "layer", "level")))
        assert.is_string(layer.args.strata.values[""])
        assert.is_string(layer.args.strata.values.TOOLTIP)
    end)

    it("turns test mode on and off", function()
        local client = NewClient()
        local test = client:LoadOptions().args.test
        test.set(nil, true)
        assert.is_true(test.get())
        assert.is_true(client.ns.testing)
        test.set(nil, false)
        assert.is_false(client.ns.testing)
    end)
end)
