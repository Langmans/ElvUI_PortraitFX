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
L.SHOW_TEXT = "Combat text"
L.SHOW_CC = "Crowd control icon"

-- The Text tab: its look, the kinds of event, the colours.
L.TEXT = "Combat text"
L.FONT = "Font"
L.SIZE = "Size"
L.SIZE_DESC = "The text's height as a part of the portrait's height."
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
L.CC_DESC = "The game picks the crowd control aura and draws it, so the icon keeps working in combat while WoW: Forever hides aura details from addons. On the player the game's loss of control data goes on top, which also knows interrupts, silences and roots."
L.NUMBERS = "Countdown numbers"
L.INTERRUPTS = "Interrupts on the player"

-- stylua: ignore end
