-- Where on a frame the text and the icon go (Spot.lua). With the portrait beside the bars, both sit
-- on the portrait's box. As an overlay the portrait fills the health bar, or only its filled part,
-- and so changes size with the health: the text then sits on the health bar's middle and the icon,
-- a square as high as the bar, on the portrait's side of it. Without a portrait the same.

describe("the spot", function()
    it("is the portrait's box when it is beside the bars", function()
        local client = NewClient()
        local frame = client.frames.player
        local region, point, size = client.ns.Spot(frame)
        assert.are.equal(frame.Portrait.backdrop, region)
        assert.are.equal("CENTER", point)
        assert.are.equal(45, size)
    end)

    it("is the health bar for an overlay, the icon on the portrait's side", function()
        local client = NewClient():Style("target", "overlay")
        local frame = client.frames.target
        local region, point, size = client.ns.Spot(frame)
        assert.are.equal(frame.Health, region)
        assert.are.equal("LEFT", point)
        assert.are.equal(40, size)
        frame.ORIENTATION = "RIGHT"
        assert.are.equal("RIGHT", select(2, client.ns.Spot(frame)))
        frame.ORIENTATION = "MIDDLE"
        assert.are.equal("CENTER", select(2, client.ns.Spot(frame)))
    end)

    it("is the health bar without a portrait", function()
        local client = NewClient():Style("focus", "none")
        local frame = client.frames.focus
        assert.are.equal(frame.Health, (client.ns.Spot(frame)))
    end)

    it("of the text can be another part of the frame, as set", function()
        local client = NewClient():Style("target", "overlay")
        local frame, place = client.frames.target, client:db().units.target.textPlace
        local spot = client.ns.Spot(frame)
        assert.are.equal(spot, client.ns.TextRegion(frame, place), "auto: the spot")
        place.anchor = "portrait"
        assert.are.equal(frame.Portrait, client.ns.TextRegion(frame, place), "the portrait itself, also as overlay")
        place.anchor = "health"
        assert.are.equal(frame.Health, client.ns.TextRegion(frame, place))
        place.anchor = "power"
        assert.are.equal(frame.Power, client.ns.TextRegion(frame, place))
        place.anchor = "frame"
        assert.are.equal(frame, client.ns.TextRegion(frame, place))
    end)

    it("of the text falls back to the spot for a part the frame lacks or hides", function()
        local client = NewClient():Style("focus", "none")
        local frame, place = client.frames.focus, client:db().units.focus.textPlace
        place.anchor = "portrait"
        assert.are.equal(frame.Health, client.ns.TextRegion(frame, place), "no portrait shown")
        frame.Power = nil
        place.anchor = "power"
        assert.are.equal(frame.Health, client.ns.TextRegion(frame, place), "no power bar")
    end)

    it("of the icon is the spot when automatic, else the part set, as big as its smaller side", function()
        local client = NewClient()
        local frame, place = client.frames.player, client:db().units.player.ccPlace
        assert.are.same({ client.ns.Spot(frame) }, { client.ns.IconSpot(frame, place) })
        place.anchor, place.point = "health", "RIGHT"
        local region, point, size = client.ns.IconSpot(frame, place)
        assert.are.equal(frame.Health, region)
        assert.are.equal("RIGHT", point)
        assert.are.equal(40, size)
        place.anchor = "power"
        frame.Power:Hide()
        assert.are.same({ client.ns.Spot(frame) }, { client.ns.IconSpot(frame, place) }, "a hidden part: automatic")
    end)

    it("takes the box's smaller side, and a fallback for a size the client hides", function()
        local client = NewClient()
        local backdrop = client.frames.player.Portrait.backdrop
        backdrop:SetSize(60, 30)
        assert.are.equal(30, select(3, client.ns.Spot(client.frames.player)))
        backdrop:SetSize(SECRET, 30)
        assert.are.equal(client.ns.FALLBACK_SIZE, select(3, client.ns.Spot(client.frames.player)))
        backdrop:SetSize(0, 0)
        assert.are.equal(client.ns.FALLBACK_SIZE, select(3, client.ns.Spot(client.frames.player)))
    end)
end)
