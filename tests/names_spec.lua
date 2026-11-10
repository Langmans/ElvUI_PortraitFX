-- Every name the game and ElvUI see comes from the folder's name: loaded as "Tester", the plugin is
-- the module Tester, keeps its settings under Tester in ElvUI's profile and has the options page
-- Tester. A rename is then the folder, the .toc and the texts.

describe("names", function()
    it("come from the folder", function()
        local client = NewClient({ name = "Tester" })
        assert.is_table(client.modules.Tester)
        assert.are.same({ { "Tester" } }, client:called("RegisterModule"))
        assert.are.same({ { "Tester" } }, client:called("RegisterPlugin"))
        assert.is_table(client.E.db.Tester)
        assert.is_table(client:LoadOptions())
        assert.is_table(client.E.Options.args.Tester)
        assert.are.equal("Tester", client.ns.NAME)
    end)
end)
