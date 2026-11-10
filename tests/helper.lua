-- Loaded once by busted before the spec files (see .busted). Finds the repository's .toc, reads it
-- the way the client does and defines NewClient (tests/wow.lua). The folder's name is the addon's
-- name, as the game passes it in; nothing here spells it. busted runs from the repository root.

local lfs = require("lfs")
local sh = require("tests.sh")

local tocFile
for entry in lfs.dir(".") do
    if entry:match("%.toc$") then tocFile = entry end
end
ADDON_NAME = assert(tocFile, "no .toc in the repository root"):gsub("%.toc$", "")

local toc = sh.read(tocFile)

-- The load order: every file the .toc names.
TOC_FILES = {}
for line in toc:gmatch("[^\r\n]+") do
    line = line:match("^%s*(.-)%s*$")
    if line ~= "" and not line:match("^#") then TOC_FILES[#TOC_FILES + 1] = (line:gsub("\\", "/")) end
end

-- The "## Key: value" lines.
TOC_METADATA = {}
for key, value in toc:gmatch("## ([^:\r\n]+):%s*([^\r\n]-)%s*\r?\n") do
    TOC_METADATA[key] = value
end

dofile("tests/wow.lua")
