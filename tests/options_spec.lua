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

    it("switches the text and the icon per frame, each kind of frame on a page of its own", function()
        local client = NewClient()
        local units = client:LoadOptions().args.units
        local show = units.args.target.args.show
        assert.is_nil(units.args.target.inline)
        assert.is_true(show.get(info("units", "target", "show", "cc")))
        show.set(info("units", "target", "show", "cc"), false)
        assert.is_false(client:db().units.target.cc)
        assert.is_false(client:Holder("target").container:IsEnabled(), "applied at once")
        units.args.party.args.show.set(info("units", "party", "show", "text"), false)
        assert.is_false(client:db().units.party.text)
        assert.are.equal("toggle", show.args.cc.type)
    end)

    it("places the text per frame: anchor, point and offset, applied at once", function()
        local client = NewClient()
        local place = client:LoadOptions().args.units.args.target.args.textPlace
        assert.are.equal("CENTER", place.get(info("units", "target", "textPlace", "point")))
        place.set(info("units", "target", "textPlace", "point"), "BOTTOM")
        place.set(info("units", "target", "textPlace", "y"), 10)
        assert.are.same(
            { client.frames.target.Portrait.backdrop, "BOTTOM", 0, 10 },
            client:Holder("target").text.points.BOTTOM
        )
        assert.is_string(place.args.point.values.TOPLEFT)
        assert.are.equal("auto", place.get(info("units", "target", "textPlace", "anchor")))
        place.set(info("units", "target", "textPlace", "anchor"), "frame")
        assert.are.equal(client.frames.target, client:Holder("target").text.points.BOTTOM[1])
        assert.are.same({ "auto", "portrait", "health", "power", "frame" }, place.args.anchor.sorting)
        assert.is_nil(place.args.point.disabled, "the text always takes its point")
        assert.are.same(
            { CENTER = { client.frames.player.Portrait.backdrop, "CENTER", 0, 0 } },
            client:Holder("player").text.points,
            "the player's frame keeps its own"
        )
    end)

    it("places the icon per frame, its point only when not automatic", function()
        local client = NewClient()
        local place = client:LoadOptions().args.units.args.focus.args.ccPlace
        assert.is_true(place.args.point.disabled(), "automatic picks the point itself")
        place.set(info("units", "focus", "ccPlace", "anchor"), "power")
        place.set(info("units", "focus", "ccPlace", "point"), "LEFT")
        place.set(info("units", "focus", "ccPlace", "x"), 4)
        assert.is_false(place.args.point.disabled())
        assert.are.same({ client.frames.focus.Power, "LEFT", 4, 0 }, client:Holder("focus").cc.points.LEFT)
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
