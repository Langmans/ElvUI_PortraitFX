-- Development dependencies only: the test tools, pinned. ElvUI_PortraitFX itself is not a rock.
-- `luarocks install --only-deps elvui_portraitfx-dev-1.rockspec` installs them, locally
-- (tests/setup-lua.ps1) and in CI alike.
rockspec_format = "3.0"
package = "elvui_portraitfx"
version = "dev-1"
source = { url = "git+https://github.com/Langmans/ElvUI_PortraitFX.git" }
description = { summary = "ElvUI_PortraitFX's test tooling", license = "MIT" }
dependencies = {
    "lua ~> 5.1",
    "busted == 2.2.0",
    "luacov == 0.17.0",
    "luacov-reporter-lcov == 0.2",
}
build = { type = "builtin", modules = {} }
