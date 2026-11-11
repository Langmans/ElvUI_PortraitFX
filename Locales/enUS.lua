-- English strings, also the fallback for every other client language. Each says where it appears.
local addon = ...
local L = LibStub("AceLocale-3.0"):NewLocale(addon, "enUS", true)

-- stylua: ignore start

-- ElvUI's options: the plugin's page in the side bar and its text.
L.OPTIONS = "Portrait FX"
L.OPTIONS_DESC = "Combat text and a crowd control icon on the portraits of ElvUI's unit frames. With the portrait as an overlay, or without one, both go on the health bar instead."
L.TEST = "Test mode"
L.TEST_DESC = "Sample combat text and a sample icon on every frame, to see how they look. Stops when combat starts."

-- The Frames tab: per frame, the text and the icon.
L.UNITS = "Frames"
L.player = "Player"
L.target = "Target"
L.focus = "Focus"
L.pet = "Pet"
L.party = "Party"
L.SHOW = "Show"
L.SHOW_TEXT = "Combat text"
L.SHOW_CC = "Crowd control icon"
L.TEXT_PLACE = "Combat text position"
L.CC_PLACE = "Icon position"

-- The Frames tab's box for the strata and level of the text and the icon.
L.LAYER = "Layer"
L.STRATA = "Strata"
L.STRATA_OWN = "The frame's own"
L.LEVEL = "Level"
L.LEVEL_DESC = "Frame levels above the unit frame's texts. ElvUI puts its auras 10 above them."

-- The Frames tab's box for the debug addons (OAP Debug, _DebugLog), the setting every OAP addon
-- has: how much the plugin sends to them.
L.DEBUG = "OAP Debug"
L.DEBUG_LEVEL = "Send to OAP Debug"
L.DEBUG_DESC = "How much goes to OAP Debug's and _DebugLog's window: what the plugin receives and shows. Detailed: every combat event on a frame."
L.DEBUG_MISSING = "Not installed: nothing is sent."
L.DEBUG_errors = "Errors only"
L.DEBUG_normal = "Normal"
L.DEBUG_metrics = "Normal and metrics"
L.DEBUG_detailed = "Detailed"

-- The Text tab: its look, the kinds of event, the colours.
L.TEXT = "Combat text"
L.FONT = "Font"
L.SIZE = "Size"
L.SIZE_DESC = "The text's height as a part of the portrait's height."
L.ANCHOR = "Anchor to"
L.ANCHOR_DESC = "What it sits on. Automatic: the portrait beside the bars, else the health bar (the icon at its portrait end). A part the frame lacks or hides falls back to automatic. The icon is as big as the smaller side of what it sits on."
L.ANCHOR_auto = "Automatic"
L.ANCHOR_portrait = "Portrait"
L.ANCHOR_health = "Health bar"
L.ANCHOR_power = "Power bar"
L.ANCHOR_frame = "Whole frame"
L.POINT = "Position"
L.POINT_DESC = "Where on what it is anchored to it sits. The icon on automatic picks its point itself."
L.POINT_TOPLEFT = "Top left"
L.POINT_TOP = "Top"
L.POINT_TOPRIGHT = "Top right"
L.POINT_LEFT = "Left"
L.POINT_CENTER = "Centre"
L.POINT_RIGHT = "Right"
L.POINT_BOTTOMLEFT = "Bottom left"
L.POINT_BOTTOM = "Bottom"
L.POINT_BOTTOMRIGHT = "Bottom right"
L.X = "X offset"
L.Y = "Y offset"
L.OUTLINE = "Outline"
L.OUTLINE_NONE = "None"
L.OUTLINE_OUTLINE = "Outline"
L.OUTLINE_THICK = "Thick outline"
L.CRIT = "Critical size"
L.CRIT_DESC = "How much bigger a critical or crushing hit is."
L.HOLD = "Time shown"
L.HOLD_DESC = "Seconds the text stays before it fades out."
L.KINDS = "Show"
L.damage = "Damage"
L.heals = "Heals"
L.misses = "Misses, dodges, blocks and the like"
L.energize = "Power gains"
L.SHORT = "Short numbers"
L.SHORT_DESC = "1.2K instead of 1,234, in ElvUI's number style."
L.BLOCK_ICON = "Shield on a partial block"
L.BLOCK_ICON_DESC = "Damage partly blocked shows a small shield after the number; off: the number alone."
L.SCHOOLS = "Colour by school"
L.SCHOOLS_DESC = "Spell damage in the colour of its school; off: all in the spell colour."
L.COLORS = "Colours"
L.physical = "Physical damage"
L.spell = "Spell damage"
L.heal = "Heals"
L.power = "Power gains"
L.miss = "Misses"
L.RESET = "Default colours"

-- The Crowd control tab.
L.CC = "Crowd control"
L.CC_DESC = "The game picks the aura and draws it, so the icon keeps working in combat while WoW: Forever hides aura details from addons. Crowd control goes over a defensive. The game's loss of control goes on top, which also knows interrupts, silences and roots."
L.NUMBERS = "Countdown numbers"
L.INTERRUPTS = "Interrupts"
L.DEFENSIVES = "Defensives"
L.DEFENSIVES_DESC = "Big defensives such as Divine Shield and Ice Block, and external ones such as Blessing of Protection, when no crowd control is on the unit."

-- stylua: ignore end
